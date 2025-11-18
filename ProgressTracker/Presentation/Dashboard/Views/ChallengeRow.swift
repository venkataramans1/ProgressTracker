import SwiftUI
import UIKit

struct ChallengeRow: View {
    let item: DashboardViewModel.ChallengeItem
    let isExpanded: Bool
    let onToggleExpansion: () -> Void
    let onToggleStatus: () -> Void
    let onEditTapped: () -> Void
    let onLogMinutes: (Int) -> Void

    @State private var customMinutesText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
                .contentShape(Rectangle())
                .onTapGesture(perform: onToggleExpansion)
            if isExpanded {
                Divider()
                expandedContent
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
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

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(item.emoji)
                    Text(item.title)
                        .font(.headline)
                }
                Text(item.trackingSummary)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(item.statusText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.down")
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
            Label("Track time", systemImage: "stopwatch")
                .font(.headline)
            Text(item.trackingSummary)
                .font(.subheadline)
                .foregroundColor(.secondary)
            HStack {
                ForEach([15, 30, 45], id: \.self) { minutes in
                    Button("+\(minutes)") {
                        onLogMinutes(minutes)
                    }
                    .buttonStyle(.bordered)
                }
            }
            HStack {
                TextField("Custom minutes", text: $customMinutesText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                Button("Add") {
                    submitCustomMinutes()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func submitCustomMinutes() {
        let value = Int(customMinutesText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        guard value > 0 else { return }
        onLogMinutes(value)
        customMinutesText = ""
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
            onLogMinutes: { _ in }
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
