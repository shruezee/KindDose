//
//  NotificationDelegate.swift
//  KindDose
//

import Foundation
import SwiftData
import UserNotifications
import WidgetKit

/// Handles the "✅ I took it" and "Remind me in 10 min" notification actions without
/// opening the app, by writing straight to a fresh SwiftData context.
@MainActor
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        let context = ModelContext(modelContainer)

        defer {
            let allMedicines = try? context.fetch(FetchDescriptor<Medicine>())
            let allLogs = try? context.fetch(FetchDescriptor<DoseLog>())
            ReminderScheduler.shared.sweepMissedDoses(medicines: allMedicines ?? [], logs: allLogs ?? [], modelContext: context)
            try? context.save()
        }

        guard let medicineIDString = userInfo["medicineID"] as? String,
              let medicineID = UUID(uuidString: medicineIDString),
              let scheduledTime = resolveScheduledTime(from: userInfo)
        else { return }

        let descriptor = FetchDescriptor<Medicine>(predicate: #Predicate { $0.id == medicineID })
        guard let medicine = try? context.fetch(descriptor).first else { return }

        switch response.actionIdentifier {
        case ReminderIdentifiers.takenActionIdentifier:
            context.insert(DoseLog(medicine: medicine, scheduledTime: scheduledTime, status: .taken, loggedAt: Date()))
            ReminderScheduler.shared.cancelEscalations(medicineID: medicineID, scheduledTime: scheduledTime)

        case ReminderIdentifiers.snoozeActionIdentifier:
            ReminderScheduler.shared.cancelEscalations(medicineID: medicineID, scheduledTime: scheduledTime)
            ReminderScheduler.shared.scheduleSnooze(medicine: medicine, scheduledTime: scheduledTime)

        default:
            break
        }

        WidgetCenter.shared.reloadAllTimelines()
    }

    private func resolveScheduledTime(from userInfo: [AnyHashable: Any]) -> Date? {
        if let interval = userInfo["scheduledTime"] as? TimeInterval {
            return Date(timeIntervalSinceReferenceDate: interval)
        }
        if let hour = userInfo["hour"] as? Int, let minute = userInfo["minute"] as? Int {
            return Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date())
        }
        return nil
    }
}
