//
//  WidgetDoseResolver.swift
//  KindDoseWidget
//

import Foundation

/// A minimal, widget-local version of the app's HomeDoseResolver — same logic,
/// duplicated because this target can't import the app's code. Picks the
/// earliest overdue-or-due occurrence, falling back to the next upcoming one.
enum WidgetDoseResolver {
    static func nextDue(medicines: [Medicine], logs: [DoseLog], now: Date = Date()) -> (medicine: Medicine, scheduledTime: Date)? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)

        var occurrences: [(medicine: Medicine, scheduledTime: Date)] = []
        for medicine in medicines where medicine.isActive {
            for time in medicine.times {
                guard let hour = time.hour, let minute = time.minute else { continue }
                for dayOffset in 0...1 {
                    guard let day = calendar.date(byAdding: .day, value: dayOffset, to: today),
                          let scheduledTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)
                    else { continue }
                    occurrences.append((medicine: medicine, scheduledTime: scheduledTime))
                }
            }
        }

        func occurrenceID(_ medicine: Medicine, _ time: Date) -> String {
            "\(medicine.id.uuidString)-\(time.timeIntervalSinceReferenceDate)"
        }

        let resolvedIDs = Set(logs.compactMap { log -> String? in
            guard let medicine = log.medicine,
                  log.status == .taken || log.status == .takenLate || log.status == .skipped
            else { return nil }
            return occurrenceID(medicine, log.scheduledTime)
        })

        let pending = occurrences
            .filter { !resolvedIDs.contains(occurrenceID($0.medicine, $0.scheduledTime)) }
            .sorted { $0.scheduledTime < $1.scheduledTime }

        return pending.first { $0.scheduledTime <= now } ?? pending.first
    }
}
