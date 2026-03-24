import SwiftUI
import SwiftData

struct TrophyShelfView: View {
    @Environment(\.appTheme) var theme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query(sort: \PracticeSession.completedAt, order: .reverse) private var sessions: [PracticeSession]

    private var streak: StreakResult {
        StreakCalculator.compute(sessions: sessions)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundColor.ignoresSafeArea()

                if sessions.isEmpty {
                    emptyStateView
                } else {
                    shelfContent
                }
            }
            .navigationTitle(loc("Trophies"))
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Text(theme.mascotEmoji)
                .font(.system(size: 60))
            Text(loc("No trophies yet"))
                .playfulFont(size: 20)
                .foregroundColor(.secondary)
            Text(loc("Get 5 clean sheets in a row for your first silver medal!"))
                .playfulFont(size: 14, weight: .regular)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var shelfContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Streak stats
                HStack(spacing: 16) {
                    streakCard(
                        title: loc("Best Streak"),
                        value: "\(streak.maxStreak)",
                        icon: "flame.fill",
                        color: theme.secondaryColor
                    )
                    streakCard(
                        title: loc("Current Streak"),
                        value: "\(streak.currentStreak)",
                        icon: "bolt.fill",
                        color: theme.primaryColor
                    )
                }
                .padding(.horizontal)

                // Cup shelf
                CupShelfView(goldCups: streak.totalGoldCups, silverCups: streak.totalSilverCups)
                    .padding(.horizontal)

                // Next milestone
                nextMilestoneView
                    .padding(.horizontal)

                // Lion unlock progress
                lionProgressView
                    .padding(.horizontal)
            }
            .padding(.vertical)
            .frame(maxWidth: horizontalSizeClass == .regular ? 600 : .infinity)
            .frame(maxWidth: .infinity)
        }
    }

    private func streakCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .playfulFont(size: 32)
                .foregroundColor(.primary)
            Text(title)
                .playfulFont(size: 14, weight: .medium)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.cardBackgroundColor)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }

    @ViewBuilder
    private var nextMilestoneView: some View {
        if streak.currentStreak > 0 {
            let toSilver = streak.cleanSheetsToNextSilver
            let toGold = streak.cleanSheetsToNextGold

            VStack(spacing: 8) {
                if toGold <= toSilver {
                    let key = streak.totalGoldCups > 0 ? "%d more for another gold cup!" : "%d more for a gold cup!"
                    HStack(spacing: 8) {
                        Text("🏆").font(.title2)
                        Text(String(format: loc(key), toGold))
                            .playfulFont(size: 16, weight: .medium)
                            .foregroundColor(.primary)
                    }
                } else {
                    let key = streak.totalSilverCups > 0 ? "%d more for another silver medal!" : "%d more for a silver medal!"
                    HStack(spacing: 8) {
                        Text("🥈").font(.title2)
                        Text(String(format: loc(key), toSilver))
                            .playfulFont(size: 16, weight: .medium)
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.accentColor.opacity(0.15))
            )
        } else if !sessions.isEmpty {
            HStack(spacing: 8) {
                Text("💪")
                    .font(.title2)
                Text(loc("Start a clean sheet streak!"))
                    .playfulFont(size: 16, weight: .medium)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.cardBackgroundColor)
            )
        }
    }

    @ViewBuilder
    private var lionProgressView: some View {
        if streak.lionUnlocked {
            HStack(spacing: 12) {
                Text("🦁")
                    .font(.system(size: 40))
                VStack(alignment: .leading, spacing: 4) {
                    Text(loc("Lion unlocked!"))
                        .playfulFont(size: 18)
                        .foregroundColor(theme.accentColor)
                    Text(loc("Go to Settings to select the Lion theme"))
                        .playfulFont(size: 13, weight: .regular)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(theme.accentColor)
                    .font(.title2)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.cardBackgroundColor)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
        } else {
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Text("🦁")
                        .font(.title)
                    Text(loc("Lion theme"))
                        .playfulFont(size: 18)
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(streak.totalGoldCups) / 5 🏆")
                        .playfulFont(size: 16, weight: .medium)
                        .foregroundColor(.secondary)
                }

                ProgressView(value: Double(min(streak.totalGoldCups, 5)), total: 5)
                    .tint(theme.accentColor)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.cardBackgroundColor)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
        }
    }
}
