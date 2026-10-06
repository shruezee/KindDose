//
//  Medicine.swift
//  KindDose
//

import Foundation
import SwiftData

enum MedicineForm: String, Codable, CaseIterable, Identifiable {
    case tablet, capsule, liquid, drops, inhaler, injection, other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tablet: "Tablet"
        case .capsule: "Capsule"
        case .liquid: "Liquid"
        case .drops: "Drops"
        case .inhaler: "Inhaler"
        case .injection: "Injection"
        case .other: "Other"
        }
    }
}

@Model
final class Medicine {
    var id: UUID
    var name: String
    var dose: String
    var form: MedicineForm
    var instructions: String
    @Attribute(.externalStorage) var photo: Data?
    var times: [DateComponents]
    var isActive: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \DoseLog.medicine)
    var doseLogs: [DoseLog]? = []

    init(
        id: UUID = UUID(),
        name: String,
        dose: String,
        form: MedicineForm,
        instructions: String = "",
        photo: Data? = nil,
        times: [DateComponents] = [],
        isActive: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.dose = dose
        self.form = form
        self.instructions = instructions
        self.photo = photo
        self.times = times
        self.isActive = isActive
        self.createdAt = createdAt
    }
}
