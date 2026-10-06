//
//  KindDoseWidget.swift
//  KindDoseWidget
//
//  Created by shruthi palchandar on 2/10/2026.
//

import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

struct NextDoseEntry: TimelineEntry {
    let date: Date
    let medicineName: String?
    let dose: String?
    let scheduledTime: Date?
    let isDueNow: Bool
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> NextDoseEntry {
        NextDoseEntry(date: Date(), medicineName: "Metformin", dose: "500 mg", scheduledTime: Date(), isDueNow: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (NextDoseEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextDoseEntry>) -> Void) {
        let entry = currentEntry()
        let soonestReasonableRefresh = Date().addingTimeInterval(15 * 60)
        let refreshDate = entry.scheduledTime.map { max($0, soonestReasonableRefresh) } ?? Date().addingTimeInterval(30 * 60)
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }

    private func currentEntry() -> NextDoseEntry {
        let emptyEntry = NextDoseEntry(date: Date(), medicineName: nil, dose: nil, scheduledTime: nil, isDueNow: false)

        guard let container = try? AppGroup.makeModelContainer(schema: Schema([Medicine.self, DoseLog.self])) else {
            return emptyEntry
        }
        let context = ModelContext(container)
        let medicines = (try? context.fetch(FetchDescriptor<Medicine>(predicate: #Predicate { $0.isActive }))) ?? []
        let logs = (try? context.fetch(FetchDescriptor<DoseLog>())) ?? []

        guard let next = WidgetDoseResolver.nextDue(medicines: medicines, logs: logs) else {
            return emptyEntry
        }

        return NextDoseEntry(
            date: Date(),
            medicineName: next.medicine.name,
            dose: next.medicine.dose,
            scheduledTime: next.scheduledTime,
            isDueNow: next.scheduledTime <= Date()
        )
    }
}

struct KindDoseWidgetEntryView: View {
    var entry: NextDoseEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    private var timeText: String {
        guard let time = entry.scheduledTime else { return "" }
        return time.formatted(date: .omitted, time: .shortened)
    }

    @ViewBuilder
    private var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let name = entry.medicineName {
                Text(entry.isDueNow ? "Due now" : "Next")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(name)
                    .font(.headline)
                    .lineLimit(2)
                if let dose = entry.dose, !dose.isEmpty {
                    Text(dose)
                        .font(.caption)
                }
                Text(timeText)
                    .font(.caption.weight(.semibold))
            } else {
                Text("All done 🌿")
                    .font(.headline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(4)
        .containerBackground(.fill.tertiary, for: .widget)
    }

    @ViewBuilder
    private var mediumView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                if let name = entry.medicineName {
                    Text(entry.isDueNow ? "Due now" : "Next: \(timeText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(name)
                        .font(.title3.bold())
                        .lineLimit(2)
                    if let dose = entry.dose, !dose.isEmpty {
                        Text(dose)
                            .font(.body)
                    }
                } else {
                    Text("All done for now 🌿")
                        .font(.title3.bold())
                }
            }
            Spacer()
            if entry.medicineName != nil {
                Button(intent: TookMedicineIntent()) {
                    Text("✅ I took it")
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("I took it")
                .accessibilityHint("Logs \(entry.medicineName ?? "this medicine") as taken now.")
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    @ViewBuilder
    private var circularView: some View {
        Group {
            if entry.medicineName != nil {
                VStack(spacing: 2) {
                    Image(systemName: entry.isDueNow ? "pills.fill" : "clock.fill")
                    Text(timeText)
                        .font(.caption2)
                }
            } else {
                Image(systemName: "checkmark.circle.fill")
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    @ViewBuilder
    private var rectangularView: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let name = entry.medicineName {
                Text(name)
                    .font(.headline)
                    .lineLimit(1)
                Text(entry.isDueNow ? "Due now" : "Next: \(timeText)")
                    .font(.caption)
            } else {
                Text("All done for now 🌿")
                    .font(.headline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct KindDoseWidget: Widget {
    let kind: String = "KindDoseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            KindDoseWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Next dose")
        .description("Shows your next medicine and lets you log it as taken.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

#if DEBUG
#Preview(as: .systemSmall) {
    KindDoseWidget()
} timeline: {
    NextDoseEntry(date: .now, medicineName: "Metformin", dose: "500 mg", scheduledTime: .now, isDueNow: true)
}

#Preview("Medium", as: .systemMedium) {
    KindDoseWidget()
} timeline: {
    NextDoseEntry(date: .now, medicineName: "Metformin", dose: "500 mg", scheduledTime: .now, isDueNow: true)
}
#endif
