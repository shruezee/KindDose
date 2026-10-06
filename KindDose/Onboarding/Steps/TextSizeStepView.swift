//
//  TextSizeStepView.swift
//  KindDose
//

import SwiftUI

struct TextSizeStepView: View {
    @Binding var selection: TextSizePreference
    var onNext: () -> Void
    var onBack: () -> Void

    @ScaledMetric(relativeTo: .body) private var baseSampleSize: CGFloat = 20

    var body: some View {
        OnboardingScaffold(step: .textSize, onBack: onBack) {
            VStack(spacing: 24) {
                Text("How big should text be?")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text("This is how your reminders will look.")
                    .font(.system(size: baseSampleSize * selection.sampleScale, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("Sample at \(selection.displayName) size: This is how your reminders will look.")

                VStack(spacing: 14) {
                    ForEach(TextSizePreference.allCases) { option in
                        Button {
                            selection = option
                        } label: {
                            HStack {
                                Text(option.displayName)
                                Spacer()
                                if option == selection {
                                    Image(systemName: "checkmark.circle.fill")
                                        .accessibilityHidden(true)
                                }
                            }
                        }
                        .buttonStyle(.bigButton)
                        .accessibilityLabel(option == selection ? "\(option.displayName), selected" : option.displayName)
                        .accessibilityAddTraits(option == selection ? [.isSelected] : [])
                    }
                }

                Button("Continue", action: onNext)
                    .buttonStyle(.bigButton)
            }
        }
    }
}

private extension TextSizePreference {
    /// Relative scale used only for the live onboarding sample, layered on top of the system's own Dynamic Type size.
    var sampleScale: CGFloat {
        switch self {
        case .standard: 1.0
        case .big: 1.3
        case .bigger: 1.6
        case .biggest: 2.0
        }
    }
}

#if DEBUG
#Preview {
    TextSizeStepView(selection: .constant(.standard), onNext: {}, onBack: {})
}
#endif
