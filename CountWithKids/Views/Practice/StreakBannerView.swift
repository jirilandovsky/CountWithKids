import SwiftUI

struct StreakBannerView: View {
    @Environment(\.appTheme) var theme
    let streak: StreakResult

    var body: some View {
        if streak.currentStreak > 0 {
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .font(.footnote)
                        .foregroundColor(theme.accentColor)
                    Text(loc("Clean sheets in a row:") + " \(streak.currentStreak)")
                        .playfulFont(.footnote, weight: .medium)
                        .foregroundColor(.primary)
                }

                milestoneHint
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(14)
            .clayCard(cornerRadius: 20, elevation: .resting, fill: theme.accentColor.opacity(0.10))
        }
    }

    @ViewBuilder
    private var milestoneHint: some View {
        let toSilver = streak.cleanSheetsToNextSilver
        let toGold = streak.cleanSheetsToNextGold

        if toGold <= toSilver {
            let key = streak.totalGoldCups > 0 ? "%d more for another gold cup!" : "%d more for a gold cup!"
            Text(String(format: loc(key), toGold) + " 🏆")
                .playfulFont(.caption2, weight: .regular)
                .foregroundColor(.secondary)
        } else {
            let key = streak.totalSilverCups > 0 ? "%d more for another silver medal!" : "%d more for a silver medal!"
            Text(String(format: loc(key), toSilver) + " 🥈")
                .playfulFont(.caption2, weight: .regular)
                .foregroundColor(.secondary)
        }
    }
}
