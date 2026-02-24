import XCTest
@testable import Count_with_Kids

final class DashboardAggregatorTests: XCTestCase {

    // MARK: - Empty Data

    func testEmptySessionsReturnsEmpty() {
        let result = DashboardAggregator.aggregate(sessions: [], difficultyKey: "20_+_5", timeFrame: .day)
        XCTAssertEqual(result.totalSessions, 0)
        XCTAssertEqual(result.averageErrors, 0)
        XCTAssertEqual(result.averageTime, 0)
        XCTAssertEqual(result.cleanSheetCount, 0)
    }

    func testMismatchedDifficultyKeyReturnsEmpty() {
        let sessions = [PracticeSession.makeTest(errors: 1)]
        let result = DashboardAggregator.aggregate(sessions: sessions, difficultyKey: "100_+-_10", timeFrame: .day)
        XCTAssertEqual(result.totalSessions, 0)
    }

    // MARK: - Aggregation

    func testAverageErrorsCalculation() {
        let sessions = [
            PracticeSession.makeTest(errors: 2),
            PracticeSession.makeTest(errors: 4),
            PracticeSession.makeTest(errors: 0)
        ]
        let result = DashboardAggregator.aggregate(sessions: sessions, difficultyKey: "20_+_5", timeFrame: .day)
        XCTAssertEqual(result.totalSessions, 3)
        XCTAssertEqual(result.averageErrors, 2.0, accuracy: 0.01)
    }

    func testAverageTimeCalculation() {
        let sessions = [
            PracticeSession.makeTest(duration: 20.0),
            PracticeSession.makeTest(duration: 40.0)
        ]
        let result = DashboardAggregator.aggregate(sessions: sessions, difficultyKey: "20_+_5", timeFrame: .day)
        XCTAssertEqual(result.averageTime, 30.0, accuracy: 0.01)
    }

    func testCleanSheetCount() {
        let sessions = [
            PracticeSession.makeTest(errors: 0),
            PracticeSession.makeTest(errors: 0),
            PracticeSession.makeTest(errors: 3)
        ]
        let result = DashboardAggregator.aggregate(sessions: sessions, difficultyKey: "20_+_5", timeFrame: .day)
        XCTAssertEqual(result.cleanSheetCount, 2)
    }

    // MARK: - Time Frame Filtering

    func testDayTimeFrameExcludesYesterday() {
        let sessions = [
            PracticeSession.makeTest(daysAgo: 0, errors: 1),
            PracticeSession.makeTest(daysAgo: 2, errors: 5)
        ]
        let result = DashboardAggregator.aggregate(sessions: sessions, difficultyKey: "20_+_5", timeFrame: .day)
        XCTAssertEqual(result.totalSessions, 1)
        XCTAssertEqual(result.averageErrors, 1.0, accuracy: 0.01)
    }

    func testWeekTimeFrameIncludes6DaysAgo() {
        let sessions = [
            PracticeSession.makeTest(daysAgo: 0, errors: 1),
            PracticeSession.makeTest(daysAgo: 6, errors: 3)
        ]
        let result = DashboardAggregator.aggregate(sessions: sessions, difficultyKey: "20_+_5", timeFrame: .week)
        XCTAssertEqual(result.totalSessions, 2)
    }

    // MARK: - Bucketing

    func testDayBucketsProduces6Buckets() {
        let sessions = [PracticeSession.makeTest()]
        let result = DashboardAggregator.aggregate(sessions: sessions, difficultyKey: "20_+_5", timeFrame: .day)
        XCTAssertEqual(result.errorChartData.count, 6)
        XCTAssertEqual(result.timeChartData.count, 6)
        XCTAssertEqual(result.cleanSheetChartData.count, 6)
    }

    func testWeekBucketsProduces7Buckets() {
        let sessions = [PracticeSession.makeTest()]
        let result = DashboardAggregator.aggregate(sessions: sessions, difficultyKey: "20_+_5", timeFrame: .week)
        XCTAssertEqual(result.errorChartData.count, 7)
    }

    func testMonthBucketsProduces4Buckets() {
        let sessions = [PracticeSession.makeTest()]
        let result = DashboardAggregator.aggregate(sessions: sessions, difficultyKey: "20_+_5", timeFrame: .month)
        XCTAssertEqual(result.errorChartData.count, 4)
    }

    func testYearBucketsProduces12Buckets() {
        let sessions = [PracticeSession.makeTest()]
        let result = DashboardAggregator.aggregate(sessions: sessions, difficultyKey: "20_+_5", timeFrame: .year)
        XCTAssertEqual(result.errorChartData.count, 12)
    }

    // MARK: - Difficulty Keys

    func testAvailableDifficultyKeys() {
        let sessions = [
            PracticeSession.makeTest(difficultyKey: "20_+_5"),
            PracticeSession.makeTest(difficultyKey: "100_+-_10"),
            PracticeSession.makeTest(difficultyKey: "20_+_5")
        ]
        let keys = DashboardAggregator.availableDifficultyKeys(from: sessions)
        XCTAssertEqual(keys.count, 2)
        XCTAssertTrue(keys.contains("20_+_5"))
        XCTAssertTrue(keys.contains("100_+-_10"))
    }

    func testDisplayName() {
        XCTAssertEqual(DashboardAggregator.displayName(for: "20_+_5"), "To 20, +, 5/page")
        XCTAssertEqual(DashboardAggregator.displayName(for: "100_+-_10"), "To 100, + -, 10/page")
    }

    func testDisplayNameInvalidKey() {
        XCTAssertEqual(DashboardAggregator.displayName(for: "invalid"), "invalid")
    }
}
