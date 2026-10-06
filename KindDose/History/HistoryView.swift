//
//  HistoryView.swift
//  KindDose
//

import SwiftUI
import SwiftData

/// This week's doses as large, plain rows. Taken is always a green check plus the
/// word "Taken"; missed or skipped is a soft grey dot plus the word — never a red
/// cross, never "streak broken." A streak line only ever appears when there's a
/// streak to be kind about.
struct HistoryView: View {
    @Query(filter: #Predicate<Medicine> { $0.isActive }) private var medicines: [Medicine]
    @Query private var logs: [DoseLog]

    private var days: [HistoryDay] {
        HistoryResolver.thisWeek(medicines: medicines, logs: logs)
    }

    private var streak: Int {
        HistoryResolver.currentStreak(medicines: medicines, logs: logs)
    }

    var body: some View {
        ZStack {
            CalmBackground()

            ScrollView {
                VStack(spacing: 20) {
                    Text("This week")
                        .font(.largeTitle.bold())
                        .accessibilityAddTraits(.isHeader)
                        .calmCard()

                    if streak > 0 {
                        Text("\(streak) day\(streak == 1 ? "" : "s") in a row 🌱")
                            .font(.title3.bold())
                            .multilineTextAlignment(.center)
                            .calmCard()
                            .accessibilityLabel("\(streak) day\(streak == 1 ? "" : "s") in a row")
                    }

                    if days.isEmpty {
                        Text("Nothing logged yet this week.")
                            .font(.body)
                            .calmCard()
                    } else {
                        VStack(spacing: 14) {
                            ForEach(days) { day in
                                dayRow(day)
                            }
                        }
                    }
                }
                .padding(24)
                .calmScreenWidth()
            }
        }
        .navigationTitle("History")
        .toolbarBackground(Color(.systemBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private func dayRow(_ day: HistoryDay) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(day.label)
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)

            WrapLayout(spacing: 8) {
                ForEach(day.occurrences) { occurrence in
                    occurrenceChip(occurrence)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .calmCard()
    }

    private func occurrenceChip(_ occurrence: HistoryOccurrence) -> some View {
        let isTaken = occurrence.status == .taken || occurrence.status == .takenLate
        return HStack(spacing: 6) {
            if isTaken {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.green)
            } else {
                Image(systemName: "circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.gray.opacity(0.5))
            }
            Text(occurrence.status.displayName)
                .font(.body)
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 44)
        .background(Color.gray.opacity(0.1))
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(occurrence.medicineName), \(occurrence.status.displayName)")
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        HistoryView()
    }
    .modelContainer(for: [Medicine.self, DoseLog.self, UserSettings.self], inMemory: true)
}

#Preview("With history") {
    let container = try! ModelContainer(
        for: Schema([Medicine.self, DoseLog.self, UserSettings.self]),
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = container.mainContext
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())

    let medicine = Medicine(name: "Metformin", dose: "500 mg", form: .tablet, times: [
        DateComponents(hour: 8, minute: 0),
        DateComponents(hour: 20, minute: 0),
    ])
    context.insert(medicine)

    for offset in -4...0 {
        guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
        for hour in [8, 20] {
            guard let scheduledTime = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day),
                  scheduledTime <= Date()
            else { continue }
            let status: DoseStatus = (offset == -3 && hour == 20) ? .skipped : .taken
            context.insert(DoseLog(medicine: medicine, scheduledTime: scheduledTime, status: status, loggedAt: scheduledTime))
        }
    }

    return NavigationStack {
        HistoryView()
    }
    .modelContainer(container)
}
#endif
