import XCTest
import SwiftData
@testable import Count_with_Kids

final class CurriculumServiceTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUpWithError() throws {
        let schema = Schema([AppSettings.self, PracticeSession.self, MasteryProgress.self, SkillProgress.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }

    // MARK: - Recording results

    func testFiveCleanSheetsMastersASkill() {
        var outcome = CurriculumService.recordResult(skillID: "add_within_10", errorCount: 0, in: context)
        XCTAssertEqual(outcome, .progress)
        for _ in 0..<3 {
            outcome = CurriculumService.recordResult(skillID: "add_within_10", errorCount: 0, in: context)
            XCTAssertEqual(outcome, .progress)
        }
        outcome = CurriculumService.recordResult(skillID: "add_within_10", errorCount: 0, in: context)
        if case .mastered(let id, _) = outcome {
            XCTAssertEqual(id, "add_within_10")
        } else {
            XCTFail("Expected mastery, got \(outcome)")
        }
    }

    func testErrorResetsCounter() {
        for _ in 0..<3 {
            _ = CurriculumService.recordResult(skillID: "add_within_10", errorCount: 0, in: context)
        }
        let outcome = CurriculumService.recordResult(skillID: "add_within_10", errorCount: 1, in: context)
        XCTAssertEqual(outcome, .noChange)

        let row = CurriculumService.progress(for: "add_within_10", in: context)
        XCTAssertEqual(row.consecutiveCleanSheets, 0)
        XCTAssertFalse(row.isCompleted)
    }

    func testMasteringTwiceDoesntDoubleFire() {
        // First mastery.
        for _ in 0..<5 { _ = CurriculumService.recordResult(skillID: "add_within_10", errorCount: 0, in: context) }
        // Subsequent clean sheets at a mastered skill return .progress, not .mastered.
        let outcome = CurriculumService.recordResult(skillID: "add_within_10", errorCount: 0, in: context)
        XCTAssertEqual(outcome, .progress)
    }

    // MARK: - Active skill resolution

    func testFirstActiveSkillIsTheBeginnerAnchor() {
        let s = CurriculumService.nextActiveSkill(in: context)
        XCTAssertEqual(s.id, "add_within_10")
    }

    func testActiveSkillAdvancesAsPrereqsAreMastered() {
        // Master add_within_10 → next active is sub_within_10.
        for _ in 0..<5 { _ = CurriculumService.recordResult(skillID: "add_within_10", errorCount: 0, in: context) }
        XCTAssertEqual(CurriculumService.nextActiveSkill(in: context).id, "sub_within_10")

        // Master sub_within_10 → add_within_20_no_carry.
        for _ in 0..<5 { _ = CurriculumService.recordResult(skillID: "sub_within_10", errorCount: 0, in: context) }
        XCTAssertEqual(CurriculumService.nextActiveSkill(in: context).id, "add_within_20_no_carry")
    }

    func testCurrentActiveRepairsStaleSettings() {
        let s = AppSettings()
        context.insert(s)
        s.activeSkillID = "add_within_10"

        // Master add_within_10. settings.activeSkillID is now stale.
        for _ in 0..<5 { _ = CurriculumService.recordResult(skillID: "add_within_10", errorCount: 0, in: context) }
        let active = CurriculumService.currentActiveSkill(settings: s, in: context)
        XCTAssertEqual(active.id, "sub_within_10")
        XCTAssertEqual(s.activeSkillID, "sub_within_10")
    }

    // MARK: - Grade completion

    func testGradeCompletionRatio() {
        XCTAssertEqual(CurriculumService.gradeCompletionRatio(.grade1, in: context), 0)
        // Master one G1 skill.
        for _ in 0..<5 { _ = CurriculumService.recordResult(skillID: "add_within_10", errorCount: 0, in: context) }
        let r = CurriculumService.gradeCompletionRatio(.grade1, in: context)
        XCTAssertGreaterThan(r, 0)
        XCTAssertLessThan(r, 1)
    }

    func testFinishingLastSkillOfGradeFiresGradeCompleted() {
        // Brute-force master every G1 skill. Should fire on the final one.
        let g1 = SkillCatalog.skills(in: .grade1)
        for s in g1.dropLast() {
            for _ in 0..<5 { _ = CurriculumService.recordResult(skillID: s.id, errorCount: 0, in: context) }
        }
        var lastOutcome: CurriculumService.Outcome = .noChange
        for _ in 0..<5 {
            lastOutcome = CurriculumService.recordResult(skillID: g1.last!.id, errorCount: 0, in: context)
        }
        if case let .mastered(_, gradeCompleted) = lastOutcome {
            XCTAssertEqual(gradeCompleted, .grade1)
        } else {
            XCTFail("Expected grade completion, got \(lastOutcome)")
        }
    }
}
