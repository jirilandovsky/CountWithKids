import SwiftUI
import SwiftData
import Charts

// In-app card opened from the Sunday 19:00 notification or the Guided home.
// Three Czech sentences + 1 chart of weekly clean sheets per operation.
struct WeeklyReportView: View {
    @Environment(\.appTheme) var theme
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \PracticeSession.completedAt, order: .reverse) private var sessions: [PracticeSession]
    @Query private var progressRows: [MasteryProgress]

    private var summary: WeeklyReportService.Summary {
        WeeklyReportService.summary(sessions: sessions, progress: progressRows)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("📬")
                    .font(.system(size: 60))
                    .padding(.top, 24)

                Text(loc("Weekly report"))
                    .playfulFont(.title2, weight: .bold)
                    .foregroundColor(theme.primaryColor)

                summaryText
                    .padding(.horizontal, 24)

                chart
                    .frame(height: 220)
                    .padding(.horizontal)

                Spacer()

                Button(loc("Close")) { dismiss() }
                    .buttonStyle(PlayfulButtonStyle())
                    .padding(.horizontal, 40)
                    .padding(.bottom, 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.backgroundColor.ignoresSafeArea())
        }
        .task {
            // Deferred to first open of this sheet — prompting at session
            // completion interrupted active gameplay (kid mid-Check-All).
            await WeeklyReportService.requestNotificationPermissionIfNeeded()
        }
    }

    @ViewBuilder
    private var summaryText: some View {
        VStack(spacing: 10) {
            Text(String(format: loc("This week %d clean sheets."), summary.totalCleanSheets))
                .playfulFont(.body, weight: .medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            if let strongest = summary.strongestOperation {
                Text(loc("Most improved in") + " \(strongest.symbol).")
                    .playfulFont(.body, weight: .medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }

            if let next = summary.nextFocusOperation {
                Text(loc("Now working on") + " \(next.symbol).")
                    .playfulFont(.body, weight: .medium)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var chart: some View {
        Chart(summary.stats, id: \.operation) { stat in
            BarMark(
                x: .value("Operation", stat.operation.symbol),
                y: .value("Clean sheets", stat.cleanSheets)
            )
            .foregroundStyle(theme.primaryColor)
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }
}
