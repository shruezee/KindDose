//
//  SettingsView.swift
//  KindDose
//

import SwiftUI
import SwiftData
import UIKit
import UserNotifications

struct SettingsView: View {
    @Query private var settingsList: [UserSettings]
    @Query(filter: #Predicate<Medicine> { $0.isActive }) private var medicines: [Medicine]
    @Query private var logs: [DoseLog]

    @Environment(\.openURL) private var openURL

    @State private var alarmPermissionDenied = false
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    private var settings: UserSettings? { settingsList.first }

    var body: some View {
        ZStack {
            CalmBackground()

            ScrollView {
                VStack(spacing: 20) {
                    Text("Settings")
                        .font(.largeTitle.bold())
                        .accessibilityAddTraits(.isHeader)
                        .calmCard()

                    nameCard
                    textSizeCard
                    whoForCard
                    jokesCard
                    breathingCard

                    if ReminderScheduler.shared.isAlarmKitAvailable {
                        alarmSoundCard
                    }

                    remindersCard
                    aboutSafetyCard
                    privacyCard
                }
                .padding(24)
                .calmScreenWidth()
            }
        }
        .navigationTitle("Settings")
        .toolbarBackground(Color(.systemBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task { await refreshNotificationStatus() }
    }

    // MARK: - Name

    private var nameCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your name")
                .font(.headline)

            TextField("Your name", text: nameBinding)
                .font(.title3)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .frame(minHeight: 60)
                .accessibilityLabel("Your name")
                .accessibilityHint("This is how KindDose greets you.")
        }
        .padding()
        .calmCard()
    }

    private var nameBinding: Binding<String> {
        Binding(
            get: { settings?.userName ?? "" },
            set: { settings?.userName = $0 }
        )
    }

    // MARK: - Text size

    private var textSizeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Text size")
                .font(.headline)

            Text("Makes KindDose's text at least this big, however your iPhone's own text size is set.")
                .font(.body)
                .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                ForEach(TextSizePreference.allCases) { option in
                    let isSelected = settings?.textSizePreference == option
                    Button {
                        settings?.textSizePreference = option
                    } label: {
                        HStack {
                            Text(option.displayName)
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .accessibilityHidden(true)
                            }
                        }
                    }
                    .buttonStyle(.bigButton)
                    .accessibilityLabel(isSelected ? "\(option.displayName), selected" : option.displayName)
                    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                    .accessibilityHint("Sets the text size to \(option.displayName).")
                }
            }
        }
        .padding()
        .calmCard()
    }

    // MARK: - Who this is for

    private var whoForCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: carerModeBinding) {
                Text("I'm caring for someone else")
                    .font(.body.weight(.semibold))
            }
            .tint(CalmColor.actionBackground)
            .frame(minHeight: 60)
            .contentShape(Rectangle())
            .accessibilityHint("Turn this on if you're setting up and checking on someone else's medicines.")
        }
        .padding()
        .calmCard()
    }

    private var carerModeBinding: Binding<Bool> {
        Binding(
            get: { settings?.isCarerMode ?? false },
            set: { settings?.isCarerMode = $0 }
        )
    }

    // MARK: - Show jokes

    private var jokesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: jokesBinding) {
                Text("😄 Show jokes")
                    .font(.body.weight(.semibold))
            }
            .tint(CalmColor.actionBackground)
            .frame(minHeight: 60)
            .contentShape(Rectangle())
            .accessibilityLabel("Show jokes")
            .accessibilityHint("Turns the joke of the day and after-dose jokes on or off.")
        }
        .padding()
        .calmCard()
    }

    private var jokesBinding: Binding<Bool> {
        Binding(
            get: { settings?.showJokes ?? true },
            set: { settings?.showJokes = $0 }
        )
    }

    // MARK: - Show breathing

    private var breathingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: breathingBinding) {
                Text("🫁 Show breathing")
                    .font(.body.weight(.semibold))
            }
            .tint(CalmColor.actionBackground)
            .frame(minHeight: 60)
            .contentShape(Rectangle())
            .accessibilityLabel("Show breathing")
            .accessibilityHint("Turns the \"Breathe with me\" option on Home on or off.")
        }
        .padding()
        .calmCard()
    }

    private var breathingBinding: Binding<Bool> {
        Binding(
            get: { settings?.showBreathing ?? true },
            set: { settings?.showBreathing = $0 }
        )
    }

    // MARK: - Alarm sound (iOS 26.1+)

    private var alarmSoundCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: alarmSoundBinding) {
                Text("Use alarm sound that rings even in Silent mode")
                    .font(.body.weight(.semibold))
            }
            .tint(CalmColor.actionBackground)
            .frame(minHeight: 60)
            .contentShape(Rectangle())
            .accessibilityHint("Turns your medicine reminders into alarms that ring even when your phone is on Silent.")

            if alarmPermissionDenied {
                Text("KindDose needs alarm permission to do this. You can allow it in Settings → KindDose.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .calmCard()
    }

    private var alarmSoundBinding: Binding<Bool> {
        Binding(
            get: { settings?.useAlarmSound ?? false },
            set: { setAlarmSound($0) }
        )
    }

    @MainActor
    private func setAlarmSound(_ enabled: Bool) {
        guard let settings else { return }
        Task { @MainActor in
            let granted = enabled ? await ReminderScheduler.shared.requestAlarmAuthorization() : true
            settings.useAlarmSound = enabled && granted
            alarmPermissionDenied = enabled && !granted
            await ReminderScheduler.shared.rebuildAll(medicines: medicines, logs: logs, useAlarmSound: settings.useAlarmSound)
        }
    }

    // MARK: - Manage reminders

    private var remindersCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reminders")
                .font(.headline)

            Text(notificationStatusText)
                .font(.body)
                .foregroundStyle(.secondary)

            Button("Manage reminders") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            .font(.body.weight(.semibold))
            .frame(minHeight: 60)
            .frame(maxWidth: .infinity)
            .accessibilityHint("Opens iPhone Settings, where you can turn KindDose's reminders on or off.")
        }
        .padding()
        .calmCard()
    }

    private var notificationStatusText: String {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral: "Reminders are on."
        case .denied: "Reminders are off. Turn them on in iPhone Settings to get notified."
        default: "Reminders aren't set up yet."
        }
    }

    private func refreshNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationStatus = settings.authorizationStatus
    }

    // MARK: - About & safety

    private var aboutSafetyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About & safety")
                .font(.headline)

            Text("KindDose is a reminder tool, not medical advice.")
                .font(.body)

            Text("If you're ever unsure about your medicines, check the leaflet or ask your pharmacist.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding()
        .calmCard()
        .accessibilityElement(children: .combine)
    }

    // MARK: - Privacy

    private var privacyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Privacy")
                .font(.headline)

            Text("Everything stays on your iPhone.")
                .font(.body)

            Text("KindDose has no accounts, no analytics, and no ads. Your medicines and history never leave this device.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding()
        .calmCard()
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: [Medicine.self, DoseLog.self, UserSettings.self], inMemory: true)
}
#endif
