import Foundation
import SwiftUI

@Observable
class DashboardViewModel {
    var selectedDifficultyKey: String = ""
    var selectedTimeFrame: TimeFrame = .week
    var metrics: AggregatedMetrics = .empty
    var availableKeys: [String] = []

    func refresh(sessions: [PracticeSession], currentSettings: AppSettings) {
        availableKeys = DashboardAggregator.availableDifficultyKeys(from: sessions)

        if selectedDifficultyKey.isEmpty || !availableKeys.contains(selectedDifficultyKey) {
            selectedDifficultyKey = currentSettings.difficultyKey
        }

        if !availableKeys.contains(selectedDifficultyKey), let first = availableKeys.first {
            selectedDifficultyKey = first
        }

        metrics = DashboardAggregator.aggregate(
            sessions: sessions,
            difficultyKey: selectedDifficultyKey,
            timeFrame: selectedTimeFrame
        )
    }
}
