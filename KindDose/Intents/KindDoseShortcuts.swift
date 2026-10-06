//
//  KindDoseShortcuts.swift
//  KindDose
//

import AppIntents

/// Registers KindDose's App Shortcuts with Siri. Every phrase must name the
/// app, per Apple's App Shortcuts rules — handled here by \(.applicationName).
struct KindDoseShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: TookMedicineIntent(),
            phrases: [
                "I took my medicine in \(.applicationName)",
                "Log my medicine in \(.applicationName)",
            ],
            shortTitle: "I Took My Medicine",
            systemImageName: "checkmark.circle.fill"
        )
        AppShortcut(
            intent: NextMedicineQueryIntent(),
            phrases: [
                "What's my next medicine in \(.applicationName)",
                "When's my next dose in \(.applicationName)",
            ],
            shortTitle: "Next Medicine",
            systemImageName: "clock.fill"
        )
    }
}
