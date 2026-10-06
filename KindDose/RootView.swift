//
//  RootView.swift
//  KindDose
//

import SwiftUI
import SwiftData

/// Shows onboarding until the singleton UserSettings row says it's done, then the home screen.
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [UserSettings]
    @State private var isSettingUp = true

    var body: some View {
        Group {
            if isSettingUp {
                SplashView()
            } else if let settings = settingsList.first, settings.hasCompletedOnboarding {
                HomeView()
            } else {
                OnboardingView()
            }
        }
        .dynamicTypeSize((settingsList.first?.textSizePreference.minimumDynamicTypeSize ?? .xSmall)...)
        .task {
            if settingsList.isEmpty {
                modelContext.insert(UserSettings())
            }
            try? await Task.sleep(for: .seconds(1))
            isSettingUp = false
        }
    }
}

#if DEBUG
#Preview {
    RootView()
        .modelContainer(for: UserSettings.self, inMemory: true)
}
#endif
