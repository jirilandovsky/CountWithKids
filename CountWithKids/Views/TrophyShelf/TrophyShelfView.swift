import SwiftUI
import SwiftData

struct TrophyShelfView: View {
    @Environment(\.appTheme) var theme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query(sort: \PracticeSession.completedAt, order: .reverse) private var sessions: [PracticeSession]
    @Query private var settingsArray: [AppSettings]
    var challengeWins: Int = 0

    private var isUnlocked: Bool {
        settingsArray.first?.isUnlocked ?? false
    }

    private var streak: StreakResult {
        StreakCalculator.compute(sessions: sessions, challengeWins: challengeWins)
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
                .playfulFont(.title3)
                .foregroundColor(.secondary)
            Text(loc("Get 5 clean sheets in a row for your first silver medal!"))
                .playfulFont(.footnote, weight: .regular)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var shelfContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Reward first — let the cups breathe at the top.
                CupShelfView(goldCups: streak.totalGoldCups, silverCups: streak.totalSilverCups)
                    .padding(.horizontal)

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

                // Challenge victories
                if challengeWins > 0 {
                    challengeVictoriesView
                        .padding(.horizontal)
                }

                // Lion unlock progress
                lionProgressView
                    .padding(.horizontal)

                // Emoji theme unlock progress (most ambitious goal — always visible)
                emojiThemeProgressView
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
                .playfulFont(.title)
                .foregroundColor(.primary)
            Text(title)
                .playfulFont(.footnote, weight: .medium)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .clayCard(cornerRadius: 22, elevation: .resting)
    }

    @ViewBuilder
    private var lionProgressView: some View {
        if streak.lionUnlocked {
            HStack(spacing: 12) {
                Text("🦁")
                    .font(.system(size: 40))
                VStack(alignment: .leading, spacing: 4) {
                    Text(loc("Lion unlocked!"))
                        .playfulFont(.headline)
                        .foregroundColor(theme.accentColor)
                    Text(isUnlocked
                         ? loc("Go to Settings to select the Lion theme")
                         : loc("Requires full version to equip"))
                        .playfulFont(.caption, weight: .regular)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: isUnlocked ? "checkmark.seal.fill" : "lock.fill")
                    .foregroundColor(isUnlocked ? theme.accentColor : .secondary)
                    .font(.title2)
            }
            .padding()
            .clayCard(cornerRadius: 22, elevation: .resting)
        } else {
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Text("🦁")
                        .font(.title)
                    Text(loc("Lion theme"))
                        .playfulFont(.headline)
                        .foregroundColor(.primary)
                    if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("\(streak.totalGoldCups) / 5 🏆")
                        .playfulFont(.callout, weight: .medium)
                        .foregroundColor(.secondary)
                }

                ProgressView(value: Double(min(streak.totalGoldCups, 5)), total: 5)
                    .tint(theme.accentColor)

                if !isUnlocked {
                    Text(loc("Requires full version to equip"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            .clayCard(cornerRadius: 22, elevation: .resting)
        }
    }

    @ViewBuilder
    private var emojiThemeProgressView: some View {
        if streak.lionUnlocked {
            if streak.emojiThemeUnlocked {
                HStack(spacing: 12) {
                    Text("🎨")
                        .font(.system(size: 40))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(loc("Emoji theme unlocked!"))
                            .playfulFont(.headline)
                            .foregroundColor(theme.accentColor)
                        Text(isUnlocked
                             ? loc("Go to Settings to select the Emoji theme")
                             : loc("Requires full version to equip"))
                            .playfulFont(.caption, weight: .regular)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(theme.accentColor)
                        .font(.title2)
                }
                .padding()
                .clayCard(cornerRadius: 22, elevation: .resting)
            } else {
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Text("🎨")
                            .font(.title)
                        Text(loc("Emoji theme"))
                            .playfulFont(.headline)
                            .foregroundColor(.primary)
                        if !isUnlocked {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("\(streak.totalGoldCups) / 15 🏆")
                            .playfulFont(.callout, weight: .medium)
                            .foregroundColor(.secondary)
                    }

                    ProgressView(value: Double(min(streak.totalGoldCups, 15)), total: 15)
                        .tint(theme.accentColor)

                    if !isUnlocked {
                        Text(loc("Requires full version to equip"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                .clayCard(cornerRadius: 22, elevation: .resting)
            }
        }
    }

    private var challengeVictoriesView: some View {
        let toNextCup = 10 - (challengeWins % 10)
        return HStack(spacing: 12) {
            Text("💪")
                .font(.system(size: 40))
            VStack(alignment: .leading, spacing: 4) {
                Text(loc("Mascot victories"))
                    .playfulFont(.headline)
                    .foregroundColor(theme.primaryColor)
                HStack(spacing: 6) {
                    Text("🏆")
                        .font(.system(size: 14))
                    Text(String(format: loc("%d more for a gold cup!"), toNextCup))
                        .playfulFont(.caption, weight: .regular)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Text("\(challengeWins)")
                .playfulFont(.title)
                .foregroundColor(theme.accentColor)
        }
        .padding()
        .clayCard(cornerRadius: 22, elevation: .resting)
    }
}
