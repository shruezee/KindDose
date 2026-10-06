//
//  AddMethodStepView.swift
//  KindDose
//

import SwiftUI
import UIKit
import HealthKit

struct AddMethodStepView: View {
    @Binding var selection: AddMedicineMethod
    var isCarerMode: Bool
    var onNext: () -> Void
    var onBack: () -> Void

    @State private var isVoiceOverRunning = UIAccessibility.isVoiceOverRunning

    private var availableMethods: [AddMedicineMethod] {
        var methods: [AddMedicineMethod] = [.scan, .speak, .type]
        if healthImportAvailable {
            methods.append(.healthImport)
        }
        return methods
    }

    private var healthImportAvailable: Bool {
        if #available(iOS 26, *) {
            return HKHealthStore.isHealthDataAvailable()
        }
        return false
    }

    /// VoiceOver users benefit most from Speak; a carer entering someone else's
    /// medicines benefits most from Scan; everyone else defaults to Type.
    private var recommendedMethod: AddMedicineMethod {
        if isVoiceOverRunning { return .speak }
        if isCarerMode { return .scan }
        return .type
    }

    var body: some View {
        OnboardingScaffold(step: .addMethod, onBack: onBack) {
            VStack(spacing: 20) {
                Text("How would you like to add medicines?")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text("You can always use a different way later.")
                    .font(.body)
                    .multilineTextAlignment(.center)

                VStack(spacing: 14) {
                    ForEach(availableMethods) { method in
                        let isRecommended = method == recommendedMethod
                        Button {
                            selection = method
                            onNext()
                        } label: {
                            VStack(spacing: 4) {
                                Text(method.displayName)
                                if isRecommended {
                                    Text("Recommended for you")
                                        .font(.footnote)
                                }
                            }
                        }
                        .buttonStyle(.bigButton)
                        .accessibilityLabel(isRecommended ? "\(method.displayName), recommended for you" : method.displayName)
                        .accessibilityHint(method.hint)
                    }
                }
            }
        }
        .task {
            for await _ in NotificationCenter.default.notifications(named: UIAccessibility.voiceOverStatusDidChangeNotification) {
                isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
            }
        }
    }
}

#if DEBUG
#Preview {
    AddMethodStepView(selection: .constant(.type), isCarerMode: false, onNext: {}, onBack: {})
}
#endif
