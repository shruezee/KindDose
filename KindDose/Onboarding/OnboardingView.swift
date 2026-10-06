//
//  OnboardingView.swift
//  KindDose
//

import SwiftUI
import SwiftData

/// Drives the one-question-per-screen onboarding flow and saves the result to
/// the singleton UserSettings row. RootView switches to HomeView reactively
/// once hasCompletedOnboarding flips, so this view doesn't need a completion callback.
struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize) private var systemDynamicTypeSize

    @State private var step: OnboardingStep = .welcome
    @State private var userName = ""
    @State private var textSizePreference: TextSizePreference = .standard
    @State private var isCarerMode = false
    @State private var preferredAddMethod: AddMedicineMethod = .type

    var body: some View {
        Group {
            switch step {
            case .welcome:
                WelcomeStepView(onNext: goNext)
            case .name:
                NameStepView(name: $userName, onNext: goNext, onBack: goBack)
            case .textSize:
                TextSizeStepView(selection: $textSizePreference, onNext: goNext, onBack: goBack)
            case .whoFor:
                WhoForStepView(isCarerMode: $isCarerMode, onNext: goNext, onBack: goBack)
            case .addMethod:
                AddMethodStepView(selection: $preferredAddMethod, isCarerMode: isCarerMode, onNext: goNext, onBack: goBack)
            case .notifications:
                NotificationsStepView(onBack: goBack, onFinish: finish)
            }
        }
        .onAppear(perform: prefillTextSizeFromSystem)
    }

    private func goNext() {
        if let next = OnboardingStep(rawValue: step.rawValue + 1) {
            step = next
        }
    }

    private func goBack() {
        if let previous = OnboardingStep(rawValue: step.rawValue - 1) {
            step = previous
        }
    }

    /// If the system's Dynamic Type is already large, preselect a matching option
    /// instead of defaulting to Standard.
    private func prefillTextSizeFromSystem() {
        switch systemDynamicTypeSize {
        case .xSmall, .small, .medium, .large:
            textSizePreference = .standard
        case .xLarge, .xxLarge, .xxxLarge:
            textSizePreference = .big
        case .accessibility1, .accessibility2:
            textSizePreference = .bigger
        case .accessibility3, .accessibility4, .accessibility5:
            textSizePreference = .biggest
        @unknown default:
            textSizePreference = .standard
        }
    }

    private func finish() {
        let descriptor = FetchDescriptor<UserSettings>()
        if let existing = try? modelContext.fetch(descriptor).first {
            existing.userName = userName
            existing.textSizePreference = textSizePreference
            existing.isCarerMode = isCarerMode
            existing.preferredAddMethod = preferredAddMethod
            existing.hasCompletedOnboarding = true
        } else {
            let settings = UserSettings(
                userName: userName,
                textSizePreference: textSizePreference,
                isCarerMode: isCarerMode,
                preferredAddMethod: preferredAddMethod,
                hasCompletedOnboarding: true
            )
            modelContext.insert(settings)
        }
    }
}

#if DEBUG
#Preview {
    OnboardingView()
        .modelContainer(for: UserSettings.self, inMemory: true)
}
#endif
