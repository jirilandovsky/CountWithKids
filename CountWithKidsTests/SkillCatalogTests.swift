import XCTest
@testable import Count_with_Kids

final class SkillCatalogTests: XCTestCase {

    func testCatalogIsNonEmpty() {
        let all = SkillCatalog.allSkills
        XCTAssertFalse(all.isEmpty)
        // First skill must be the absolute beginner anchor — real addition,
        // not "n + 0" counting.
        XCTAssertEqual(all.first?.id, "add_within_10")
        // Every grade has at least one skill (placement anchor existence).
        for grade in CzechGrade.allCases {
            XCTAssertFalse(SkillCatalog.skills(in: grade).isEmpty, "no skills in \(grade.displayName)")
        }
    }

    func testNoSkillEverGeneratesPlusZero() {
        // count_to_10 / count_to_20 used to generate `n + 0` problems which
        // are degenerate as practice. Guard against the regression: every
        // skill in the catalog must produce non-trivial problems.
        for skill in SkillCatalog.allSkills {
            for _ in 0..<30 {
                let p = skill.generate()
                if p.operation == .add {
                    XCTAssertGreaterThan(p.operand1, 0, "\(skill.id) generated 0 + n")
                    XCTAssertGreaterThan(p.operand2, 0, "\(skill.id) generated n + 0")
                }
                if p.operation == .subtract {
                    XCTAssertGreaterThan(p.operand1, 0, "\(skill.id) subtraction has 0 minuend")
                    XCTAssertGreaterThan(p.operand2, 0, "\(skill.id) subtraction has 0 subtrahend (n − 0)")
                }
            }
        }
    }

    func testPrerequisiteOrderingIsAcyclic() {
        // Walk the catalog: by the time we reach skill X, every prereq must
        // already have been seen. This guarantees the dependency graph has no
        // cycles even when grade order isn't strictly monotonic in the array.
        var seen = Set<String>()
        for skill in SkillCatalog.allSkills {
            for prereq in skill.prerequisites {
                XCTAssertTrue(seen.contains(prereq), "\(skill.id) lists prereq \(prereq) that comes later in the catalog")
            }
            seen.insert(skill.id)
        }
    }

    func testEverySkillReachableViaPrerequisites() {
        let allIDs = Set(SkillCatalog.allSkills.map(\.id))
        for skill in SkillCatalog.allSkills {
            for prereq in skill.prerequisites {
                XCTAssertTrue(allIDs.contains(prereq), "\(skill.id) lists missing prereq \(prereq)")
            }
        }
    }

    func testAnchorByAge() {
        XCTAssertEqual(SkillCatalog.anchorSkill(age: 5, grade: nil).grade, .grade1)
        XCTAssertEqual(SkillCatalog.anchorSkill(age: 6, grade: nil).grade, .grade1)
        XCTAssertEqual(SkillCatalog.anchorSkill(age: 7, grade: nil).grade, .grade2)
        XCTAssertEqual(SkillCatalog.anchorSkill(age: 8, grade: nil).grade, .grade3)
        XCTAssertEqual(SkillCatalog.anchorSkill(age: 10, grade: nil).grade, .grade5)
    }

    func testExplicitGradeOverridesAge() {
        // 5yo with declared 1.tř → grade 1 anchor.
        XCTAssertEqual(SkillCatalog.anchorSkill(age: 5, grade: .grade1).grade, .grade1)
        // 6yo whose parent says they're already in 2.tř.
        XCTAssertEqual(SkillCatalog.anchorSkill(age: 6, grade: .grade2).grade, .grade2)
    }

    func testNeighborWalksCatalog() {
        let first = SkillCatalog.allSkills[0].id
        let second = SkillCatalog.allSkills[1].id
        XCTAssertEqual(SkillCatalog.neighbor(of: first, offset: 1)?.id, second)
        XCTAssertEqual(SkillCatalog.neighbor(of: second, offset: -1)?.id, first)
        // Clamping at the start.
        XCTAssertEqual(SkillCatalog.neighbor(of: first, offset: -5)?.id, first)
    }

    // MARK: - Per-skill problem generation

    func testEverySkillProducesValidProblems() {
        for skill in SkillCatalog.allSkills {
            for _ in 0..<10 {
                let p = skill.generate()
                let computed: Int
                switch p.operation {
                case .add:      computed = p.operand1 + p.operand2
                case .subtract: computed = p.operand1 - p.operand2
                case .multiply: computed = p.operand1 * p.operand2
                case .divide:
                    XCTAssertGreaterThan(p.operand2, 0, "division by zero in \(skill.id)")
                    computed = p.operand1 / p.operand2
                }
                XCTAssertEqual(p.correctAnswer, computed, "wrong answer in \(skill.id): \(p.operand1) \(p.operation.symbol) \(p.operand2) = \(p.correctAnswer)")
            }
        }
    }

    func testAddWithin10StaysWithin10() {
        guard let s = SkillCatalog.skill("add_within_10") else { return XCTFail() }
        for _ in 0..<30 {
            let p = s.generate()
            XCTAssertLessThanOrEqual(p.correctAnswer, 10)
        }
    }

    func testTimesTablesProduceExpectedFactor() {
        for n in [2, 3, 4, 5, 6, 7, 8, 9, 10] {
            guard let s = SkillCatalog.skill("times_\(n)") else { return XCTFail("times_\(n)") }
            for _ in 0..<10 {
                let p = s.generate()
                XCTAssertTrue(p.operand1 == n || p.operand2 == n, "table \(n) didn't include \(n): \(p.operand1)×\(p.operand2)")
            }
        }
    }

    func testDivideExactSkillsHaveNoRemainder() {
        for n in [2, 3, 4, 5, 6, 7, 8, 9, 10] {
            guard let s = SkillCatalog.skill("divide_by_\(n)") else { return XCTFail("divide_by_\(n)") }
            for _ in 0..<10 {
                let p = s.generate()
                XCTAssertEqual(p.operand1 % p.operand2, 0, "divide_by_\(n) had remainder")
            }
        }
    }

    func testDivideWithRemainderActuallyHasRemainder() {
        for id in ["divide_with_remainder_within_100", "divide_with_remainder_within_1000"] {
            guard let s = SkillCatalog.skill(id) else { return XCTFail(id) }
            var withRemainder = 0
            for _ in 0..<20 {
                let p = s.generate()
                if p.operand1 % p.operand2 != 0 { withRemainder += 1 }
            }
            XCTAssertGreaterThan(withRemainder, 0, "\(id) produced no remainders")
        }
    }
}
