import XCTest
@testable import Count_with_Kids

final class DailyPlanBuilderTests: XCTestCase {

    private func skill(_ id: String) -> Skill { SkillCatalog.skill(id)! }

    // MARK: - Empty mastery

    func testFreshKidAtFloorClampsAndPreviewsAhead() {
        // No mastered skills, active is the very first skill (add_within_10).
        // Warmup clamps to active (catalog floor); Challenge previews next.
        let active = skill("add_within_10")
        let plan = DailyPlanBuilder.build(activeSkill: active, masteredSkillIDs: [])
        XCTAssertEqual(plan.warmup.skillIDs, ["add_within_10"])
        XCTAssertEqual(plan.focus.skillIDs, ["add_within_10"])
        XCTAssertEqual(plan.challenge.skillIDs, ["sub_within_10"], "challenge should preview the next skill")
    }

    func testFreshKidMidLadderHasDistinctSlots() {
        // 6yo placed at "+ within 20 (no carrying)" with nothing mastered yet.
        // Warmup goes one step back, Focus is active, Challenge is one step ahead.
        let active = skill("add_within_20_no_carry")
        let plan = DailyPlanBuilder.build(activeSkill: active, masteredSkillIDs: [])
        XCTAssertEqual(plan.warmup.skillIDs, ["sub_within_10"])
        XCTAssertEqual(plan.focus.skillIDs, ["add_within_20_no_carry"])
        XCTAssertEqual(plan.challenge.skillIDs, ["sub_within_20_no_borrow"])
        XCTAssertNotEqual(plan.warmup.skillIDs, plan.focus.skillIDs)
        XCTAssertNotEqual(plan.focus.skillIDs, plan.challenge.skillIDs)
    }

    // MARK: - With some mastery

    func testWarmupPicksMasteredSameOpSkill() {
        let active = skill("add_within_20_no_carry")
        let mastered: Set<String> = ["add_within_10", "sub_within_10"]
        let plan = DailyPlanBuilder.build(activeSkill: active, masteredSkillIDs: mastered)
        // Should prefer addition skill (same op) over the subtraction one.
        XCTAssertEqual(plan.warmup.skillIDs, ["add_within_10"])
        XCTAssertEqual(plan.focus.skillIDs, ["add_within_20_no_carry"])
    }

    func testChallengeMixesRecentMastered() {
        let active = skill("add_within_20_carry")
        let mastered: Set<String> = [
            "add_within_10", "sub_within_10",
            "add_within_20_no_carry", "sub_within_20_no_borrow"
        ]
        let plan = DailyPlanBuilder.build(activeSkill: active, masteredSkillIDs: mastered)
        XCTAssertEqual(plan.challenge.skillIDs.count, 4)
        // All challenge skills must come from the mastered set.
        for id in plan.challenge.skillIDs {
            XCTAssertTrue(mastered.contains(id))
        }
    }

    // MARK: - Composition invariants

    func testAllCardsHaveFiveProblems() {
        let active = skill("add_within_10")
        let plan = DailyPlanBuilder.build(activeSkill: active, masteredSkillIDs: [])
        XCTAssertEqual(plan.warmup.problemCount, 5)
        XCTAssertEqual(plan.focus.problemCount, 5)
        XCTAssertEqual(plan.challenge.problemCount, 5)
    }

    func testNoSubtractionInWarmupForBeginner() {
        // 6yo who just mastered count_to_10. Active = add_within_10.
        // Warmup should NOT pull subtraction or division skills.
        let active = skill("add_within_10")
        let mastered: Set<String> = ["add_within_10"]
        let plan = DailyPlanBuilder.build(activeSkill: active, masteredSkillIDs: mastered)
        for id in plan.warmup.skillIDs {
            let s = SkillCatalog.skill(id)!
            XCTAssertNotEqual(s.primaryOperation, .subtract, "warmup pulled subtraction for a kid who hasn't done it yet")
            XCTAssertNotEqual(s.primaryOperation, .divide)
            XCTAssertNotEqual(s.primaryOperation, .multiply)
        }
    }
}
