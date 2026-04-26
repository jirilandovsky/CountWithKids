import Foundation

struct StreakResult {
    let currentStreak: Int
    let maxStreak: Int
    let totalGoldCups: Int
    let totalSilverCups: Int

    var lionUnlocked: Bool { totalGoldCups >= 5 }
    var emojiThemeUnlocked: Bool { totalGoldCups >= 15 }

    var cleanSheetsToNextSilver: Int {
        let nextFive = ((currentStreak / 5) + 1) * 5
        return nextFive - currentStreak
    }

    var cleanSheetsToNextGold: Int {
        let nextTen = ((currentStreak / 10) + 1) * 10
        return nextTen - currentStreak
    }
}

struct StreakCalculator {

    /// Compute streak results from sessions sorted by completedAt descending (most recent first).
    /// `challengeWins` adds 1 gold cup per 10 mascot victories on top of clean-sheet cups.
    static func compute(sessions: [PracticeSession], challengeWins: Int = 0) -> StreakResult {
        let challengeGold = max(0, challengeWins) / 10

        guard !sessions.isEmpty else {
            return StreakResult(currentStreak: 0, maxStreak: 0, totalGoldCups: challengeGold, totalSilverCups: 0)
        }

        var currentStreak = 0
        for session in sessions {
            if session.isCleanSheet {
                currentStreak += 1
            } else {
                break
            }
        }

        let chronological = sessions.reversed()
        var maxStreak = 0
        var runLength = 0
        var totalGold = 0
        var totalSilver = 0

        for session in chronological {
            if session.isCleanSheet {
                runLength += 1
            } else {
                if runLength > 0 {
                    maxStreak = max(maxStreak, runLength)
                    totalGold += runLength / 10
                    totalSilver += (runLength / 5) - (runLength / 10)
                    runLength = 0
                }
            }
        }
        if runLength > 0 {
            maxStreak = max(maxStreak, runLength)
            totalGold += runLength / 10
            totalSilver += (runLength / 5) - (runLength / 10)
        }

        return StreakResult(
            currentStreak: currentStreak,
            maxStreak: maxStreak,
            totalGoldCups: totalGold + challengeGold,
            totalSilverCups: totalSilver
        )
    }
}
