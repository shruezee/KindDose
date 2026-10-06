//
//  HomeDoseResolver.swift
//  KindDose
//

import Foundation

/// A single scheduled dose occurrence: one medicine, at one of its daily times, on one day.
struct DueDose: Identifiable, Hashable {
    var medicine: Medicine
    var scheduledTime: Date

    var id: String { "\(medicine.id.uuidString)-\(scheduledTime.timeIntervalSinceReferenceDate)" }
}

struct HomeDoseSummary {
    var dueNow: DueDose?
    var upcoming: DueDose?
}

enum HomeDoseResolver {
    /// Builds today's and tomorrow's dose occurrences from each active medicine's
    /// daily times, drops any already logged as taken/taken late/skipped, then
    /// picks the earliest overdue-or-due occurrence and the one after it.
    static func summary(medicines: [Medicine], logs: [DoseLog], now: Date = Date()) -> HomeDoseSummary {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)

        var occurrences: [DueDose] = []
        for medicine in medicines where medicine.isActive {
            for time in medicine.times {
                guard let hour = time.hour, let minute = time.minute else { continue }
                for dayOffset in 0...1 {
                    guard let day = calendar.date(byAdding: .day, value: dayOffset, to: today),
                          let scheduledTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)
                    else { continue }
                    occurrences.append(DueDose(medicine: medicine, scheduledTime: scheduledTime))
                }
            }
        }

        let resolvedIDs = Set(logs.compactMap { log -> String? in
            guard let medicine = log.medicine,
                  log.status == .taken || log.status == .takenLate || log.status == .skipped
            else { return nil }
            return DueDose(medicine: medicine, scheduledTime: log.scheduledTime).id
        })

        let pending = occurrences
            .filter { !resolvedIDs.contains($0.id) }
            .sorted { $0.scheduledTime < $1.scheduledTime }

        let due = pending.first { $0.scheduledTime <= now }
        let upcoming = pending.first { $0.scheduledTime > (due?.scheduledTime ?? .distantPast) }

        return HomeDoseSummary(dueNow: due, upcoming: upcoming)
    }
}
