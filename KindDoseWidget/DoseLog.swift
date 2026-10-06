//
//  DoseLog.swift
//  KindDoseWidget
//
//  NOTE: intentionally duplicated (identical content) from the main KindDose
//  app target at KindDose/Models/DoseLog.swift. Keep both copies in sync.

import Foundation
import SwiftData

enum DoseStatus: String, Codable, CaseIterable, Identifiable {
    case taken, takenLate, skipped, missed, pending

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .taken: "Taken"
        case .takenLate: "Taken late"
        case .skipped: "Skipped"
        case .missed: "Not logged"
        case .pending: "Upcoming"
        }
    }
}

@Model
final class DoseLog: Identifiable {
    var id: UUID
    var medicine: Medicine?
    var scheduledTime: Date
    var status: DoseStatus
    var loggedAt: Date?

    init(
        id: UUID = UUID(),
        medicine: Medicine? = nil,
        scheduledTime: Date,
        status: DoseStatus = .pending,
        loggedAt: Date? = nil
    ) {
        self.id = id
        self.medicine = medicine
        self.scheduledTime = scheduledTime
        self.status = status
        self.loggedAt = loggedAt
    }
}
