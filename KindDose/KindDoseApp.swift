//
//  KindDoseApp.swift
//  KindDose
//
//  Created by shruthi palchandar on 1/10/2026.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct KindDoseApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Medicine.self,
            DoseLog.self,
            UserSettings.self,
        ])

        do {
            return try AppGroup.makeModelContainer(schema: schema)
        } catch {
            // A schema change that lightweight migration can't resolve would otherwise crash
            // this app on every launch, permanently. For an elder-first medication reminder,
            // a fresh (empty) store beats a store the person can never open again.
            let storeURL = AppGroup.storeURL
            for suffix in ["", "-wal", "-shm"] {
                try? FileManager.default.removeItem(at: URL(fileURLWithPath: storeURL.path + suffix))
            }
            do {
                return try AppGroup.makeModelContainer(schema: schema)
            } catch {
                fatalError("Could not create ModelContainer even after resetting the store: \(error)")
            }
        }
    }()

    private let notificationDelegate: NotificationDelegate

    init() {
        let container = sharedModelContainer
        let delegate = NotificationDelegate(modelContainer: container)
        notificationDelegate = delegate
        UNUserNotificationCenter.current().delegate = delegate
        ReminderScheduler.shared.registerCategories()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
