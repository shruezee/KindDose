//
//  AddMedicineMethodPickerView.swift
//  KindDose
//

import SwiftUI
import SwiftData
import HealthKit

/// "How would you like to add this medicine?" — every path from here ends on
/// AddMedicineConfirmView's "Is this correct?" screen; nothing saves automatically.
struct AddMedicineMethodPickerView: View {
    @State private var selectedMethod: AddMedicineMethod?

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

    var body: some View {
        ZStack {
            CalmBackground()

            ScrollView {
                VStack(spacing: 20) {
                    Text("How would you like to add this medicine?")
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)

                    VStack(spacing: 14) {
                        ForEach(availableMethods) { method in
                            Button(method.displayName) {
                                selectedMethod = method
                            }
                            .buttonStyle(.bigButton)
                            .accessibilityHint(method.hint)
                        }
                    }
                }
                .padding(24)
                .calmCard()
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .calmScreenWidth()
            }
        }
        .navigationTitle("Add a medicine")
        .toolbarBackground(Color(.systemBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationDestination(item: $selectedMethod) { method in
            switch method {
            case .type:
                AddMedicineConfirmView(draft: MedicineDraft())
            case .scan:
                ScanMedicineView()
            case .speak:
                SpeakMedicineView()
            case .healthImport:
                if #available(iOS 26, *) {
                    HealthImportView()
                } else {
                    EmptyView()
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        AddMedicineMethodPickerView()
    }
    .modelContainer(for: [Medicine.self, DoseLog.self, UserSettings.self], inMemory: true)
}
#endif
