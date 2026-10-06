//
//  WelcomeStepView.swift
//  KindDose
//

import SwiftUI

struct WelcomeStepView: View {
    var onNext: () -> Void

    var body: some View {
        OnboardingScaffold(step: .welcome, onBack: nil) {
            VStack(spacing: 24) {
                Text("Hi! I'm KindDose.")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text("Let's set up your medicine reminders. It takes 1 minute.")
                    .font(.title3)
                    .multilineTextAlignment(.center)

                Button("Let's go", action: onNext)
                    .buttonStyle(.bigButton)
            }
        }
    }
}

#if DEBUG
#Preview {
    WelcomeStepView(onNext: {})
}
#endif
