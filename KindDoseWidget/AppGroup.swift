//
//  AppGroup.swift
//  KindDoseWidget
//
//  NOTE: this file is intentionally duplicated (identical content) in the main
//  KindDose app target at KindDose/Shared/AppGroup.swift, since a widget
//  extension compiles into its own separate binary and can't import code from
//  the main app. Keep both copies in sync if this ever changes.

import Foundation
import SwiftData

/// The on-disk location KindDose, its widget, and its App Intents all open so
/// they share one SwiftData store instead of each getting their own sandboxed copy.
enum AppGroup {
    static let identifier = "group.com.shruthi.kinddose"

    static var storeURL: URL {
        let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
        let base = containerURL ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("KindDose.store")
    }

    static func makeModelContainer(schema: Schema) throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, url: storeURL)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
