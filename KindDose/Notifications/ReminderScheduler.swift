//
//  ReminderScheduler.swift
//  KindDose
//

import Foundation
import SwiftData
import SwiftUI
import UserNotifications
import CryptoKit
import AlarmKit

enum ReminderIdentifiers {
    static let categoryIdentifier = "medicineReminder"
    static let takenActionIdentifier = "TAKEN_ACTION"
    static let snoozeActionIdentifier = "SNOOZE_ACTION"

    static func initialID(medicineID: UUID, hour: Int, minute: Int) -> String {
        "initial-\(medicineID.uuidString)-\(hour)-\(minute)"
    }

    static func escalationID(medicineID: UUID, scheduledTime: Date, stage: Int) -> String {
        "escalation-\(stage)-\(medicineID.uuidString)-\(scheduledTime.timeIntervalSinceReferenceDate)"
    }

    static func snoozeID(medicineID: UUID, scheduledTime: Date) -> String {
        "snooze-\(medicineID.uuidString)-\(scheduledTime.timeIntervalSinceReferenceDate)"
    }
}

/// Builds, tracks, and tears down every local notification (and, where available, AlarmKit alarm)
/// behind KindDose's medicine reminders. One rebuild pass recomputes everything from the current
/// list of medicines and dose logs, so it's safe to call whenever medicines change or the app
/// returns to the foreground.
final class ReminderScheduler {
    static let shared = ReminderScheduler()

    private init() {}

    /// Stays comfortably under the system's 64-pending-notification ceiling, leaving headroom
    /// for ad-hoc "Remind me in 10 minutes" snoozes a person triggers by hand.
    private let maxPendingNotifications = 64
    private let pendingSafetyMargin = 8
    private let maxEscalationDaysAhead = 7
    private let escalationDelays: [TimeInterval] = [10 * 60, 30 * 60]
    private let trackedAlarmIDsKey = "KindDose.trackedAlarmIDs"

    // MARK: - Setup

    func registerCategories() {
        let taken = UNNotificationAction(
            identifier: ReminderIdentifiers.takenActionIdentifier,
            title: "✅ I took it",
            options: []
        )
        let snooze = UNNotificationAction(
            identifier: ReminderIdentifiers.snoozeActionIdentifier,
            title: "Remind me in 10 min",
            options: []
        )
        let category = UNNotificationCategory(
            identifier: ReminderIdentifiers.categoryIdentifier,
            actions: [taken, snooze],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    /// `.timeSensitive` isn't requested here: the Time Sensitive Notifications entitlement
    /// (added in Signing & Capabilities) is what actually grants it, not this options bitmask.
    func requestNotificationAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    // MARK: - Full rebuild

    /// Cancels every pending reminder and schedules fresh ones for today's and the next few
    /// days' occurrences of each active medicine time. Call this whenever medicines are added,
    /// edited, or deleted, and whenever the app returns to the foreground.
    @MainActor
    func rebuildAll(medicines: [Medicine], logs: [DoseLog], useAlarmSound: Bool, now: Date = Date()) async {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        cancelAllTrackedAlarms()

        let activeMedicines = medicines.filter(\.isActive)
        let timeSlots = activeMedicines.reduce(into: 0) { count, medicine in count += medicine.times.count }
        guard timeSlots > 0 else { return }

        let budget = max(0, maxPendingNotifications - pendingSafetyMargin - timeSlots)
        let perDayCost = timeSlots * escalationDelays.count
        let daysAhead = perDayCost > 0
            ? max(1, min(maxEscalationDaysAhead, budget / perDayCost))
            : maxEscalationDaysAhead

        let resolvedIDs = resolvedOccurrenceIDs(from: logs)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)

        for medicine in activeMedicines {
            for time in medicine.times {
                guard let hour = time.hour, let minute = time.minute else { continue }

                if useAlarmSound {
                    await scheduleAlarmIfAvailable(medicine: medicine, hour: hour, minute: minute)
                } else {
                    scheduleInitialNotification(medicine: medicine, hour: hour, minute: minute)
                }

                for dayOffset in 0..<daysAhead {
                    guard let day = calendar.date(byAdding: .day, value: dayOffset, to: today),
                          let scheduledTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)
                    else { continue }

                    let occurrenceID = DueDose(medicine: medicine, scheduledTime: scheduledTime).id
                    guard !resolvedIDs.contains(occurrenceID) else { continue }

                    scheduleEscalations(medicine: medicine, scheduledTime: scheduledTime)
                }
            }
        }
    }

    private func resolvedOccurrenceIDs(from logs: [DoseLog]) -> Set<String> {
        Set(logs.compactMap { log -> String? in
            guard let medicine = log.medicine,
                  log.status == .taken || log.status == .takenLate || log.status == .skipped
            else { return nil }
            return DueDose(medicine: medicine, scheduledTime: log.scheduledTime).id
        })
    }

    // MARK: - Initial notification (daily repeating)

    private func scheduleInitialNotification(medicine: Medicine, hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Time for your \(medicine.name)"
        content.body = bodyText(for: medicine)
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        content.categoryIdentifier = ReminderIdentifiers.categoryIdentifier
        content.userInfo = ["medicineID": medicine.id.uuidString, "hour": hour, "minute": minute]

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let identifier = ReminderIdentifiers.initialID(medicineID: medicine.id, hour: hour, minute: minute)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Escalations (+10 min, +30 min, one-off)

    private func scheduleEscalations(medicine: Medicine, scheduledTime: Date) {
        for (stage, delay) in escalationDelays.enumerated() {
            let fireDate = scheduledTime.addingTimeInterval(delay)
            let interval = fireDate.timeIntervalSinceNow
            guard interval > 0 else { continue }

            let content = UNMutableNotificationContent()
            content.title = "Time for your \(medicine.name)"
            content.body = bodyText(for: medicine)
            content.sound = .default
            content.interruptionLevel = .timeSensitive
            content.categoryIdentifier = ReminderIdentifiers.categoryIdentifier
            content.userInfo = [
                "medicineID": medicine.id.uuidString,
                "scheduledTime": scheduledTime.timeIntervalSinceReferenceDate,
            ]

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            let identifier = ReminderIdentifiers.escalationID(medicineID: medicine.id, scheduledTime: scheduledTime, stage: stage)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }

    /// Cancels the pending +10/+30 escalations for one occurrence — call this the moment a dose
    /// is logged, so an already-taken dose doesn't keep nagging.
    func cancelEscalations(medicineID: UUID, scheduledTime: Date) {
        let identifiers = (0..<escalationDelays.count).map {
            ReminderIdentifiers.escalationID(medicineID: medicineID, scheduledTime: scheduledTime, stage: $0)
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    // MARK: - One-off "remind me in 10 minutes"

    func scheduleSnooze(medicine: Medicine, scheduledTime: Date, delay: TimeInterval = 10 * 60) {
        let content = UNMutableNotificationContent()
        content.title = "Time for your \(medicine.name)"
        content.body = bodyText(for: medicine)
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        content.categoryIdentifier = ReminderIdentifiers.categoryIdentifier
        content.userInfo = [
            "medicineID": medicine.id.uuidString,
            "scheduledTime": scheduledTime.timeIntervalSinceReferenceDate,
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let identifier = ReminderIdentifiers.snoozeID(medicineID: medicine.id, scheduledTime: scheduledTime)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func bodyText(for medicine: Medicine) -> String {
        medicine.instructions.isEmpty ? medicine.dose : "\(medicine.dose) — \(medicine.instructions)"
    }

    // MARK: - Missed-dose sweep

    /// Marks any dose whose final (+30 min) escalation window has passed with no log as missed.
    /// There's no reliable way for iOS to run app code at an exact background time without a
    /// person interacting with a notification, so this runs opportunistically: on app foreground
    /// and whenever a notification is delivered or tapped.
    @MainActor
    func sweepMissedDoses(medicines: [Medicine], logs: [DoseLog], modelContext: ModelContext, now: Date = Date()) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let finalEscalationDelay = escalationDelays.last ?? 0
        let resolvedIDs = Set(logs.compactMap { log -> String? in
            guard let medicine = log.medicine else { return nil }
            return DueDose(medicine: medicine, scheduledTime: log.scheduledTime).id
        })

        for medicine in medicines where medicine.isActive {
            for time in medicine.times {
                guard let hour = time.hour, let minute = time.minute else { continue }
                for dayOffset in -1...0 {
                    guard let day = calendar.date(byAdding: .day, value: dayOffset, to: today),
                          let scheduledTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day),
                          scheduledTime.addingTimeInterval(finalEscalationDelay) < now,
                          // A dose time from before the medicine was added was never owed;
                          // without this, a medicine added today shows yesterday as missed.
                          scheduledTime >= medicine.createdAt
                    else { continue }

                    let occurrenceID = DueDose(medicine: medicine, scheduledTime: scheduledTime).id
                    guard !resolvedIDs.contains(occurrenceID) else { continue }

                    modelContext.insert(DoseLog(medicine: medicine, scheduledTime: scheduledTime, status: .missed, loggedAt: now))
                }
            }
        }
    }

    // MARK: - AlarmKit (iOS 26.1+)

    var isAlarmKitAvailable: Bool {
        if #available(iOS 26.1, *) {
            return true
        }
        return false
    }

    /// Safe to call on any OS version — returns false immediately where AlarmKit doesn't exist.
    func requestAlarmAuthorization() async -> Bool {
        if #available(iOS 26.1, *) {
            do {
                let state = try await AlarmManager.shared.requestAuthorization()
                return state == .authorized
            } catch {
                return false
            }
        }
        return false
    }

    private func scheduleAlarmIfAvailable(medicine: Medicine, hour: Int, minute: Int) async {
        if #available(iOS 26.1, *) {
            await scheduleAlarm(medicine: medicine, hour: hour, minute: minute)
        } else {
            scheduleInitialNotification(medicine: medicine, hour: hour, minute: minute)
        }
    }

    @available(iOS 26.1, *)
    private func scheduleAlarm(medicine: Medicine, hour: Int, minute: Int) async {
        let id = alarmID(medicineID: medicine.id, hour: hour, minute: minute)
        let alert = AlarmPresentation.Alert(title: "Time for your \(medicine.name)")
        let presentation = AlarmPresentation(alert: alert)
        let attributes = AlarmAttributes(presentation: presentation, metadata: ReminderAlarmMetadata(), tintColor: Color.blue)
        let time = Alarm.Schedule.Relative.Time(hour: hour, minute: minute)
        let everyWeekday: [Locale.Weekday] = [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
        let schedule = Alarm.Schedule.relative(.init(time: time, repeats: .weekly(everyWeekday)))
        let configuration = AlarmManager.AlarmConfiguration.alarm(schedule: schedule, attributes: attributes)

        do {
            _ = try await AlarmManager.shared.schedule(id: id, configuration: configuration)
            trackAlarmID(id)
        } catch {
            // Alarm scheduling failed (e.g. not authorized) — fall back to a plain notification
            // so the person still gets reminded.
            scheduleInitialNotification(medicine: medicine, hour: hour, minute: minute)
        }
    }

    private func alarmID(medicineID: UUID, hour: Int, minute: Int) -> UUID {
        deterministicUUID(from: "alarm-\(medicineID.uuidString)-\(hour)-\(minute)")
    }

    private func cancelAllTrackedAlarms() {
        guard #available(iOS 26.1, *) else { return }
        let ids = UserDefaults.standard.stringArray(forKey: trackedAlarmIDsKey) ?? []
        for idString in ids {
            guard let id = UUID(uuidString: idString) else { continue }
            try? AlarmManager.shared.cancel(id: id)
        }
        UserDefaults.standard.removeObject(forKey: trackedAlarmIDsKey)
    }

    private func trackAlarmID(_ id: UUID) {
        var ids = UserDefaults.standard.stringArray(forKey: trackedAlarmIDsKey) ?? []
        ids.append(id.uuidString)
        UserDefaults.standard.set(ids, forKey: trackedAlarmIDsKey)
    }
}

@available(iOS 26.1, *)
private struct ReminderAlarmMetadata: AlarmMetadata {}

private func deterministicUUID(from string: String) -> UUID {
    let digest = Array(SHA256.hash(data: Data(string.utf8)))
    let bytes = Array(digest.prefix(16))
    return bytes.withUnsafeBufferPointer { buffer in
        NSUUID(uuidBytes: buffer.baseAddress!) as UUID
    }
}
