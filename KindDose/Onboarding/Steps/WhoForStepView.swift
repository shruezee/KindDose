//
//  WhoForStepView.swift
//  KindDose
//

import SwiftUI

struct WhoForStepView: View {
    @Binding var isCarerMode: Bool
    var onNext: () -> Void
    var onBack: () -> Void

    var body: some View {
        OnboardingScaffold(step: .whoFor, onBack: onBack) {
            VStack(spacing: 20) {
                Text("Who is this for?")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                VStack(spacing: 14) {
                    Button {
                        isCarerMode = false
                        onNext()
                    } label: {
                        Text("Me")
                    }
                    .buttonStyle(.bigButton)

                    Button {
                        isCarerMode = true
                        onNext()
                    } label: {
                        Text("Someone I care for")
                    }
                    .buttonStyle(.bigButton)
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    WhoForStepView(isCarerMode: .constant(false), onNext: {}, onBack: {})
}
#endif
