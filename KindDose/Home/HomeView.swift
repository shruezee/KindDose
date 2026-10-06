//
//  HomeView.swift
//  KindDose
//

import SwiftUI
import SwiftData
import UIKit
import WidgetKit

private enum HomeDestination: Hashable {
    case myMedicines, history, settings
}

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(filter: #Predicate<Medicine> { $0.isActive }) private var medicines: [Medicine]
    @Query private var logs: [DoseLog]
    @Query private var settingsList: [UserSettings]

    @State private var now = Date()
    @State private var snoozedDoseID: String?
    @State private var snoozedUntil: Date?
    @State private var takenDose: DueDose?
    @State private var missedLog: DoseLog?
    @State private var showBreathing = false

    private var userName: String { settingsList.first?.userName ?? "" }
    private var showJokes: Bool { settingsList.first?.showJokes ?? true }
    private var showBreathingEntry: Bool { settingsList.first?.showBreathing ?? true }
    private var useAlarmSound: Bool { settingsList.first?.useAlarmSound ?? false }

    /// The earliest unresolved missed dose, if any — surfaced on next open per project.md.
    private var earliestMissedLog: DoseLog? {
        logs.filter { $0.status == .missed }.sorted { $0.scheduledTime < $1.scheduledTime }.first
    }

    private var summary: HomeDoseSummary {
        HomeDoseResolver.summary(medicines: medicines, logs: logs, now: now)
    }

    /// The due dose to actually show — nil while it's snoozed, even if it's technically still due.
    private var effectiveDueDose: DueDose? {
        guard let due = summary.dueNow else { return nil }
        if due.id == snoozedDoseID, let snoozedUntil, now < snoozedUntil {
            return nil
        }
        return due
    }

    /// What to show on the "Next:" line when something is due right now.
    private var nextAfterDue: DueDose? {
        summary.upcoming
    }

    /// What to show next to "All done for now" when nothing is currently due.
    private var nextWhenNothingDue: DueDose? {
        if let due = summary.dueNow, due.id == snoozedDoseID, let snoozedUntil, now < snoozedUntil {
            return due
        }
        return summary.upcoming
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CalmBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        header

                        if let dueDose = effectiveDueDose {
                            dueCard(for: dueDose)

                            if let next = nextAfterDue {
                                nextLine(for: next)
                            }
                        } else {
                            allDoneCard
                        }

                        if showJokes, let joke = ContentProvider.shared.jokeOfTheDay() {
                            jokeOfTheDayLine(joke)
                        }

                        if showBreathingEntry {
                            breatheEntryLine
                        }

                        toolbarRow
                    }
                    .padding(24)
                    .calmScreenWidth()
                }
            }
            .navigationDestination(for: HomeDestination.self) { destination in
                switch destination {
                case .myMedicines: MyMedicinesView()
                case .history: HistoryView()
                case .settings: SettingsView()
                }
            }
        }
        .fullScreenCover(item: $takenDose) { dose in
            TakenView(userName: userName, dose: dose) {
                takenDose = nil
            }
        }
        .fullScreenCover(item: $missedLog) { log in
            MissedView(userName: userName, medicineName: log.medicine?.name ?? "this medicine") { status in
                resolveMissed(log, as: status)
            }
        }
        .fullScreenCover(isPresented: $showBreathing) {
            BreatheView { showBreathing = false }
        }
        .task {
            await rebuildReminders()
            checkForMissedDose()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                now = Date()
            }
        }
        .onChange(of: medicines) {
            Task { await rebuildReminders() }
        }
        .onChange(of: logs) {
            checkForMissedDose()
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active, !isRunningInPreview {
                ReminderScheduler.shared.sweepMissedDoses(medicines: medicines, logs: logs, modelContext: modelContext)
                Task { await rebuildReminders() }
            }
        }
    }

    /// Surfaces the earliest unresolved missed dose, if there's one and nothing's showing yet.
    private func checkForMissedDose() {
        guard missedLog == nil, takenDose == nil, let next = earliestMissedLog else { return }
        missedLog = next
    }

    private func resolveMissed(_ log: DoseLog, as status: DoseStatus) {
        log.status = status
        log.loggedAt = Date()
        if let medicine = log.medicine {
            ReminderScheduler.shared.cancelEscalations(medicineID: medicine.id, scheduledTime: log.scheduledTime)
        }
        missedLog = nil
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Xcode Previews run without a real notification daemon connection, so scheduling dozens
    /// of requests there is slow and pointless — skip it there, never in the real app.
    private var isRunningInPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    private func rebuildReminders() async {
        guard !isRunningInPreview else { return }
        await ReminderScheduler.shared.rebuildAll(medicines: medicines, logs: logs, useAlarmSound: useAlarmSound)
    }

    // MARK: - Header

    private var header: some View {
        Text(greeting)
            .font(.largeTitle.bold())
            .multilineTextAlignment(.center)
            .accessibilityAddTraits(.isHeader)
            .calmCard()
    }

    private var greeting: String {
        let base: String
        switch Calendar.current.component(.hour, from: now) {
        case 5..<12: base = "Good morning"
        case 12..<17: base = "Good afternoon"
        case 17..<21: base = "Good evening"
        default: base = "Hello"
        }
        return userName.isEmpty ? "\(base)!" : "\(base), \(userName)"
    }

    // MARK: - Due dose card

    private func dueCard(for dose: DueDose) -> some View {
        VStack(spacing: 16) {
            if let photoData = dose.medicine.photo, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .accessibilityHidden(true)
            }

            Text(dose.medicine.name)
                .font(.title.bold())
                .multilineTextAlignment(.center)

            Text(dose.medicine.dose)
                .font(.title3)

            if !dose.medicine.instructions.isEmpty {
                Text(dose.medicine.instructions)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button("✅ I took it") {
                markTaken(dose)
            }
            .buttonStyle(.bigButton)
            .accessibilityLabel("I took it")
            .accessibilityHint("Logs \(dose.medicine.name) as taken now.")

            Button("Remind me in 10 minutes") {
                snooze(dose)
            }
            .font(.body.weight(.semibold))
            .frame(minHeight: 60)
            .frame(maxWidth: .infinity)
            .accessibilityHint("Waits 10 minutes, then shows this reminder again.")
        }
        .padding()
        .calmCard()
    }

    private func nextLine(for dose: DueDose) -> some View {
        Text("Next: \(Self.nextTimeText(dose.scheduledTime))")
            .font(.body)
            .calmCard()
            .accessibilityLabel("Next dose \(Self.nextTimeText(dose.scheduledTime))")
    }

    /// "1:51 pm" for today, "Tomorrow, 1:51 pm" otherwise, so a dose just
    /// logged never looks like it's due again at the same time.
    static func nextTimeText(_ date: Date, now: Date = Date()) -> String {
        let time = date.formatted(date: .omitted, time: .shortened)
        let calendar = Calendar.current
        if calendar.isDate(date, inSameDayAs: now) { return time }
        if calendar.isDateInTomorrow(date) { return "Tomorrow, \(time)" }
        return "\(date.formatted(.dateTime.weekday(.wide))), \(time)"
    }

    // MARK: - Nothing due

    private var allDoneCard: some View {
        VStack(spacing: 12) {
            Text("All done for now 🌿")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .accessibilityLabel("All done for now")

            if let next = nextWhenNothingDue {
                Text("Next: \(Self.nextTimeText(next.scheduledTime))")
                    .font(.body)
                    .accessibilityLabel("Next dose \(Self.nextTimeText(next.scheduledTime))")
            }
        }
        .padding()
        .calmCard()
    }

    // MARK: - Joke of the day

    private func jokeOfTheDayLine(_ joke: Joke) -> some View {
        Text("😄 Joke of the day: \(joke.setup) \(joke.punchline)")
            .font(.footnote)
            .multilineTextAlignment(.center)
            .calmCard()
            .accessibilityLabel("Joke of the day: \(joke.setup) \(joke.punchline)")
    }

    // MARK: - Breathe entry point

    private var breatheEntryLine: some View {
        Button {
            showBreathing = true
        } label: {
            Text("🫁 Breathe with me")
                .font(.body.weight(.semibold))
                .frame(minHeight: 60)
                .frame(maxWidth: .infinity)
        }
        .calmCard()
        .accessibilityLabel("Breathe with me")
        .accessibilityHint("Opens a short calming breathing exercise.")
    }

    // MARK: - Toolbar

    private var toolbarRow: some View {
        HStack(spacing: 12) {
            NavigationLink(value: HomeDestination.myMedicines) {
                toolbarButtonLabel(systemImage: "pills.fill", title: "My medicines")
            }
            .accessibilityLabel("My medicines")
            .accessibilityHint("Opens your medicines list.")

            NavigationLink(value: HomeDestination.history) {
                toolbarButtonLabel(systemImage: "clock.arrow.circlepath", title: "History")
            }
            .accessibilityLabel("History")
            .accessibilityHint("Opens your dose history.")

            NavigationLink(value: HomeDestination.settings) {
                toolbarButtonLabel(systemImage: "gearshape.fill", title: "Settings")
            }
            .accessibilityLabel("Settings")
            .accessibilityHint("Opens settings.")
        }
        .padding()
        .calmCard()
    }

    /// Purely decorative inside its NavigationLink — the link itself carries the single
    /// accessibility label and hint, so VoiceOver doesn't announce the title twice.
    private func toolbarButtonLabel(systemImage: String, title: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.title2)
            Text(title)
                .font(.caption.weight(.semibold))
        }
        .frame(minHeight: 60)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
    }

    // MARK: - Actions

    private func markTaken(_ dose: DueDose) {
        let log = DoseLog(medicine: dose.medicine, scheduledTime: dose.scheduledTime, status: .taken, loggedAt: Date())
        modelContext.insert(log)
        ReminderScheduler.shared.cancelEscalations(medicineID: dose.medicine.id, scheduledTime: dose.scheduledTime)
        takenDose = dose
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func snooze(_ dose: DueDose) {
        snoozedDoseID = dose.id
        snoozedUntil = Date().addingTimeInterval(10 * 60)
        ReminderScheduler.shared.cancelEscalations(medicineID: dose.medicine.id, scheduledTime: dose.scheduledTime)
        ReminderScheduler.shared.scheduleSnooze(medicine: dose.medicine, scheduledTime: dose.scheduledTime)
    }
}

private struct PlaceholderDestinationView: View {
    var title: String

    var body: some View {
        ZStack {
            CalmBackground()
            Text(title)
                .font(.largeTitle.bold())
                .calmCard()
                .accessibilityAddTraits(.isHeader)
        }
        .navigationTitle(title)
    }
}

#if DEBUG
#Preview {
    HomeView()
        .modelContainer(for: [Medicine.self, DoseLog.self, UserSettings.self], inMemory: true)
}

#Preview("With sample medicines") {
    let container = try! ModelContainer(
        for: Schema([Medicine.self, DoseLog.self, UserSettings.self]),
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let morning = DateComponents(hour: 8, minute: 0)
    let evening = DateComponents(hour: 20, minute: 0)

    let samples = [
        Medicine(name: "Metformin", dose: "500 mg", form: .tablet, instructions: "With food", times: [morning, evening]),
        Medicine(name: "Amoxicillin", dose: "250 mg", form: .capsule, instructions: "On an empty stomach", times: [morning]),
        Medicine(name: "Cough syrup", dose: "10 ml", form: .liquid, instructions: "With water", times: [evening]),
    ]
    samples.forEach { container.mainContext.insert($0) }
    container.mainContext.insert(UserSettings(userName: "Mary"))

    return HomeView()
        .modelContainer(container)
}
#endif
