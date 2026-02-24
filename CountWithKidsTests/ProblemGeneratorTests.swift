import XCTest
@testable import Count_with_Kids

final class ProblemGeneratorTests: XCTestCase {

    // MARK: - Generation Count

    func testGeneratesCorrectNumberOfProblems() {
        for count in [1, 5, 10] {
            let problems = ProblemGenerator.generate(count: count, range: 20, operations: [.add])
            XCTAssertEqual(problems.count, count)
        }
    }

    func testEmptyOperationsReturnsEmpty() {
        let problems = ProblemGenerator.generate(count: 5, range: 20, operations: [])
        XCTAssertTrue(problems.isEmpty)
    }

    // MARK: - Addition

    func testAdditionNeverExceedsRange() {
        for range in [10, 20, 100, 1000] {
            let problems = ProblemGenerator.generate(count: 100, range: range, operations: [.add])
            for p in problems {
                XCTAssertEqual(p.operation, .add)
                XCTAssertEqual(p.correctAnswer, p.operand1 + p.operand2)
                XCTAssertLessThanOrEqual(p.correctAnswer, range, "Addition result \(p.correctAnswer) exceeds range \(range)")
                XCTAssertGreaterThanOrEqual(p.operand1, 0)
                XCTAssertGreaterThanOrEqual(p.operand2, 0)
            }
        }
    }

    // MARK: - Subtraction

    func testSubtractionCorrectAnswer() {
        let problems = ProblemGenerator.generate(count: 100, range: 20, operations: [.subtract])
        for p in problems {
            XCTAssertEqual(p.operation, .subtract)
            XCTAssertEqual(p.correctAnswer, p.operand1 - p.operand2)
            XCTAssertGreaterThanOrEqual(p.operand1, 0)
            XCTAssertGreaterThanOrEqual(p.operand2, 0)
        }
    }

    // MARK: - Multiplication

    func testMultiplicationCorrectAnswer() {
        let problems = ProblemGenerator.generate(count: 100, range: 100, operations: [.multiply])
        for p in problems {
            XCTAssertEqual(p.operation, .multiply)
            XCTAssertEqual(p.correctAnswer, p.operand1 * p.operand2)
            XCTAssertGreaterThanOrEqual(p.operand1, 0)
            XCTAssertGreaterThanOrEqual(p.operand2, 0)
        }
    }

    func testMultiplicationFactorsLimitedBySqrtOfRange() {
        let range = 100
        let maxFactor = Int(sqrt(Double(range)))
        let problems = ProblemGenerator.generate(count: 200, range: range, operations: [.multiply])
        for p in problems {
            XCTAssertLessThanOrEqual(p.operand1, maxFactor)
            XCTAssertLessThanOrEqual(p.operand2, maxFactor)
        }
    }

    // MARK: - Division

    func testDivisionNeverDividesByZero() {
        let problems = ProblemGenerator.generate(count: 200, range: 20, operations: [.divide])
        for p in problems {
            XCTAssertEqual(p.operation, .divide)
            XCTAssertGreaterThan(p.operand2, 0, "Division by zero detected")
        }
    }

    func testDivisionAlwaysClean() {
        let problems = ProblemGenerator.generate(count: 200, range: 100, operations: [.divide])
        for p in problems {
            XCTAssertEqual(p.operand1 % p.operand2, 0, "Division \(p.operand1) / \(p.operand2) is not clean")
            XCTAssertEqual(p.correctAnswer, p.operand1 / p.operand2)
        }
    }

    // MARK: - Mixed Operations

    func testMixedOperationsProducesAllTypes() {
        let allOps: Set<MathOperation> = [.add, .subtract, .multiply, .divide]
        let problems = ProblemGenerator.generate(count: 200, range: 100, operations: allOps)
        let usedOps = Set(problems.map(\.operation))
        XCTAssertEqual(usedOps, allOps, "Not all operation types were generated")
    }

    // MARK: - Edge Cases

    func testRangeOfTen() {
        let problems = ProblemGenerator.generate(count: 50, range: 10, operations: [.add, .subtract, .multiply, .divide])
        for p in problems {
            switch p.operation {
            case .add:
                XCTAssertLessThanOrEqual(p.correctAnswer, 10)
            case .divide:
                XCTAssertGreaterThan(p.operand2, 0)
                XCTAssertEqual(p.operand1 % p.operand2, 0)
            default:
                break
            }
        }
    }
}
