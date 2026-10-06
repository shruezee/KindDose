//
//  KindDoseTests.swift
//  KindDoseTests
//
//  Created by shruthi palchandar on 1/10/2026.
//

import Foundation
import SwiftData
import Testing
@testable import KindDose

@MainActor
struct KindDoseTests {

    private func makeContext() throws -> ModelContext {
        let schema = Schema([Medicine.self, DoseLog.self, UserSettings.self])
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return ModelContext(container)
    }

    private func date(_ day: Int, _ hour: Int, _ minute: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    private func missedLogs(_ context: ModelContext) throws -> [DoseLog] {
        try context.fetch(FetchDescriptor<DoseLog>()).filter { $0.status == .missed }
    }

    @Test func medicineAddedTodayIsNotMissedYesterday() throws {
        let context = try makeContext()
        let now = date(3, 14, 7)
        let medicine = Medicine(name: "Vitamin D", dose: "1000 IU", form: .tablet,
                                times: [DateComponents(hour: 13, minute: 57)], createdAt: date(3, 13, 56))
        context.insert(medicine)

        ReminderScheduler.shared.sweepMissedDoses(medicines: [medicine], logs: [], modelContext: context, now: now)

        #expect(try missedLogs(context).isEmpty)
    }

    @Test func olderMedicineStillGetsMissedDose() throws {
        let context = try makeContext()
        let now = date(3, 14, 7)
        let medicine = Medicine(name: "Vitamin D", dose: "1000 IU", form: .tablet,
                                times: [DateComponents(hour: 13, minute: 57)], createdAt: date(1, 9, 0))
        context.insert(medicine)

        ReminderScheduler.shared.sweepMissedDoses(medicines: [medicine], logs: [], modelContext: context, now: now)

        let missed = try missedLogs(context)
        #expect(missed.count == 1)
        #expect(missed.first?.scheduledTime == date(2, 13, 57))
    }

    @Test func nextTimeSaysTomorrowWhenNotToday() {
        let now = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        #expect(HomeView.nextTimeText(tomorrow, now: now).hasPrefix("Tomorrow, "))
        #expect(!HomeView.nextTimeText(now, now: now).contains("Tomorrow"))
    }
}
