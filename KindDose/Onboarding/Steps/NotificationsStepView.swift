//
//  NotificationsStepView.swift
//  KindDose
//

import SwiftUI

struct NotificationsStepView: View {
    var onBack: () -> Void
    var onFinish: () -> Void

    private enum PermissionState {
        case notRequested, granted, denied
    }

    @State private var permissionState: PermissionState = .notRequested

    var body: some View {
        OnboardingScaffold(step: .notifications, onBack: onBack) {
            VStack(spacing: 24) {
                Text("Can I send you reminders?")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text("A gentle notification at your medicine times, right on your lock screen. Nothing else — no ads, no extra messages.")
                    .font(.body)
                    .multilineTextAlignment(.center)

                switch permissionState {
                case .notRequested:
                    Button("Allow reminders") {
                        requestPermission()
                    }
                    .buttonStyle(.bigButton)
                    .accessibilityHint("Asks your phone to allow medicine reminders.")

                case .granted:
                    Text("Reminders are on. You're all set.")
                        .font(.body.weight(.semibold))
                        .multilineTextAlignment(.center)

                    Button("Finish setup", action: onFinish)
                        .buttonStyle(.bigButton)

                case .denied:
                    Text("That's okay. You can turn reminders on anytime in Settings → Notifications → KindDose.")
                        .font(.body)
                        .multilineTextAlignment(.center)

                    Button("Finish setup", action: onFinish)
                        .buttonStyle(.bigButton)
                }
            }
        }
    }

    private func requestPermission() {
        Task {
            let granted = await ReminderScheduler.shared.requestNotificationAuthorization()
            permissionState = granted ? .granted : .denied
        }
    }
}

#if DEBUG
#Preview {
    NotificationsStepView(onBack: {}, onFinish: {})
}
#endif
