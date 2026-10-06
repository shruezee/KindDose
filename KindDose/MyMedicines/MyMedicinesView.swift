//
//  MyMedicinesView.swift
//  KindDose
//

import SwiftUI
import SwiftData

struct MyMedicinesView: View {
    @Query(sort: \Medicine.createdAt) private var medicines: [Medicine]
    @State private var showAddFlow = false

    var body: some View {
        ZStack {
            CalmBackground()

            ScrollView {
                VStack(spacing: 20) {
                    Text("My medicines")
                        .font(.largeTitle.bold())
                        .accessibilityAddTraits(.isHeader)
                        .calmCard()

                    if medicines.isEmpty {
                        Text("No medicines yet.")
                            .font(.body)
                            .calmCard()
                    } else {
                        VStack(spacing: 14) {
                            ForEach(medicines) { medicine in
                                medicineRow(medicine)
                            }
                        }
                    }

                    Button("Add a medicine") {
                        showAddFlow = true
                    }
                    .buttonStyle(.bigButton)
                    .accessibilityHint("Starts adding a new medicine.")
                }
                .padding(24)
                .calmScreenWidth()
            }
        }
        .navigationTitle("My medicines")
        .toolbarBackground(Color(.systemBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationDestination(isPresented: $showAddFlow) {
            AddMedicineMethodPickerView()
        }
    }

    private func medicineRow(_ medicine: Medicine) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(medicine.name)
                .font(.title3.bold())
            Text(medicine.dose)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .calmCard()
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        MyMedicinesView()
    }
    .modelContainer(for: [Medicine.self, DoseLog.self, UserSettings.self], inMemory: true)
}
#endif
