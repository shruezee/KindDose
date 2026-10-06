//
//  HealthImportView.swift
//  KindDose
//

import SwiftUI
import HealthKit

/// Imports medicines already tracked in Health, iOS 26+ only. Shows a list to
/// choose from, then walks through the "Is this correct?" confirm screen once
/// per selected medicine — nothing imports automatically.
@available(iOS 26, *)
struct HealthImportView: View {
    @State private var items: [HKUserAnnotatedMedication] = []
    @State private var selected: Set<HKUserAnnotatedMedication> = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var confirmQueue: [HKUserAnnotatedMedication] = []
    @State private var currentDraft: MedicineDraft?

    private let healthStore = HKHealthStore()

    var body: some View {
        ZStack {
            CalmBackground()

            ScrollView {
                VStack(spacing: 20) {
                    Text("Import from Health")
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                        .calmCard()

                    if isLoading {
                        ProgressView("Looking for your medicines…")
                            .calmCard()
                    } else if let errorMessage {
                        Text(errorMessage)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .calmCard()
                    } else if items.isEmpty {
                        Text("No medicines found in Health yet.")
                            .font(.body)
                            .calmCard()
                    } else {
                        VStack(spacing: 10) {
                            ForEach(items, id: \.self) { item in
                                row(for: item)
                            }
                        }

                        Button("Continue") {
                            startConfirming()
                        }
                        .buttonStyle(.bigButton)
                        .disabled(selected.isEmpty)
                        .accessibilityHint(selected.isEmpty ? "Select at least one medicine first." : "Reviews each selected medicine, one at a time.")
                    }
                }
                .padding(24)
                .calmScreenWidth()
            }
        }
        .navigationTitle("Health")
        .toolbarBackground(Color(.systemBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task { await load() }
        .navigationDestination(item: $currentDraft) { draft in
            AddMedicineConfirmView(draft: draft, onSaved: advanceQueue)
        }
    }

    private func row(for item: HKUserAnnotatedMedication) -> some View {
        let isSelected = selected.contains(item)
        return Button {
            if isSelected {
                selected.remove(item)
            } else {
                selected.insert(item)
            }
        } label: {
            HStack {
                Text(item.medication.displayText)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.bigButton)
        .accessibilityLabel(isSelected ? "\(item.medication.displayText), selected" : item.medication.displayText)
        .accessibilityHint("Toggles whether to import this medicine.")
    }

    private func load() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            errorMessage = "Health isn't available on this device."
            isLoading = false
            return
        }
        let medicationType = HKObjectType.userAnnotatedMedicationType()
        do {
            try await healthStore.requestAuthorization(toShare: [], read: [medicationType])
        } catch {
            errorMessage = "KindDose couldn't get permission to read Health."
            isLoading = false
            return
        }
        await fetchMedications()
    }

    private func fetchMedications() async {
        await withCheckedContinuation { continuation in
            let query = HKUserAnnotatedMedicationQuery(predicate: nil, limit: HKObjectQueryNoLimit) { _, medication, done, _ in
                if let medication {
                    DispatchQueue.main.async {
                        items.append(medication)
                    }
                }
                if done {
                    DispatchQueue.main.async {
                        isLoading = false
                    }
                    continuation.resume()
                }
            }
            healthStore.execute(query)
        }
    }

    private func startConfirming() {
        confirmQueue = items.filter { selected.contains($0) }
        advanceQueue()
    }

    private func advanceQueue() {
        guard !confirmQueue.isEmpty else {
            currentDraft = nil
            return
        }
        let next = confirmQueue.removeFirst()
        var draft = MedicineDraft()
        draft.name = next.medication.displayText
        currentDraft = draft
    }
}
