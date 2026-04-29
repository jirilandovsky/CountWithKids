import Foundation

// Scaffolded hints used in Challenge mode for Guided Learning subscribers.
//
// Per GUIDED_LEARNING_DEV_PLAN.md §2.3: keep narrow — 20–30 hints covering the
// common cases. Three escalating tiers:
//
//   • Tier 1 (5 s):  generic nudge   → encouragement, no math content
//   • Tier 2 (10 s): operation-specific strategy
//   • Tier 3 (20 s): worked example anchored to the current problem
//
// All strings are looked up via `loc()` so the strings catalog can supply
// Czech / English / Hebrew translations. The English source is the lookup key.
enum HintLibrary {
    enum Tier: Int, Comparable {
        case nudge = 1, strategy = 2, workedExample = 3

        static func < (lhs: Tier, rhs: Tier) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    /// Returns the localized hint string for the given tier and problem.
    static func hint(tier: Tier, for problem: MathProblem) -> String {
        switch tier {
        case .nudge:
            return loc(genericNudges.randomElement() ?? "You can do it!")
        case .strategy:
            return loc(strategy(for: problem))
        case .workedExample:
            return loc(workedExample(for: problem))
        }
    }

    // MARK: - Tier 1: generic nudges (operation-agnostic)

    private static let genericNudges: [String] = [
        "Take your time.",
        "You can do it!",
        "Let's try this one.",
        "Keep going!",
        "Almost there!"
    ]

    // MARK: - Tier 2: operation-specific strategy

    private static func strategy(for problem: MathProblem) -> String {
        switch problem.operation {
        case .add:
            if problem.operand1 + problem.operand2 <= 10 {
                return "Count up on your fingers."
            }
            if max(problem.operand1, problem.operand2) >= 10 {
                return "Add the tens first, then the ones."
            }
            return "Make a 10 first, then add the rest."
        case .subtract:
            if max(problem.operand1, problem.operand2) <= 10 {
                return "Count back from the bigger number."
            }
            return "Subtract the tens first, then the ones."
        case .multiply:
            if problem.operand1 == 10 || problem.operand2 == 10 {
                return "Multiplying by 10 just adds a zero."
            }
            if problem.operand1 == 5 || problem.operand2 == 5 {
                return "Count by 5s."
            }
            if problem.operand1 == 2 || problem.operand2 == 2 {
                return "Doubling is just adding the number to itself."
            }
            return "Use a multiplication you already know, then add or subtract."
        case .divide:
            return "Think: how many times does the smaller number fit into the bigger one?"
        }
    }

    // MARK: - Tier 3: worked example tied to the problem

    private static func workedExample(for problem: MathProblem) -> String {
        let a = problem.operand1
        let b = problem.operand2
        switch problem.operation {
        case .add:
            // Anchor: the same problem with one operand reduced by 1, so the
            // kid sees a near-miss and adds 1.
            if b > 0 {
                let near = a + (b - 1)
                return "If \(a) + \(b - 1) = \(near), what is \(a) + \(b)?"
            }
            return "Try counting up from \(a)."
        case .subtract:
            if b > 0 {
                let near = a - (b - 1)
                return "If \(a) − \(b - 1) = \(near), what is \(a) − \(b)?"
            }
            return "Try counting down from \(a)."
        case .multiply:
            if b > 1 {
                let near = a * (b - 1)
                return "If \(a) × \(b - 1) = \(near), then \(a) × \(b) = \(near) + \(a)."
            }
            return "Anything × 1 is itself."
        case .divide:
            // Show inverse multiplication.
            return "What number times \(b) equals \(a)?"
        }
    }
}
