//
//  NameStepView.swift
//  KindDose
//

import SwiftUI

struct NameStepView: View {
    @Binding var name: String
    var onNext: () -> Void
    var onBack: () -> Void

    @FocusState private var isFieldFocused: Bool

    var body: some View {
        OnboardingScaffold(step: .name, onBack: onBack) {
            VStack(spacing: 20) {
                Text("What should I call you?")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                TextField("Your name", text: $name)
                    .font(.title3)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .frame(minHeight: 60)
                    .focused($isFieldFocused)
                    .accessibilityLabel("Your name")
                    .accessibilityHint("Optional. This is how KindDose will greet you.")

                Button("Continue", action: onNext)
                    .buttonStyle(.bigButton)

                Button {
                    name = ""
                    onNext()
                } label: {
                    Text("Skip")
                        .font(.body.weight(.semibold))
                        .frame(minHeight: 60)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                }
                .accessibilityHint("Skips this question. You can add your name later.")
            }
        }
    }
}

#if DEBUG
#Preview {
    NameStepView(name: .constant(""), onNext: {}, onBack: {})
}
#endif
