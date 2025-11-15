import SwiftUI

struct ProgressSummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(value)
                    .font(.title3.bold())
            }
            ProgressView(value: progress)
                .progressViewStyle(.linear)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
