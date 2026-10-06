//
//  TakenView.swift
//  KindDose
//

import SwiftUI

/// The "taken" moment: a checkmark, a personal validation message, and a clean joke.
/// Auto-closes after 12 seconds unless VoiceOver is running, in which case the
/// person must dismiss it themselves (so VoiceOver has time to read everything).
struct TakenView: View {
    var userName: String
    var dose: DueDose
    var onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled

    @State private var checkmarkScale: CGFloat = 0.4
    @State private var didAppear = false
    @State private var validationText = ""
    @State private var joke: Joke?

    var body: some View {
        ZStack {
            CalmBackground()

            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 84))
                        .foregroundStyle(CalmColor.actionBackground)
                        .scaleEffect(checkmarkScale)
                        .accessibilityHidden(true)

                    Text(validationText)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)

                    if let joke {
                        VStack(spacing: 8) {
                            Text(joke.setup)
                                .font(.body)
                            Text(joke.punchline)
                                .font(.body.bold())
                        }
                        .multilineTextAlignment(.center)
                        .accessibilityElement(children: .combine)
                    }

                    Button("Done", action: onDone)
                        .buttonStyle(.bigButton)
                        .accessibilityHint("Closes this screen.")
                }
                .padding(24)
                .calmCard()
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .calmScreenWidth()
            }
        }
        .sensoryFeedback(.success, trigger: didAppear)
        .onAppear {
            validationText = makeValidationText()
            joke = ContentProvider.shared.nextJoke()
            if reduceMotion {
                checkmarkScale = 1.0
            } else {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    checkmarkScale = 1.0
                }
            }
            didAppear = true
        }
        .task {
            guard !voiceOverEnabled else { return }
            try? await Task.sleep(for: .seconds(12))
            if !Task.isCancelled {
                onDone()
            }
        }
    }

    private func makeValidationText() -> String {
        let name = userName.isEmpty ? "friend" : userName
        let period = TimeOfDay.current(for: dose.scheduledTime).medicinePeriodLabel
        guard let template = ContentProvider.shared.nextValidation() else {
            return "Well done, \(name). That's your \(period) medicine done."
        }
        return template.text
            .replacingOccurrences(of: "{name}", with: name)
            .replacingOccurrences(of: "{period}", with: period)
    }
}

#if DEBUG
#Preview {
    TakenView(
        userName: "Mary",
        dose: DueDose(
            medicine: Medicine(name: "Metformin", dose: "500 mg", form: .tablet, instructions: "With food"),
            scheduledTime: Date()
        ),
        onDone: {}
    )
}
#endif
