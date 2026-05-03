import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.appTheme) var theme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(StoreManager.self) private var store
    @Bindable var settings: AppSettings
    @Query(sort: \PracticeSession.completedAt, order: .reverse) private var sessions: [PracticeSession]
    @State private var viewModel = DashboardViewModel()
    @State private var showPaywall = false

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
            .sheet(isPresented: $showPaywall) {
                PaywallView(settings: settings, store: store, focus: .fullUnlockOnly)
                    .environment(\.appTheme, theme)
            }
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
                .playfulFont(.title3)
                .foregroundColor(.secondary)
            Text(loc("Complete a practice page to see your stats!"))
                .playfulFont(.footnote, weight: .regular)
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

                // Single soft upsell footer for non-paid users — replaces the
                // per-card harsh blur/lock previously used.
                if !settings.isUnlocked {
                    upsellFooter
                        .padding(.horizontal)
                        .padding(.top, 4)
                }
            }
            .padding(.vertical)
            .frame(maxWidth: horizontalSizeClass == .regular ? 900 : .infinity)
            .frame(maxWidth: .infinity)
        }
    }

    private var upsellFooter: some View {
        Button {
            showPaywall = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "lock.open.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                VStack(alignment: .leading, spacing: 2) {
                    Text(loc("See all stats"))
                        .playfulFont(.callout, weight: .bold)
                        .foregroundColor(.white)
                    Text(loc("Unlock the full version"))
                        .playfulFont(.caption, weight: .medium)
                        .foregroundColor(.white.opacity(0.85))
                }
                Spacer()
                Text(store.displayPrice)
                    .playfulFont(.callout, weight: .bold)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(theme.primaryColor)
                    .shadow(color: theme.primaryColor.opacity(0.30), radius: 10, x: 0, y: 6)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var metricCards: some View {
        lockedIfNeeded(
            MetricCardView(
                title: loc("Average Errors"),
                value: String(format: "%.1f", viewModel.metrics.averageErrors),
                subtitle: "\(viewModel.metrics.totalSessions) " + loc("sessions"),
                chartData: viewModel.metrics.errorChartData,
                chartColor: theme.secondaryColor,
                chartUnit: "Errors"
            )
        )

        MetricCardView(
            title: loc("Average Time"),
            value: formatTime(viewModel.metrics.averageTime),
            subtitle: loc("seconds per page"),
            chartData: viewModel.metrics.timeChartData,
            chartColor: theme.primaryColor,
            chartUnit: "Seconds"
        )

        lockedIfNeeded(
            MetricCardView(
                title: loc("Clean Sheets"),
                value: "\(viewModel.metrics.cleanSheetCount)",
                subtitle: loc("pages with zero errors"),
                chartData: viewModel.metrics.cleanSheetChartData,
                chartColor: theme.accentColor,
                chartUnit: "Count"
            )
        )
    }

    @ViewBuilder
    private func lockedIfNeeded<Content: View>(_ content: Content) -> some View {
        if settings.isUnlocked {
            content
        } else {
            content
                .opacity(0.55)
                .overlay(alignment: .topTrailing) {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 11, weight: .semibold))
                        Text(loc("Premium"))
                            .playfulFont(.caption2, weight: .bold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule().fill(theme.primaryColor)
                    )
                    .padding(10)
                }
                .contentShape(Rectangle())
                .onTapGesture { showPaywall = true }
                .accessibilityAddTraits(.isButton)
                .accessibilityHint(loc("Locked, tap to unlock full version"))
        }
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
