//
//  HistoryResolver.swift
//  KindDose
//

import Foundation

struct HistoryOccurrence: Identifiable {
    let id: String
    let medicineName: String
    let status: DoseStatus
}

struct HistoryDay: Identifiable {
    let id: Date
    let date: Date
    let label: String
    let occurrences: [HistoryOccurrence]
}

enum HistoryResolver {
    /// Every elapsed dose occurrence from the start of this calendar week through today.
    static func thisWeek(medicines: [Medicine], logs: [DoseLog], now: Date = Date()) -> [HistoryDay] {
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else { return [] }
        let today = calendar.startOfDay(for: now)

        var days: [HistoryDay] = []
        var day = calendar.startOfDay(for: weekInterval.start)

        while day <= today {
            let occurrences = occurrencesForDay(day, medicines: medicines, logs: logs, now: now)
            if !occurrences.isEmpty {
                days.append(HistoryDay(id: day, date: day, label: weekdayLabel(for: day), occurrences: occurrences))
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return days
    }

    /// Consecutive days (ending today) where every elapsed dose was taken. Today only
    /// breaks the streak once its own doses have actually come due and gone unlogged —
    /// a day with nothing due yet is skipped, not counted as a break.
    static func currentStreak(medicines: [Medicine], logs: [DoseLog], now: Date = Date()) -> Int {
        let calendar = Calendar.current
        var streak = 0
        var day = calendar.startOfDay(for: now)
        var isFirstDay = true

        while true {
            let occurrences = occurrencesForDay(day, medicines: medicines, logs: logs, now: now)
            if occurrences.isEmpty {
                if isFirstDay, let previous = calendar.date(byAdding: .day, value: -1, to: day) {
                    day = previous
                    isFirstDay = false
                    continue
                }
                break
            }
            let allTaken = occurrences.allSatisfy { $0.status == .taken || $0.status == .takenLate }
            guard allTaken else { break }
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
            isFirstDay = false
        }
        return streak
    }

    private static func occurrencesForDay(_ day: Date, medicines: [Medicine], logs: [DoseLog], now: Date) -> [HistoryOccurrence] {
        let calendar = Calendar.current
        var results: [HistoryOccurrence] = []

        for medicine in medicines where medicine.isActive {
            let sortedTimes = medicine.times.sorted { ($0.hour ?? 0, $0.minute ?? 0) < ($1.hour ?? 0, $1.minute ?? 0) }
            for time in sortedTimes {
                guard let hour = time.hour, let minute = time.minute,
                      let scheduledTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day),
                      scheduledTime <= now
                else { continue }

                let status = logs.first {
                    $0.medicine?.id == medicine.id && calendar.isDate($0.scheduledTime, equalTo: scheduledTime, toGranularity: .minute)
                }?.status ?? .missed

                results.append(HistoryOccurrence(
                    id: "\(medicine.id.uuidString)-\(scheduledTime.timeIntervalSinceReferenceDate)",
                    medicineName: medicine.name,
                    status: status
                ))
            }
        }
        return results
    }

    private static func weekdayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}
