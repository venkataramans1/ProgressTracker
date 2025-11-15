import SwiftUI

struct ErrorStateView: View {
    let message: String
    let retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(.orange)
            Text(message)
                .font(.callout)
                .multilineTextAlignment(.center)
            if let retryAction {
                Button("Retry", action: retryAction)
            }
        }
        .padding()
    }
}
