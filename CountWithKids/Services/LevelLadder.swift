import Foundation

// 10-level adaptive ladder for the Guided Learning tier.
// Designed for Czech children aged 6-10 (roughly 1st through 3rd grade).
// Level 1 is trivial. Level 10 is end-of-2nd-grade Czech curriculum mastery.
//
// Each level provides a generator closure that returns one problem. The caller
// (ProblemGenerator) wraps that closure with deduplication and shuffle logic.
enum LevelLadder {
    static let minLevel = 1
    static let maxLevel = 10

    struct Spec {
        let operation: MathOperation
        let level: Int
        // Short human-readable description, mostly for the debug screen.
        let summary: String
        let generate: () -> MathProblem
    }

    static func spec(for operation: MathOperation, level: Int) -> Spec {
        let clamped = clampLevel(level)
        switch operation {
        case .add: return additionSpec(level: clamped)
        case .subtract: return subtractionSpec(level: clamped)
        case .multiply: return multiplicationSpec(level: clamped)
        case .divide: return divisionSpec(level: clamped)
        }
    }

    static func clampLevel(_ level: Int) -> Int {
        max(minLevel, min(maxLevel, level))
    }

    // MARK: - Helpers

    fileprivate static func make(_ a: Int, _ op: MathOperation, _ b: Int, _ result: Int) -> MathProblem {
        MathProblem(operand1: a, operand2: b, operation: op, correctAnswer: result)
    }

    /// True if column-wise addition a + b never carries.
    fileprivate static func additionHasNoCarry(_ a: Int, _ b: Int) -> Bool {
        var x = a, y = b
        while x > 0 || y > 0 {
            if (x % 10) + (y % 10) >= 10 { return false }
            x /= 10; y /= 10
        }
        return true
    }

    /// True if column-wise subtraction a - b (a >= b) never borrows.
    fileprivate static func subtractionHasNoBorrow(_ a: Int, _ b: Int) -> Bool {
        var x = a, y = b
        while y > 0 {
            if (x % 10) < (y % 10) { return false }
            x /= 10; y /= 10
        }
        return true
    }

    /// Re-roll a generator until `accept` is true. Falls back to the last value if exhausted.
    fileprivate static func retry<T>(_ generate: () -> T, accept: (T) -> Bool, maxAttempts: Int = 200) -> T {
        var last = generate()
        if accept(last) { return last }
        for _ in 0..<maxAttempts {
            last = generate()
            if accept(last) { return last }
        }
        return last
    }

    // MARK: - Addition ladder

    private static func additionSpec(level: Int) -> Spec {
        let summary: String
        let gen: () -> MathProblem
        switch level {
        case 1:
            summary = "+ ≤ 5"
            gen = {
                let a = Int.random(in: 1...4)
                let b = Int.random(in: 1...(5 - a))
                return make(a, .add, b, a + b)
            }
        case 2:
            summary = "+ ≤ 10"
            gen = {
                let a = Int.random(in: 1...9)
                let b = Int.random(in: 1...(10 - a))
                return make(a, .add, b, a + b)
            }
        case 3:
            summary = "+ ≤ 20, no carry"
            gen = {
                let pair = retry({
                    let a = Int.random(in: 1...19)
                    let b = Int.random(in: 1...(20 - a))
                    return (a, b)
                }, accept: { additionHasNoCarry($0.0, $0.1) })
                return make(pair.0, .add, pair.1, pair.0 + pair.1)
            }
        case 4:
            summary = "+ ≤ 20, with carry"
            gen = {
                let pair = retry({
                    let a = Int.random(in: 2...18)
                    let b = Int.random(in: 2...(20 - a))
                    return (a, b)
                }, accept: { !additionHasNoCarry($0.0, $0.1) })
                return make(pair.0, .add, pair.1, pair.0 + pair.1)
            }
        case 5:
            summary = "+ ≤ 50, single + double digit"
            gen = {
                let a = Int.random(in: 10...45)
                let b = Int.random(in: 1...min(9, 50 - a))
                return make(a, .add, b, a + b)
            }
        case 6:
            summary = "+ ≤ 100, no carry"
            gen = {
                let pair = retry({
                    let a = Int.random(in: 10...90)
                    let b = Int.random(in: 1...(100 - a))
                    return (a, b)
                }, accept: { additionHasNoCarry($0.0, $0.1) })
                return make(pair.0, .add, pair.1, pair.0 + pair.1)
            }
        case 7:
            summary = "+ ≤ 100, with carry"
            gen = {
                let pair = retry({
                    let a = Int.random(in: 12...88)
                    let b = Int.random(in: 12...max(12, 100 - a))
                    return (a, b)
                }, accept: { !additionHasNoCarry($0.0, $0.1) && $0.0 + $0.1 <= 100 })
                return make(pair.0, .add, pair.1, pair.0 + pair.1)
            }
        case 8:
            summary = "+ ≤ 500"
            gen = {
                let a = Int.random(in: 50...450)
                let b = Int.random(in: 10...(500 - a))
                return make(a, .add, b, a + b)
            }
        case 9:
            summary = "+ ≤ 1000"
            gen = {
                let a = Int.random(in: 100...900)
                let b = Int.random(in: 10...(1000 - a))
                return make(a, .add, b, a + b)
            }
        default:
            summary = "+ mastered, ≤ 1000"
            gen = {
                let a = Int.random(in: 1...999)
                let b = Int.random(in: 1...(1000 - a))
                return make(a, .add, b, a + b)
            }
        }
        return Spec(operation: .add, level: level, summary: summary, generate: gen)
    }

    // MARK: - Subtraction ladder

    private static func subtractionSpec(level: Int) -> Spec {
        let summary: String
        let gen: () -> MathProblem
        switch level {
        case 1:
            summary = "− within 5"
            gen = {
                let a = Int.random(in: 1...5)
                let b = Int.random(in: 0...a)
                return make(a, .subtract, b, a - b)
            }
        case 2:
            summary = "− within 10"
            gen = {
                let a = Int.random(in: 1...10)
                let b = Int.random(in: 0...a)
                return make(a, .subtract, b, a - b)
            }
        case 3:
            summary = "− within 20, no borrow"
            gen = {
                let pair = retry({
                    let a = Int.random(in: 2...20)
                    let b = Int.random(in: 1...a)
                    return (a, b)
                }, accept: { subtractionHasNoBorrow($0.0, $0.1) })
                return make(pair.0, .subtract, pair.1, pair.0 - pair.1)
            }
        case 4:
            summary = "− within 20, with borrow"
            gen = {
                let pair = retry({
                    let a = Int.random(in: 11...20)
                    let b = Int.random(in: 2...9)
                    return (a, b)
                }, accept: { !subtractionHasNoBorrow($0.0, $0.1) && $0.0 >= $0.1 })
                return make(pair.0, .subtract, pair.1, pair.0 - pair.1)
            }
        case 5:
            summary = "− within 50"
            gen = {
                let a = Int.random(in: 11...50)
                let b = Int.random(in: 1...a)
                return make(a, .subtract, b, a - b)
            }
        case 6:
            summary = "− within 100, no borrow"
            gen = {
                let pair = retry({
                    let a = Int.random(in: 11...100)
                    let b = Int.random(in: 1...a)
                    return (a, b)
                }, accept: { subtractionHasNoBorrow($0.0, $0.1) })
                return make(pair.0, .subtract, pair.1, pair.0 - pair.1)
            }
        case 7:
            summary = "− within 100, with borrow"
            gen = {
                let pair = retry({
                    let a = Int.random(in: 21...100)
                    let b = Int.random(in: 12...a)
                    return (a, b)
                }, accept: { !subtractionHasNoBorrow($0.0, $0.1) })
                return make(pair.0, .subtract, pair.1, pair.0 - pair.1)
            }
        case 8:
            summary = "− within 500"
            gen = {
                let a = Int.random(in: 50...500)
                let b = Int.random(in: 10...a)
                return make(a, .subtract, b, a - b)
            }
        case 9:
            summary = "− within 1000"
            gen = {
                let a = Int.random(in: 100...1000)
                let b = Int.random(in: 10...a)
                return make(a, .subtract, b, a - b)
            }
        default:
            summary = "− mastered, within 1000"
            gen = {
                let a = Int.random(in: 1...1000)
                let b = Int.random(in: 1...a)
                return make(a, .subtract, b, a - b)
            }
        }
        return Spec(operation: .subtract, level: level, summary: summary, generate: gen)
    }

    // MARK: - Multiplication ladder

    private static func multiplicationSpec(level: Int) -> Spec {
        let summary: String
        let gen: () -> MathProblem
        switch level {
        case 1:
            summary = "×1, ×2"
            gen = {
                let a = [1, 2].randomElement()!
                let b = Int.random(in: 1...10)
                return make(a, .multiply, b, a * b)
            }
        case 2:
            summary = "×1–5"
            gen = {
                let a = Int.random(in: 1...5)
                let b = Int.random(in: 1...10)
                return make(a, .multiply, b, a * b)
            }
        case 3:
            summary = "×1–10 tables (≤ 100)"
            gen = {
                let a = Int.random(in: 1...10)
                let b = Int.random(in: 1...10)
                return make(a, .multiply, b, a * b)
            }
        case 4:
            summary = "×11, ×12"
            gen = {
                let a = [11, 12].randomElement()!
                let b = Int.random(in: 2...10)
                return make(a, .multiply, b, a * b)
            }
        case 5:
            summary = "two-digit × one-digit ≤ 200"
            gen = {
                let pair = retry({
                    let a = Int.random(in: 11...50)
                    let b = Int.random(in: 2...9)
                    return (a, b)
                }, accept: { $0.0 * $0.1 <= 200 })
                return make(pair.0, .multiply, pair.1, pair.0 * pair.1)
            }
        case 6:
            summary = "two-digit × one-digit ≤ 500"
            gen = {
                let pair = retry({
                    let a = Int.random(in: 20...80)
                    let b = Int.random(in: 3...9)
                    return (a, b)
                }, accept: { $0.0 * $0.1 <= 500 })
                return make(pair.0, .multiply, pair.1, pair.0 * pair.1)
            }
        case 7:
            summary = "×15, ×20, ×25 patterns"
            gen = {
                let a = [15, 20, 25].randomElement()!
                let b = Int.random(in: 2...12)
                return make(a, .multiply, b, a * b)
            }
        case 8:
            summary = "two-digit × two-digit ≤ 1000"
            gen = {
                let pair = retry({
                    let a = Int.random(in: 11...50)
                    let b = Int.random(in: 11...50)
                    return (a, b)
                }, accept: { $0.0 * $0.1 <= 1000 })
                return make(pair.0, .multiply, pair.1, pair.0 * pair.1)
            }
        case 9:
            summary = "two-digit × two-digit ≤ 1000, mixed"
            gen = {
                let pair = retry({
                    let a = Int.random(in: 12...90)
                    let b = Int.random(in: 12...90)
                    return (a, b)
                }, accept: { $0.0 * $0.1 <= 1000 })
                return make(pair.0, .multiply, pair.1, pair.0 * pair.1)
            }
        default:
            summary = "× mastered ≤ 1000"
            gen = {
                let pair = retry({
                    let a = Int.random(in: 2...100)
                    let b = Int.random(in: 2...100)
                    return (a, b)
                }, accept: { $0.0 * $0.1 <= 1000 })
                return make(pair.0, .multiply, pair.1, pair.0 * pair.1)
            }
        }
        return Spec(operation: .multiply, level: level, summary: summary, generate: gen)
    }

    // MARK: - Division ladder

    private static func divisionSpec(level: Int) -> Spec {
        let summary: String
        let gen: () -> MathProblem
        switch level {
        case 1:
            summary = "÷1, ÷2 (exact)"
            gen = {
                let divisor = [1, 2].randomElement()!
                let answer = Int.random(in: 1...10)
                let dividend = answer * divisor
                return make(dividend, .divide, divisor, answer)
            }
        case 2:
            summary = "÷1–5 (exact)"
            gen = {
                let divisor = Int.random(in: 1...5)
                let answer = Int.random(in: 1...10)
                let dividend = answer * divisor
                return make(dividend, .divide, divisor, answer)
            }
        case 3:
            summary = "÷ inverse of ×1–10 tables"
            gen = {
                let divisor = Int.random(in: 2...10)
                let answer = Int.random(in: 2...10)
                let dividend = answer * divisor
                return make(dividend, .divide, divisor, answer)
            }
        case 4:
            summary = "two-digit ÷ one-digit, exact, ≤ 100"
            gen = {
                let trip = retry({
                    let divisor = Int.random(in: 2...9)
                    let answer = Int.random(in: 2...12)
                    let dividend = answer * divisor
                    return (dividend, divisor, answer)
                }, accept: { $0.0 >= 10 && $0.0 <= 100 })
                return make(trip.0, .divide, trip.1, trip.2)
            }
        case 5:
            summary = "two-digit ÷ one-digit, exact, ≤ 500"
            gen = {
                let trip = retry({
                    let divisor = Int.random(in: 3...9)
                    let answer = Int.random(in: 5...60)
                    let dividend = answer * divisor
                    return (dividend, divisor, answer)
                }, accept: { $0.0 >= 30 && $0.0 <= 500 })
                return make(trip.0, .divide, trip.1, trip.2)
            }
        case 6:
            summary = "÷ with remainder, ≤ 100"
            gen = {
                let trip = retry({
                    let divisor = Int.random(in: 2...9)
                    let dividend = Int.random(in: 10...100)
                    return (dividend, divisor, dividend / divisor)
                }, accept: { $0.0 % $0.1 != 0 })
                return make(trip.0, .divide, trip.1, trip.2)
            }
        case 7:
            summary = "two-digit ÷ two-digit, exact, ≤ 500"
            gen = {
                let trip = retry({
                    let divisor = Int.random(in: 11...30)
                    let answer = Int.random(in: 2...20)
                    let dividend = answer * divisor
                    return (dividend, divisor, answer)
                }, accept: { $0.0 <= 500 && $0.0 >= 22 })
                return make(trip.0, .divide, trip.1, trip.2)
            }
        case 8:
            summary = "two-digit ÷ two-digit, exact, ≤ 1000"
            gen = {
                let trip = retry({
                    let divisor = Int.random(in: 11...50)
                    let answer = Int.random(in: 2...30)
                    let dividend = answer * divisor
                    return (dividend, divisor, answer)
                }, accept: { $0.0 <= 1000 && $0.0 >= 22 })
                return make(trip.0, .divide, trip.1, trip.2)
            }
        case 9:
            summary = "÷ with remainder, ≤ 1000"
            gen = {
                let trip = retry({
                    let divisor = Int.random(in: 3...20)
                    let dividend = Int.random(in: 50...1000)
                    return (dividend, divisor, dividend / divisor)
                }, accept: { $0.0 % $0.1 != 0 })
                return make(trip.0, .divide, trip.1, trip.2)
            }
        default:
            summary = "÷ mastered ≤ 1000"
            gen = {
                let divisor = Int.random(in: 2...20)
                let answer = Int.random(in: 2...50)
                let dividend = answer * divisor
                return make(dividend, .divide, divisor, answer)
            }
        }
        return Spec(operation: .divide, level: level, summary: summary, generate: gen)
    }
}
