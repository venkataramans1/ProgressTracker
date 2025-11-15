import SwiftUI

struct MoodSelectorView: View {
    @Binding var selectedMood: Mood

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Mood.allCases) { mood in
                    Button {
                        selectedMood = mood
                    } label: {
                        VStack {
                            Image(systemName: mood.systemImageName)
                                .font(.title2)
                            Text(mood.label)
                                .font(.caption)
                        }
                        .padding()
                        .frame(width: 90)
                        .background(selectedMood == mood ? Color.accentColor.opacity(0.2) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
}
