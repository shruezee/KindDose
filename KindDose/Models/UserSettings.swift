//
//  UserSettings.swift
//  KindDose
//

import Foundation
import SwiftData

enum TextSizePreference: String, Codable, CaseIterable, Identifiable {
    case standard, big, bigger, biggest

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .standard: "Standard"
        case .big: "Big"
        case .bigger: "Bigger"
        case .biggest: "Biggest"
        }
    }
}

enum AddMedicineMethod: String, Codable, CaseIterable, Identifiable {
    case scan, speak, type, healthImport

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .scan: "Scan the packet"
        case .speak: "Speak the details"
        case .type: "Type it in"
        case .healthImport: "Import from Health"
        }
    }

    var hint: String {
        switch self {
        case .scan: "Takes a photo of the medicine packet or label."
        case .speak: "Say the medicine name and dose out loud."
        case .type: "Type the name and dose yourself."
        case .healthImport: "Brings in medicines already tracked in the Health app."
        }
    }
}

/// A single settings row acts as the app's singleton; use `current(in:)` to fetch or create it.
@Model
final class UserSettings {
    var userName: String
    var textSizePreference: TextSizePreference
    var isCarerMode: Bool
    var preferredAddMethod: AddMedicineMethod
    var showJokes: Bool
    var showBreathing: Bool
    var hasCompletedOnboarding: Bool
    /// iOS 26.1+ only: use AlarmKit so the reminder rings even in Silent mode. Ignored on older iOS.
    /// Needs this inline default (not just an init default) so SwiftData's lightweight migration
    /// can backfill it on stores created before this property existed.
    var useAlarmSound: Bool = false

    init(
        userName: String = "",
        textSizePreference: TextSizePreference = .standard,
        isCarerMode: Bool = false,
        preferredAddMethod: AddMedicineMethod = .type,
        showJokes: Bool = true,
        showBreathing: Bool = true,
        hasCompletedOnboarding: Bool = false,
        useAlarmSound: Bool = false
    ) {
        self.userName = userName
        self.textSizePreference = textSizePreference
        self.isCarerMode = isCarerMode
        self.preferredAddMethod = preferredAddMethod
        self.showJokes = showJokes
        self.showBreathing = showBreathing
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.useAlarmSound = useAlarmSound
    }
}
