//
//  TookMedicineIntent.swift
//  KindDoseWidget
//
//  NOTE: intentionally duplicated (identical in spirit) in the main KindDose
//  app target, so both Siri ("I took my medicine in KindDose") and the
//  widget's own "I took it" button log a dose the same way. This copy has to
//  be self-contained since the widget extension can't import the app's code.

import AppIntents
import SwiftData
import Foundation
import UserNotifications
import WidgetKit

struct TookMedicineIntent: AppIntent {
    static var title: LocalizedStringResource = "I Took My Medicine"
    static var description = IntentDescription("Logs your next due medicine as taken, in KindDose.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let schema = Schema([Medicine.self, DoseLog.self])
        let container = try AppGroup.makeModelContainer(schema: schema)
        let context = ModelContext(container)

        let medicines = try context.fetch(FetchDescriptor<Medicine>(predicate: #Predicate { $0.isActive }))
        let logs = try context.fetch(FetchDescriptor<DoseLog>())

        guard let due = WidgetDoseResolver.nextDue(medicines: medicines, logs: logs),
              due.scheduledTime <= Date()
        else {
            return .result(dialog: "You're all done for now in KindDose — nothing is due.")
        }

        let log = DoseLog(medicine: due.medicine, scheduledTime: due.scheduledTime, status: .taken, loggedAt: Date())
        context.insert(log)
        try context.save()

        cancelEscalations(medicineID: due.medicine.id, scheduledTime: due.scheduledTime)
        WidgetCenter.shared.reloadAllTimelines()

        return .result(dialog: "Well done. That's \(due.medicine.name) taken in KindDose.")
    }

    /// Mirrors ReminderScheduler.cancelEscalations' identifier scheme (app target only,
    /// not importable here) so the +10/+30 reminders for this dose don't keep nagging.
    private func cancelEscalations(medicineID: UUID, scheduledTime: Date) {
        let identifiers = (0..<2).map { stage in
            "escalation-\(stage)-\(medicineID.uuidString)-\(scheduledTime.timeIntervalSinceReferenceDate)"
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
