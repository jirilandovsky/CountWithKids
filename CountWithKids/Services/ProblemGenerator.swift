import Foundation

struct ProblemGenerator {
    static func generate(count: Int, range: Int, operations: Set<MathOperation>) -> [MathProblem] {
        guard !operations.isEmpty else { return [] }
        let ops = Array(operations)
        var problems: [MathProblem] = []
        var seenProblems = Set<String>()   // "3+7" and "7+3" both tracked
        var answerCounts: [Int: Int] = [:]  // track how many problems share the same answer

        var attempts = 0
        let maxAttempts = count * 50

        while problems.count < count && attempts < maxAttempts {
            attempts += 1
            let op = ops[problems.count % ops.count]
            let problem = makeProblem(op: op, range: range)

            // Deduplicate: check both "a+b" and for commutative ops also "b+a"
            let key = "\(problem.operand1)\(problem.operation.rawValue)\(problem.operand2)"
            if seenProblems.contains(key) { continue }

            // For commutative operations, also block the reverse
            let isCommutative = (op == .add || op == .multiply)
            if isCommutative {
                let reverseKey = "\(problem.operand2)\(problem.operation.rawValue)\(problem.operand1)"
                if seenProblems.contains(reverseKey) { continue }
            }

            // Limit problems with the same answer to at most 2
            let answer = problem.correctAnswer
            if (answerCounts[answer] ?? 0) >= 2 { continue }

            seenProblems.insert(key)
            if isCommutative {
                seenProblems.insert("\(problem.operand2)\(problem.operation.rawValue)\(problem.operand1)")
            }
            answerCounts[answer, default: 0] += 1
            problems.append(problem)
        }

        // Fallback if we couldn't fill (very small range)
        while problems.count < count {
            let op = ops.randomElement()!
            problems.append(makeProblem(op: op, range: range))
        }

        return problems.shuffled()
    }

    private static func makeProblem(op: MathOperation, range: Int) -> MathProblem {
        switch op {
        case .add:
            let a = Int.random(in: 1...(range - 1))
            let maxB = range - a
            let b = Int.random(in: 1...max(1, maxB))
            return MathProblem(operand1: a, operand2: b, operation: op, correctAnswer: a + b)

        case .subtract:
            let a = Int.random(in: 1...range)
            let b = Int.random(in: 1...range)
            return MathProblem(operand1: a, operand2: b, operation: op, correctAnswer: a - b)

        case .multiply:
            let maxFactor = max(2, Int(sqrt(Double(range))))
            let a = Int.random(in: 1...maxFactor)
            let b = Int.random(in: 1...maxFactor)
            return MathProblem(operand1: a, operand2: b, operation: op, correctAnswer: a * b)

        case .divide:
            let maxAnswer = min(range, 12)
            let answer = Int.random(in: 1...maxAnswer)
            let divisor = Int.random(in: 1...max(1, min(range, 12)))
            let dividend = answer * divisor
            return MathProblem(operand1: dividend, operand2: divisor, operation: op, correctAnswer: answer)
        }
    }
}
