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
                        if let summary = viewModel.summary {
                            ResilienceSummaryCard(summary: summary)
                            MetricHighlightsGrid(summary: summary)
                        }
                        if !viewModel.nudges.isEmpty {
                            NudgesListView(nudges: viewModel.nudges)
                        }
                        if !viewModel.challengeInsights.isEmpty {
                            ChallengeInsightsList(insights: viewModel.challengeInsights)
                        }
                        focusChart
                        moodChart
                        completionChart
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle("Insights")
            }
        }
        .task { await viewModel.load() }
        .onAppear { Task { await viewModel.load() } }
        .refreshable { await viewModel.load() }
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

    private var completionChart: some View {
        Chart(viewModel.dataPoints) { point in
            LineMark(
                x: .value("Date", point.date, unit: .day),
                y: .value("Completion", point.completionRate * 100)
            )
            .symbol(.circle)
        }
        .frame(height: 200)
        .chartYAxisLabel("% Complete")
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(alignment: .topLeading) {
            Text("Objective Completion")
                .font(.headline)
                .padding()
        }
    }
}

private struct ResilienceSummaryCard: View {
    let summary: ResilienceSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Resilience Score")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(trendText)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
                Text(Int(summary.resilienceScore).formatted())
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
            }
            ProgressView(value: summary.resilienceScore / 100)
                .tint(.white)
            Text(statusMessage)
                .font(.footnote)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding()
        .background(LinearGradient(colors: [Color.blue, Color.indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var trendText: String {
        switch summary.trend {
        case .improving: return "Trend: Improving"
        case .steady: return "Trend: Steady"
        case .declining: return "Trend: Declining"
        }
    }

    private var statusMessage: String {
        switch summary.resilienceScore {
        case ..<50: return "Energy dipping—reclaim today with small wins."
        case 50..<80: return "Solid momentum. Keep stacking consistent habits."
        default: return "Thriving! Consider mentoring or sharing progress."
        }
    }
}

private struct MetricHighlightsGrid: View {
    let summary: ResilienceSummary

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            MetricTile(
                title: "Avg Mood",
                valueText: (summary.averageMood / 5).formatted(.percent.precision(.fractionLength(0))),
                footer: nil
            )
            MetricTile(
                title: "Focus hrs",
                valueText: summary.averageFocusHours.formatted(.number.precision(.fractionLength(1))),
                footer: "per day"
            )
            MetricTile(
                title: "Completion",
                valueText: summary.completionRate.formatted(.percent.precision(.fractionLength(0))),
                footer: nil
            )
            MetricTile(
                title: "Active challenges",
                valueText: summary.activeChallenges.formatted(),
                footer: nil
            )
            MetricTile(
                title: "Streak",
                valueText: summary.currentStreak.formatted(),
                footer: "days"
            )
        }
    }

    private struct MetricTile: View {
        let title: String
        let valueText: String
        let footer: String?

        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(valueText)
                    .font(.headline)
                if let footer {
                    Text(footer)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

private struct NudgesListView: View {
    let nudges: [ResilienceNudge]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Suggested actions")
                .font(.headline)
            ForEach(nudges) { nudge in
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: nudge.kind.iconName)
                        .foregroundColor(nudge.kind.tint)
                        .frame(width: 32, height: 32)
                        .background(nudge.kind.tint.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(nudge.title)
                            .font(.subheadline.weight(.semibold))
                        Text(nudge.detail)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }
}

private extension ResilienceNudge.Kind {
    var iconName: String {
        switch self {
        case .mindfulness: return "leaf"
        case .focus: return "target"
        case .movement: return "figure.walk"
        case .celebration: return "sparkles"
        }
    }

    var tint: Color {
        switch self {
        case .mindfulness: return .mint
        case .focus: return .orange
        case .movement: return .blue
        case .celebration: return .purple
        }
    }
}

private struct ChallengeInsightsList: View {
    let insights: [ChallengeInsight]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Challenge insights")
                .font(.headline)
            ForEach(insights.prefix(3)) { insight in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(insight.title)
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(insight.completionRate.formatted(.percent.precision(.fractionLength(0))))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    ProgressView(value: insight.completionRate)
                        .tint(.accentColor)
                    HStack(spacing: 12) {
                        Label("\(insight.checkIns) check-ins", systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let last = insight.lastUpdated {
                            Text(last, style: .relative)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }
}
