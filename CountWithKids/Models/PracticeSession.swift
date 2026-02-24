import Foundation
import SwiftData

@Model
final class PracticeSession {
    var completedAt: Date = Date()
    var durationSeconds: Double = 0.0
    var errorCount: Int = 0
    var totalProblems: Int = 0
    var isCleanSheet: Bool = false
    var difficultyKey: String = ""
    var countingRange: Int = 20
    var operationsRaw: [String] = ["+"]
    var examplesPerPage: Int = 5

    init() {}

    init(duration: Double, errors: Int, total: Int, settings: AppSettings) {
        self.durationSeconds = duration
        self.errorCount = errors
        self.totalProblems = total
        self.isCleanSheet = errors == 0
        self.difficultyKey = settings.difficultyKey
        self.countingRange = settings.countingRange
        self.operationsRaw = settings.operationsRaw
        self.examplesPerPage = settings.examplesPerPage
        self.completedAt = Date()
    }
}
