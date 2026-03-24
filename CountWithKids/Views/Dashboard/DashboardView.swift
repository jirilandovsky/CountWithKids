import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.appTheme) var theme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Bindable var settings: AppSettings
    @Query(sort: \PracticeSession.completedAt, order: .reverse) private var sessions: [PracticeSession]
    @State private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundColor.ignoresSafeArea()

                if sessions.isEmpty {
                    emptyStateView
                } else {
                    dashboardContent
                }
            }
            .navigationTitle(loc("Dashboard"))
            .navigationBarTitleDisplayMode(.large)
            .onAppear { viewModel.refresh(sessions: sessions, currentSettings: settings) }
            .onChange(of: viewModel.selectedDifficultyKey) { _, _ in
                viewModel.refresh(sessions: sessions, currentSettings: settings)
            }
            .onChange(of: viewModel.selectedTimeFrame) { _, _ in
                viewModel.refresh(sessions: sessions, currentSettings: settings)
            }
            .onChange(of: sessions.count) { _, _ in
                viewModel.refresh(sessions: sessions, currentSettings: settings)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Text(theme.mascotEmoji)
                .font(.system(size: 60))
            Text(loc("No practice sessions yet"))
                .playfulFont(size: 20)
                .foregroundColor(.secondary)
            Text(loc("Complete a practice page to see your stats!"))
                .playfulFont(size: 14, weight: .regular)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var dashboardContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Filters
                VStack(spacing: 8) {
                    if viewModel.availableKeys.count > 1 {
                        Picker(loc("Difficulty"), selection: $viewModel.selectedDifficultyKey) {
                            ForEach(viewModel.availableKeys, id: \.self) { key in
                                Text(DashboardAggregator.displayName(for: key))
                                    .tag(key)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    Picker(loc("Period"), selection: $viewModel.selectedTimeFrame) {
                        ForEach(TimeFrame.allCases) { tf in
                            Text(loc(tf.rawValue))
                                .tag(tf)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal)

                // Metric cards — grid on iPad, stack on iPhone
                if horizontalSizeClass == .regular {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        metricCards
                    }
                    .padding(.horizontal)
                } else {
                    VStack(spacing: 16) {
                        metricCards
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
            .frame(maxWidth: horizontalSizeClass == .regular ? 900 : .infinity)
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var metricCards: some View {
        MetricCardView(
            title: loc("Average Errors"),
            value: String(format: "%.1f", viewModel.metrics.averageErrors),
            subtitle: "\(viewModel.metrics.totalSessions) " + loc("sessions"),
            chartData: viewModel.metrics.errorChartData,
            chartColor: theme.secondaryColor,
            chartUnit: "Errors"
        )

        MetricCardView(
            title: loc("Average Time"),
            value: formatTime(viewModel.metrics.averageTime),
            subtitle: loc("seconds per page"),
            chartData: viewModel.metrics.timeChartData,
            chartColor: theme.primaryColor,
            chartUnit: "Seconds"
        )

        MetricCardView(
            title: loc("Clean Sheets"),
            value: "\(viewModel.metrics.cleanSheetCount)",
            subtitle: loc("pages with zero errors"),
            chartData: viewModel.metrics.cleanSheetChartData,
            chartColor: theme.accentColor,
            chartUnit: "Count"
        )
    }

    private func formatTime(_ seconds: Double) -> String {
        if seconds < 60 {
            return String(format: "%.0fs", seconds)
        }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return "\(mins)m \(secs)s"
    }
}
