import Foundation
@testable import Count_with_Kids

extension PracticeSession {
    /// Creates a PracticeSession for testing without SwiftData context
    static func makeTest(
        daysAgo: Int = 0,
        hoursAgo: Double = 0,
        errors: Int = 0,
        total: Int = 5,
        duration: Double = 30.0,
        difficultyKey: String = "20_+_5"
    ) -> PracticeSession {
        let session = PracticeSession()
        session.completedAt = Date().addingTimeInterval(-Double(daysAgo) * 86400 - hoursAgo * 3600)
        session.errorCount = errors
        session.totalProblems = total
        session.durationSeconds = duration
        session.isCleanSheet = errors == 0
        session.difficultyKey = difficultyKey
        session.countingRange = 20
        session.operationsRaw = ["+"]
        session.examplesPerPage = 5
        return session
    }
}
