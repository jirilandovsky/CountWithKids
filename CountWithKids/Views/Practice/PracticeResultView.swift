import SwiftUI

struct PracticeResultView: View {
    @Environment(\.appTheme) var theme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let viewModel: PracticeViewModel
    let settings: AppSettings
    let streak: StreakResult
    let onSaveAndRestart: () -> Void
    let onSaveAndFinish: () -> Void

    private var isCleanSheet: Bool { viewModel.errorCount == 0 }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Mascot / Celebration
            Text(isCleanSheet ? theme.celebrationEmoji : theme.mascotEmoji)
                .font(.system(size: 80))

            if isCleanSheet {
                Text(loc("Clean Sheet!"))
                    .playfulFont(.title)
                    .foregroundColor(theme.accentColor)
            }

            if viewModel.showDeadlineExpired {
                Text(loc("Time's up!"))
                    .playfulFont(.title2)
                    .foregroundColor(theme.secondaryColor)
            }

            // Stats
            VStack(spacing: 16) {
                resultRow(
                    icon: "clock",
                    label: loc("Time"),
                    value: viewModel.timeString
                )

                resultRow(
                    icon: "xmark.circle",
                    label: loc("Errors"),
                    value: "\(viewModel.errorCount) / \(viewModel.problems.count)"
                )

                if !isCleanSheet {
                    resultRow(
                        icon: "arrow.counterclockwise",
                        label: loc("Correct"),
                        value: "\(viewModel.problems.count - viewModel.errorCount) / \(viewModel.problems.count)"
                    )
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.cardBackgroundColor)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .padding(.horizontal)

            if isCleanSheet {
                StreakBannerView(streak: streak)
                    .padding(.horizontal)
            }

            Spacer()

            // Action buttons
            VStack(spacing: 12) {
                Button(loc("Try Again")) {
                    onSaveAndRestart()
                }
                .buttonStyle(PlayfulButtonStyle())

                Button(loc("Done")) {
                    onSaveAndFinish()
                }
                .buttonStyle(PlayfulButtonStyle(color: theme.secondaryColor))
            }
            .padding(.bottom, 32)
        }
        .padding()
        .frame(maxWidth: horizontalSizeClass == .regular ? 600 : .infinity)
        .frame(maxWidth: .infinity)
    }

    private func resultRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(theme.primaryColor)
                .frame(width: 30)

            Text(label)
                .playfulFont(.headline, weight: .medium)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .playfulFont(.title3)
                .foregroundColor(.primary)
                .monospacedDigit()
        }
    }
}
