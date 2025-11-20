import SwiftUI
import UIKit

struct ChallengeRow: View {
    let item: DashboardViewModel.ChallengeItem
    let isExpanded: Bool
    let onToggleExpansion: () -> Void
    let onToggleStatus: () -> Void
    let onEditTapped: () -> Void
    let onLogMinutes: (Int) -> Void
    let onSetLoggedMinutes: (Int) -> Void

    @State private var isShowingCustomPicker = false
    @State private var customUnit: CustomUnit = .minutes
    @State private var customValue: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            if isExpanded {
                Divider()
                    .padding(.horizontal, 4)
                expandedContent
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggleExpansion)
        .onChange(of: isExpanded) { expanded in
            if !expanded {
                isShowingCustomPicker = false
            }
        }
        .onChange(of: item.detail.loggedMinutes) { _ in
            if isShowingCustomPicker {
                syncCustomValue()
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: onToggleStatus) {
                Image(systemName: item.detail.isCompleted ? "checkmark.square.fill" : "square")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(item.detail.isCompleted ? .green : .secondary)
                    .accessibilityLabel(item.detail.isCompleted ? "Mark as not started" : "Mark as completed")
            }
            .buttonStyle(.plain)

            Text(item.emoji)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.body.weight(.semibold))
                Text(item.statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.down")
                .font(.footnote.weight(.semibold))
                .foregroundColor(.secondary)
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                .animation(.easeInOut(duration: 0.2), value: isExpanded)
        }
    }

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !item.subtitle.isEmpty {
                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if item.trackingStyle == .trackTime {
                trackingSection
            }

            notesSection

            if !item.detail.photoURLs.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(item.detail.photoURLs, id: \.self) { url in
                        ChallengePhotoThumbnail(url: url)
                            .frame(height: 70)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }
        }
    }

    private var trackingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.timeSummaryLine)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.secondary)
            HStack(spacing: 12) {
                ForEach([15, 30, 45], id: \.self) { minutes in
                    Button("+\(minutes)") {
                        onLogMinutes(minutes)
                    }
                    .buttonStyle(.bordered)
                }
                Button("Custom") {
                    toggleCustomPicker()
                }
                .buttonStyle(.bordered)
            }
            if isShowingCustomPicker {
                customPicker
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Notes", systemImage: "note.text")
                    .font(.headline)
                Spacer()
                Button(action: onEditTapped) {
                    Label("Edit", systemImage: "square.and.pencil")
                        .labelStyle(.iconOnly)
                        .font(.headline)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit notes and photos")
            }
            if let notes = item.detail.notes, !notes.isEmpty {
                Text(notes)
                    .font(.body)
            } else {
                Text("No notes yet")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var customPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Custom value", selection: $customValue) {
                ForEach(customRange, id: \.self) { value in
                    Text("\(value)")
                        .tag(value)
                }
            }
            .labelsHidden()
            .pickerStyle(.wheel)
            .frame(height: 100)
            .clipped()

            Picker("Unit", selection: $customUnit) {
                ForEach(CustomUnit.allCases) { unit in
                    Text(unit.title).tag(unit)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: customUnit) { _ in
                syncCustomValue()
            }

            Text("Custom sets today's total time (overwrites previous).")
                .font(.caption)
                .foregroundColor(.secondary)

            Button("Set") {
                setCustomValue()
            }
            .buttonStyle(.borderedProminent)
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private func toggleCustomPicker() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isShowingCustomPicker.toggle()
        }
        if isShowingCustomPicker {
            syncCustomValue()
        }
    }

    private func syncCustomValue() {
        switch customUnit {
        case .minutes:
            customValue = min(max(0, item.loggedMinutes), 59)
        case .hours:
            customValue = min(max(0, item.loggedMinutes / 60), 24)
        }
    }

    private func setCustomValue() {
        let totalMinutes: Int
        switch customUnit {
        case .minutes:
            totalMinutes = customValue
        case .hours:
            totalMinutes = customValue * 60
        }
        onSetLoggedMinutes(totalMinutes)
        withAnimation(.easeInOut(duration: 0.2)) {
            isShowingCustomPicker = false
        }
    }

    private var customRange: ClosedRange<Int> {
        switch customUnit {
        case .minutes:
            return 0...59
        case .hours:
            return 0...24
        }
    }

    private enum CustomUnit: String, CaseIterable, Identifiable {
        case minutes
        case hours

        var id: String { rawValue }

        var title: String {
            switch self {
            case .minutes: return "Minutes"
            case .hours: return "Hours"
            }
        }
    }
}

struct ChallengePhotoThumbnail: View {
    let url: URL

    var body: some View {
        ZStack {
            if let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .padding(12)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(.tertiarySystemFill))
    }
}

#if DEBUG
struct ChallengeRow_Previews: PreviewProvider {
    static var previews: some View {
        ChallengeRow(
            item: DashboardViewModel.ChallengeItem(
                challenge: Challenge(
                    title: "Read 20 pages",
                    detail: "Keep up with the reading habit",
                    startDate: Date(),
                    emoji: "📚",
                    trackingStyle: .trackTime,
                    dailyTargetMinutes: 30
                ),
                detail: ChallengeDetail(
                    challengeId: UUID(),
                    isCompleted: false,
                    loggedMinutes: 15,
                    notes: "Felt productive today",
                    photoURLs: []
                )
            ),
            isExpanded: true,
            onToggleExpansion: {},
            onToggleStatus: {},
            onEditTapped: {},
            onLogMinutes: { _ in },
            onSetLoggedMinutes: { _ in }
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
