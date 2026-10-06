//
//  MissedView.swift
//  KindDose
//

import SwiftUI

/// Shown when a dose went unlogged past its final reminder. Kind, never guilt —
/// no red, no ❌, no "failed/forgot." Offers to log it late, skip it, or breathe
/// for a moment; never suggests taking a late or double dose.
struct MissedView: View {
    var userName: String
    var medicineName: String
    var onResolve: (DoseStatus) -> Void

    @State private var validationText = ""
    @State private var showBreathing = false

    var body: some View {
        ZStack {
            CalmBackground()

            ScrollView {
                VStack(spacing: 24) {
                    Text("🌱")
                        .font(.system(size: 56))
                        .accessibilityHidden(true)

                    Text(validationText)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)

                    Button("I took it late") {
                        onResolve(.takenLate)
                    }
                    .buttonStyle(.bigButton)
                    .accessibilityHint("Logs \(medicineName) as taken, a little later than planned.")

                    Button("I skipped it") {
                        onResolve(.skipped)
                    }
                    .buttonStyle(.bigButton)
                    .accessibilityHint("Logs \(medicineName) as skipped for this time.")

                    Button("🫁 Breathe with me") {
                        showBreathing = true
                    }
                    .font(.body.weight(.semibold))
                    .frame(minHeight: 60)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("Breathe with me")
                    .accessibilityHint("Opens a short calming breathing exercise.")

                    Text("Not sure what to do? Check your medicine leaflet or ask your pharmacist.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .calmCard()
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .calmScreenWidth()
            }
        }
        .onAppear {
            validationText = makeValidationText()
        }
        .fullScreenCover(isPresented: $showBreathing) {
            BreatheView { showBreathing = false }
        }
    }

    private func makeValidationText() -> String {
        let name = userName.isEmpty ? "friend" : userName
        guard let template = ContentProvider.shared.nextMissedValidation() else {
            return "That's okay, \(name). Everyone misses one sometimes."
        }
        return template.text.replacingOccurrences(of: "{name}", with: name)
    }
}

#if DEBUG
#Preview {
    MissedView(userName: "Mary", medicineName: "Metformin", onResolve: { _ in })
}
#endif
