import SwiftUI

struct LoadingStateView: View {
    let text: String

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text(text)
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
