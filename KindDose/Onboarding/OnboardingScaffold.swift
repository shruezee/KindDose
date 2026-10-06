//
//  OnboardingScaffold.swift
//  KindDose
//

import SwiftUI

/// Shared chrome for every onboarding question: calm background, a solid card
/// (text never sits directly on the gradient), progress dots, and an optional
/// Back button. `onBack` is nil on the first screen, where there's nowhere to go.
struct OnboardingScaffold<Content: View>: View {
    var step: OnboardingStep
    var onBack: (() -> Void)?
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            CalmBackground()

            ScrollView {
                VStack(spacing: 24) {
                    HStack {
                        if let onBack {
                            Button(action: onBack) {
                                Label("Back", systemImage: "chevron.left")
                                    .font(.body.weight(.semibold))
                                    .frame(minHeight: 60)
                                    .padding(.horizontal, 8)
                                    .contentShape(Rectangle())
                            }
                            .accessibilityLabel("Back")
                            .accessibilityHint("Goes back to the previous question.")
                        }
                        Spacer()
                    }

                    ProgressDotsView(current: step.rawValue, total: OnboardingStep.allCases.count)

                    content()
                }
                .padding(24)
                .calmCard()
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .calmScreenWidth()
            }
        }
    }
}
