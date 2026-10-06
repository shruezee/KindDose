//
//  AddMedicineConfirmView.swift
//  KindDose
//

import SwiftUI
import SwiftData
import UIKit
import WidgetKit

/// The "Is this correct?" screen every add method ends on. Nothing from a scan,
/// a spoken phrase, or Health is ever saved automatically — the person always
/// reviews and can edit every field here before saving.
struct AddMedicineConfirmView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State var draft: MedicineDraft
    /// When set (e.g. confirming several Health imports in a row), save() calls this
    /// instead of dismissing, so the caller can advance to the next draft itself.
    var onSaved: (() -> Void)?

    @State private var isAddingTime = false
    @State private var newTime = Date()

    var body: some View {
        ZStack {
            CalmBackground()

            ScrollView {
                VStack(spacing: 20) {
                    Text("Is this correct?")
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)

                    if let photoData = draft.photo, let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .accessibilityHidden(true)
                    }

                    VStack(alignment: .leading, spacing: 20) {
                        field(title: "Name") {
                            TextField("Medicine name", text: $draft.name)
                                .font(.title3)
                                .textFieldStyle(.roundedBorder)
                                .frame(minHeight: 60)
                                .accessibilityLabel("Medicine name")
                                .accessibilityHint("Edit the name of this medicine.")
                        }

                        field(title: "Dose") {
                            TextField("e.g. 500 mg", text: $draft.dose)
                                .font(.title3)
                                .textFieldStyle(.roundedBorder)
                                .frame(minHeight: 60)
                                .accessibilityLabel("Dose")
                                .accessibilityHint("Edit the dose, for example 500 mg.")
                        }

                        field(title: "Form") {
                            formPicker
                        }

                        field(title: "Instructions") {
                            TextField("e.g. With food", text: $draft.instructions)
                                .font(.title3)
                                .textFieldStyle(.roundedBorder)
                                .frame(minHeight: 60)
                                .accessibilityLabel("Instructions")
                                .accessibilityHint("Edit any instructions, for example with food.")
                        }

                        field(title: "Times each day") {
                            timesEditor
                        }
                    }

                    Button("Save", action: save)
                        .buttonStyle(.bigButton)
                        .disabled(isNameEmpty)
                        .accessibilityHint(isNameEmpty ? "Enter a name before saving." : "Saves this medicine.")

                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.body.weight(.semibold))
                    .frame(minHeight: 60)
                    .frame(maxWidth: .infinity)
                    .accessibilityHint("Closes without saving.")
                }
                .padding(24)
                .calmCard()
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .calmScreenWidth()
            }
        }
        .navigationTitle("Is this correct?")
        .toolbarBackground(Color(.systemBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var isNameEmpty: Bool {
        draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func field<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            content()
        }
    }

    private var formPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(MedicineForm.allCases) { form in
                    let isSelected = draft.form == form
                    Button(form.displayName) {
                        draft.form = form
                    }
                    .font(.body.weight(.semibold))
                    .padding(.horizontal, 16)
                    .frame(minHeight: 60)
                    .foregroundStyle(isSelected ? Color.white : CalmColor.actionBackground)
                    .background(isSelected ? CalmColor.actionBackground : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(CalmColor.actionBackground, lineWidth: 1.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityLabel(form.displayName)
                    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                    .accessibilityHint("Sets the medicine form to \(form.displayName).")
                }
            }
        }
    }

    private var timesEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            if draft.times.isEmpty {
                Text("No times set yet.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            ForEach(Array(draft.times.enumerated()), id: \.offset) { index, components in
                HStack {
                    Text(timeLabel(for: components))
                        .font(.body.weight(.semibold))
                    Spacer()
                    Button {
                        draft.times.remove(at: index)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                    }
                    .frame(minWidth: 60, minHeight: 60)
                    .accessibilityLabel("Remove \(timeLabel(for: components))")
                    .accessibilityHint("Removes this time from the schedule.")
                }
                .padding(.horizontal, 12)
                .frame(minHeight: 60)
                .background(Color.gray.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            if isAddingTime {
                HStack(spacing: 12) {
                    DatePicker("New time", selection: $newTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .accessibilityLabel("New time")

                    Button("Add") {
                        let components = Calendar.current.dateComponents([.hour, .minute], from: newTime)
                        draft.times.append(components)
                        isAddingTime = false
                    }
                    .font(.body.weight(.semibold))
                    .frame(minWidth: 60, minHeight: 60)
                    .accessibilityHint("Adds this time to the schedule.")
                }
            } else {
                Button("+ Add a time") {
                    isAddingTime = true
                }
                .font(.body.weight(.semibold))
                .frame(minHeight: 60)
                .frame(maxWidth: .infinity)
                .accessibilityHint("Adds another time to the schedule.")
            }
        }
    }

    private func timeLabel(for components: DateComponents) -> String {
        let date = Calendar.current.date(
            bySettingHour: components.hour ?? 0,
            minute: components.minute ?? 0,
            second: 0,
            of: Date()
        ) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }

    private func save() {
        let medicine = Medicine(
            name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
            dose: draft.dose.trimmingCharacters(in: .whitespacesAndNewlines),
            form: draft.form,
            instructions: draft.instructions.trimmingCharacters(in: .whitespacesAndNewlines),
            photo: draft.photo,
            times: draft.times
        )
        modelContext.insert(medicine)
        WidgetCenter.shared.reloadAllTimelines()

        if let onSaved {
            onSaved()
        } else {
            dismiss()
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        AddMedicineConfirmView(draft: MedicineDraft(name: "Metformin", dose: "500 mg", times: [DateComponents(hour: 8, minute: 0)]))
    }
    .modelContainer(for: [Medicine.self, DoseLog.self, UserSettings.self], inMemory: true)
}
#endif
