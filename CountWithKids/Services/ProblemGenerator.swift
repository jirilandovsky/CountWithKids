import Foundation

struct ProblemGenerator {
    /// Adaptive overload used by the Guided Learning tier. Pulls from the level
    /// ladder and reuses the dedup/answer-balance logic of the free-practice
    /// generator.
    static func generate(operation: MathOperation, level: Int, count: Int) -> [MathProblem] {
        let spec = LevelLadder.spec(for: operation, level: level)
        return generate(count: count, using: { spec.generate() }, isCommutative: operation == .add || operation == .multiply)
    }

    /// Adaptive overload for mixed-operation guided sessions (Daily Plan
    /// "Challenge"). Each operation contributes to the spec lookup at its
    /// own level.
    static func generate(levels: [MathOperation: Int], count: Int) -> [MathProblem] {
        guard !levels.isEmpty else { return [] }
        let ops = Array(levels.keys)
        var index = 0
        return generate(count: count, using: {
            let op = ops[index % ops.count]
            index += 1
            let spec = LevelLadder.spec(for: op, level: levels[op] ?? LevelLadder.minLevel)
            return spec.generate()
        }, isCommutative: false)  // mixed: don't apply commutative dedup across ops
    }

    /// Shared dedup/balance loop. Caller supplies the per-attempt generator.
    private static func generate(count: Int, using makeOne: () -> MathProblem, isCommutative: Bool) -> [MathProblem] {
        guard count > 0 else { return [] }
        var problems: [MathProblem] = []
        var seen = Set<String>()
        var answerCounts: [Int: Int] = [:]

        var attempts = 0
        let maxAttempts = count * 50

        while problems.count < count && attempts < maxAttempts {
            attempts += 1
            let problem = makeOne()
            let key = "\(problem.operand1)\(problem.operation.rawValue)\(problem.operand2)"
            if seen.contains(key) { continue }

            let commutative = isCommutative && (problem.operation == .add || problem.operation == .multiply)
            if commutative {
                let reverse = "\(problem.operand2)\(problem.operation.rawValue)\(problem.operand1)"
                if seen.contains(reverse) { continue }
            }

            if (answerCounts[problem.correctAnswer] ?? 0) >= 2 { continue }

            seen.insert(key)
            if commutative {
                seen.insert("\(problem.operand2)\(problem.operation.rawValue)\(problem.operand1)")
            }
            answerCounts[problem.correctAnswer, default: 0] += 1
            problems.append(problem)
        }

        // Fallback for very narrow level constraints.
        while problems.count < count {
            problems.append(makeOne())
        }

        return problems.shuffled()
    }

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
