//
//  NextMedicineQueryIntent.swift
//  KindDose
//

import AppIntents
import SwiftData
import Foundation

struct NextMedicineQueryIntent: AppIntent {
    static var title: LocalizedStringResource = "What's My Next Medicine"
    static var description = IntentDescription("Tells you your next medicine and when it's due, in KindDose.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let schema = Schema([Medicine.self, DoseLog.self, UserSettings.self])
        let container = try AppGroup.makeModelContainer(schema: schema)
        let context = ModelContext(container)

        let medicines = try context.fetch(FetchDescriptor<Medicine>(predicate: #Predicate { $0.isActive }))
        let logs = try context.fetch(FetchDescriptor<DoseLog>())

        let summary = HomeDoseResolver.summary(medicines: medicines, logs: logs)
        guard let next = summary.dueNow ?? summary.upcoming else {
            return .result(dialog: "You have nothing scheduled in KindDose right now.")
        }

        let timeText = next.scheduledTime.formatted(date: .omitted, time: .shortened)
        if summary.dueNow != nil {
            return .result(dialog: "\(next.medicine.name) is due now, in KindDose.")
        } else {
            return .result(dialog: "Your next medicine in KindDose is \(next.medicine.name) at \(timeText).")
        }
    }
}
