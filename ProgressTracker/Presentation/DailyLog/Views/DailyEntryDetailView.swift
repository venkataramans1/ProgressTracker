import SwiftUI

struct DailyEntryDetailView: View {
    let entry: DailyEntry

    var body: some View {
        List {
            Section("Overview") {
                HStack {
                    Label("Date", systemImage: "calendar")
                    Spacer()
                    Text(entry.date, style: .date)
                }
                HStack {
                    Label("Mood", systemImage: entry.resolvedMood.systemImageName)
                    Spacer()
                    Text(entry.resolvedMood.label)
                }
                HStack {
                    Label("Completed", systemImage: entry.isCompleted ? "checkmark.circle.fill" : "xmark.circle")
                    Spacer()
                    Text(entry.isCompleted ? "Yes" : "No")
                }
            }

            if !entry.metrics.isEmpty {
                Section("Metrics") {
                    ForEach(entry.metrics.sorted(by: { $0.key < $1.key }), id: \.key) { metric, value in
                        HStack {
                            Text(metric)
                            Spacer()
                            Text(value.formatted())
                        }
                    }
                }
            }

            if !entry.notes.isEmpty {
                Section("Notes") {
                    Text(entry.notes)
                        .font(.body)
                }
            }
        }
        .navigationTitle("Entry Details")
    }
}
