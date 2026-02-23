import Foundation

struct ProblemGenerator {
    static func generate(count: Int, range: Int, operations: Set<MathOperation>) -> [MathProblem] {
        guard !operations.isEmpty else { return [] }
        let ops = Array(operations)
        return (0..<count).map { _ in
            let op = ops.randomElement()!
            return makeProblem(op: op, range: range)
        }
    }

    private static func makeProblem(op: MathOperation, range: Int) -> MathProblem {
        switch op {
        case .add:
            let a = Int.random(in: 0...range)
            let maxB = range - a
            let b = maxB > 0 ? Int.random(in: 0...maxB) : 0
            return MathProblem(operand1: a, operand2: b, operation: op, correctAnswer: a + b)

        case .subtract:
            let a = Int.random(in: 0...range)
            let b = Int.random(in: 0...range)
            return MathProblem(operand1: a, operand2: b, operation: op, correctAnswer: a - b)

        case .multiply:
            let maxFactor = max(1, Int(sqrt(Double(range))))
            let a = Int.random(in: 0...maxFactor)
            let b = Int.random(in: 0...maxFactor)
            return MathProblem(operand1: a, operand2: b, operation: op, correctAnswer: a * b)

        case .divide:
            let maxAnswer = min(range, 12)
            let answer = Int.random(in: 0...maxAnswer)
            let divisor = Int.random(in: 1...max(1, min(range, 12)))
            let dividend = answer * divisor
            return MathProblem(operand1: dividend, operand2: divisor, operation: op, correctAnswer: answer)
        }
    }
}
