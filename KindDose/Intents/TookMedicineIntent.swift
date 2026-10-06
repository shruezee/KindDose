//
//  TookMedicineIntent.swift
//  KindDose
//
//  NOTE: intentionally duplicated (in spirit) in the KindDoseWidgetExtension
//  target, so both Siri ("I took my medicine in KindDose") and the widget's
//  own "I took it" button log a dose the same way. The widget's copy is
//  self-contained since that target can't import this app's code.

import AppIntents
import SwiftData
import Foundation
import WidgetKit

struct TookMedicineIntent: AppIntent {
    static var title: LocalizedStringResource = "I Took My Medicine"
    static var description = IntentDescription("Logs your next due medicine as taken, in KindDose.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let schema = Schema([Medicine.self, DoseLog.self, UserSettings.self])
        let container = try AppGroup.makeModelContainer(schema: schema)
        let context = ModelContext(container)

        let medicines = try context.fetch(FetchDescriptor<Medicine>(predicate: #Predicate { $0.isActive }))
        let logs = try context.fetch(FetchDescriptor<DoseLog>())

        guard let due = HomeDoseResolver.summary(medicines: medicines, logs: logs).dueNow else {
            return .result(dialog: "You're all done for now in KindDose — nothing is due.")
        }

        let log = DoseLog(medicine: due.medicine, scheduledTime: due.scheduledTime, status: .taken, loggedAt: Date())
        context.insert(log)
        try context.save()

        ReminderScheduler.shared.cancelEscalations(medicineID: due.medicine.id, scheduledTime: due.scheduledTime)
        WidgetCenter.shared.reloadAllTimelines()

        return .result(dialog: "Well done. That's \(due.medicine.name) taken in KindDose.")
    }
}
