import Charts
import SwiftUI

struct InsightsView: View {
    @StateObject private var viewModel: InsightsViewModel

    init(viewModel: InsightsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingStateView(text: "Loading insights...")
            } else if let error = viewModel.errorMessage {
                ErrorStateView(message: error, retryAction: { Task { await viewModel.load() } })
            } else if viewModel.dataPoints.isEmpty {
                EmptyStateView(title: "No data", message: "Log entries to view insights.")
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        focusChart
                        exerciseChart
                        moodChart
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle("Insights")
            }
        }
        .task { await viewModel.load() }
    }

    private var focusChart: some View {
        Chart(viewModel.dataPoints) { point in
            LineMark(
                x: .value("Date", point.date, unit: .day),
                y: .value("Focus", point.focusHours)
            )
            PointMark(
                x: .value("Date", point.date, unit: .day),
                y: .value("Focus", point.focusHours)
            )
        }
        .frame(height: 200)
        .chartXScale(range: .plotDimension(padding: 12))
        .chartYAxisLabel("Hours")
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(alignment: .topLeading) {
            Text("Focus Hours")
                .font(.headline)
                .padding()
        }
    }

    private var exerciseChart: some View {
        Chart(viewModel.dataPoints) { point in
            BarMark(
                x: .value("Date", point.date, unit: .day),
                y: .value("Exercise", point.exerciseMinutes)
            )
        }
        .frame(height: 200)
        .chartYAxisLabel("Minutes")
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(alignment: .topLeading) {
            Text("Exercise Minutes")
                .font(.headline)
                .padding()
        }
    }

    private var moodChart: some View {
        Chart(viewModel.dataPoints) { point in
            AreaMark(
                x: .value("Date", point.date, unit: .day),
                y: .value("Mood", point.moodScore)
            )
        }
        .frame(height: 200)
        .chartYAxisLabel("Mood Score")
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(alignment: .topLeading) {
            Text("Mood Trend")
                .font(.headline)
                .padding()
        }
    }
}
