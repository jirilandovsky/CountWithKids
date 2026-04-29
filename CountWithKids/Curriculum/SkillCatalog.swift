import Foundation

// Hejný-aligned Czech RVP curriculum graph for the Guided Learning tier.
//
// Replaces the older flat per-operation L1–L10 ladder. Skills are arranged
// across grades 1–5 (ages 6–11) with explicit prerequisites; a child works
// through them in order. Hejný sequencing in particular:
//   • Full multiplication tables 1–10 are completed in 2.tř (not split 2/3).
//   • +/− and × are interleaved earlier than the traditional path.
//
// Sources informing this graph:
//   • RVP ZV 2021 očekávané výstupy 1.–5. roč.
//   • H-mat (Hejný metoda) Očekávané výstupy 1. roč. PDF
//   • Skolákov.eu 1.–4. třída sequencing
//   • CCSS-M & Singapore Primary Math (cross-validation)
//
// Skill IDs are stable strings — used as the SwiftData key in SkillProgress.
// NEVER renumber. Adding a new skill is fine; removing one breaks migration.
enum CzechGrade: Int, CaseIterable, Codable, Identifiable {
    case grade1 = 1, grade2 = 2, grade3 = 3, grade4 = 4, grade5 = 5
    var id: Int { rawValue }

    /// Localized display name. Czech build returns "1.tř" through "5.tř";
    /// English/Hebrew get full localized strings via the strings catalog.
    var displayName: String {
        switch self {
        case .grade1: return loc("Grade 1")
        case .grade2: return loc("Grade 2")
        case .grade3: return loc("Grade 3")
        case .grade4: return loc("Grade 4")
        case .grade5: return loc("Grade 5")
        }
    }
}

struct Skill: Identifiable, Hashable {
    let id: String                        // stable id, e.g. "add_within_10"
    let grade: CzechGrade
    let displayKey: String                // localized key, e.g. "skill.add_within_10"
    /// English source string used as the localization key (e.g. "+ within 10").
    /// Czech / Hebrew translations live in Localizable.xcstrings.
    let shortLabel: String
    let prerequisites: [String]
    let primaryOperation: MathOperation?  // nil for counting/concept skills
    let generate: () -> MathProblem

    /// Resolved through `loc()` against the current app language.
    var localizedLabel: String { loc(shortLabel) }

    static func == (lhs: Skill, rhs: Skill) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

enum SkillCatalog {
    /// All skills in dependency order. The first skill (`count_to_10`) has no
    /// prerequisites and is the absolute beginner anchor.
    static let allSkills: [Skill] = buildCatalog()

    static func skill(_ id: String) -> Skill? { byId[id] }

    static func skills(in grade: CzechGrade) -> [Skill] {
        allSkills.filter { $0.grade == grade }
    }

    static func firstSkill(of grade: CzechGrade) -> Skill {
        skills(in: grade).first ?? allSkills[0]
    }

    /// Anchor skill the placement warmup starts from, given parent-declared
    /// age + (optional) school grade.
    ///
    /// We anchor at what teachers typically OPEN the school year with, not
    /// the middle of the grade — that way:
    ///   • A strong kid promotes (cap +2) and lands at a credible mid-grade
    ///     skill, not end-of-grade content.
    ///   • A weak kid demotes safely without falling out of the grade.
    ///   • Daily-plan progression handles the rest of the year naturally.
    ///
    /// 5-year-olds map to the 1.tř anchor; placement will demote if needed.
    static func anchorSkill(age: Int, grade: CzechGrade?) -> Skill {
        let resolvedGrade: CzechGrade = grade ?? guessGrade(forAge: age)
        let anchorID: String
        switch resolvedGrade {
        case .grade1: anchorID = "add_within_10"
        case .grade2: anchorID = "add_within_100_no_carry"
        case .grade3: anchorID = "times_6"
        case .grade4: anchorID = "multiply_2digit_by_1digit"
        case .grade5: anchorID = "divide_by_2digit"
        }
        return skill(anchorID) ?? firstSkill(of: resolvedGrade)
    }

    private static func guessGrade(forAge age: Int) -> CzechGrade {
        switch age {
        case ..<7: return .grade1
        case 7:    return .grade2
        case 8:    return .grade3
        case 9:    return .grade4
        default:   return .grade5
        }
    }

    static func index(of skillID: String) -> Int? {
        allSkills.firstIndex(where: { $0.id == skillID })
    }

    /// Returns the skill `offset` positions away in catalog order, clamped to bounds.
    static func neighbor(of skillID: String, offset: Int) -> Skill? {
        guard let i = index(of: skillID) else { return nil }
        let target = max(0, min(allSkills.count - 1, i + offset))
        return allSkills[target]
    }

    private static let byId: [String: Skill] = Dictionary(
        uniqueKeysWithValues: allSkills.map { ($0.id, $0) }
    )

    // MARK: - Catalog construction

    private static func buildCatalog() -> [Skill] {
        var skills: [Skill] = []

        // ───────────────────── 1. třída (age 6–7) ─────────────────────
        // Note: we deliberately don't model "count to N" as a practice skill —
        // a `n + 0 = n` problem template makes Focus sessions degenerate. The
        // kid is assumed to know counting before tackling addition.

        skills.append(Skill(
            id: "add_within_10", grade: .grade1,
            displayKey: "skill.add_within_10", shortLabel: "+ within 10",
            prerequisites: [], primaryOperation: .add,
            generate: {
                // Both operands ≥ 1 so we never serve `n + 0`.
                let a = Int.random(in: 1...9)
                let b = Int.random(in: 1...max(1, 10 - a))
                return MathProblem(operand1: a, operand2: b, operation: .add, correctAnswer: a + b)
            }
        ))

        skills.append(Skill(
            id: "sub_within_10", grade: .grade1,
            displayKey: "skill.sub_within_10", shortLabel: "− within 10",
            prerequisites: ["add_within_10"], primaryOperation: .subtract,
            generate: {
                // a ≥ 2, b ≥ 1, b ≤ a − 1 so we never serve `n − 0` or `n − n`.
                let a = Int.random(in: 2...10)
                let b = Int.random(in: 1...(a - 1))
                return MathProblem(operand1: a, operand2: b, operation: .subtract, correctAnswer: a - b)
            }
        ))

        skills.append(Skill(
            id: "add_within_20_no_carry", grade: .grade1,
            displayKey: "skill.add_within_20_no_carry", shortLabel: "+ within 20 (no carrying)",
            prerequisites: ["sub_within_10"], primaryOperation: .add,
            generate: {
                // Both operands ≥ 1 so the kid is actually adding two numbers.
                let (a, b) = retryPair(
                    gen: {
                        let a = Int.random(in: 1...18)
                        let b = Int.random(in: 1...max(1, 19 - a))
                        return (a, b)
                    },
                    accept: { hasNoCarry($0.0, $0.1) }
                )
                return MathProblem(operand1: a, operand2: b, operation: .add, correctAnswer: a + b)
            }
        ))

        skills.append(Skill(
            id: "sub_within_20_no_borrow", grade: .grade1,
            displayKey: "skill.sub_within_20_no_borrow", shortLabel: "− within 20 (no borrowing)",
            prerequisites: ["add_within_20_no_carry"], primaryOperation: .subtract,
            generate: {
                let (a, b) = retryPair(
                    gen: {
                        let a = Int.random(in: 2...20)
                        let b = Int.random(in: 1...a)
                        return (a, b)
                    },
                    accept: { hasNoBorrow($0.0, $0.1) }
                )
                return MathProblem(operand1: a, operand2: b, operation: .subtract, correctAnswer: a - b)
            }
        ))

        skills.append(Skill(
            id: "add_within_20_carry", grade: .grade1,
            displayKey: "skill.add_within_20_carry", shortLabel: "+ within 20 (with carrying)",
            prerequisites: ["sub_within_20_no_borrow"], primaryOperation: .add,
            generate: {
                let (a, b) = retryPair(
                    gen: {
                        let a = Int.random(in: 2...18)
                        let b = Int.random(in: 2...(20 - a))
                        return (a, b)
                    },
                    accept: { !hasNoCarry($0.0, $0.1) }
                )
                return MathProblem(operand1: a, operand2: b, operation: .add, correctAnswer: a + b)
            }
        ))

        skills.append(Skill(
            id: "sub_within_20_borrow", grade: .grade1,
            displayKey: "skill.sub_within_20_borrow", shortLabel: "− within 20 (with borrowing)",
            prerequisites: ["add_within_20_carry"], primaryOperation: .subtract,
            generate: {
                let (a, b) = retryPair(
                    gen: {
                        let a = Int.random(in: 11...20)
                        let b = Int.random(in: 2...9)
                        return (a, b)
                    },
                    accept: { !hasNoBorrow($0.0, $0.1) && $0.0 >= $0.1 }
                )
                return MathProblem(operand1: a, operand2: b, operation: .subtract, correctAnswer: a - b)
            }
        ))

        // ───────────────────── 2. třída (age 7–8) ─────────────────────

        skills.append(Skill(
            id: "add_within_100_no_carry", grade: .grade2,
            displayKey: "skill.add_within_100_no_carry", shortLabel: "+ within 100 (no carrying)",
            prerequisites: ["sub_within_20_borrow"], primaryOperation: .add,
            generate: {
                let (a, b) = retryPair(
                    gen: {
                        let a = Int.random(in: 10...90)
                        let b = Int.random(in: 1...(100 - a))
                        return (a, b)
                    },
                    accept: { hasNoCarry($0.0, $0.1) }
                )
                return MathProblem(operand1: a, operand2: b, operation: .add, correctAnswer: a + b)
            }
        ))

        skills.append(Skill(
            id: "sub_within_100_no_borrow", grade: .grade2,
            displayKey: "skill.sub_within_100_no_borrow", shortLabel: "− within 100 (no borrowing)",
            prerequisites: ["add_within_100_no_carry"], primaryOperation: .subtract,
            generate: {
                let (a, b) = retryPair(
                    gen: {
                        let a = Int.random(in: 11...100)
                        let b = Int.random(in: 1...a)
                        return (a, b)
                    },
                    accept: { hasNoBorrow($0.0, $0.1) }
                )
                return MathProblem(operand1: a, operand2: b, operation: .subtract, correctAnswer: a - b)
            }
        ))

        skills.append(Skill(
            id: "add_within_100_carry", grade: .grade2,
            displayKey: "skill.add_within_100_carry", shortLabel: "+ within 100 (with carrying)",
            prerequisites: ["sub_within_100_no_borrow"], primaryOperation: .add,
            generate: {
                let (a, b) = retryPair(
                    gen: {
                        let a = Int.random(in: 12...88)
                        let b = Int.random(in: 12...max(12, 100 - a))
                        return (a, b)
                    },
                    accept: { !hasNoCarry($0.0, $0.1) && $0.0 + $0.1 <= 100 }
                )
                return MathProblem(operand1: a, operand2: b, operation: .add, correctAnswer: a + b)
            }
        ))

        skills.append(Skill(
            id: "sub_within_100_borrow", grade: .grade2,
            displayKey: "skill.sub_within_100_borrow", shortLabel: "− within 100 (with borrowing)",
            prerequisites: ["add_within_100_carry"], primaryOperation: .subtract,
            generate: {
                let (a, b) = retryPair(
                    gen: {
                        let a = Int.random(in: 21...100)
                        let b = Int.random(in: 12...a)
                        return (a, b)
                    },
                    accept: { !hasNoBorrow($0.0, $0.1) }
                )
                return MathProblem(operand1: a, operand2: b, operation: .subtract, correctAnswer: a - b)
            }
        ))

        // Hejný order: 2 → 5 → 10 → 3 → 4 → 6 → 7 → 8 → 9.
        // 2.tř covers 2 through 5 (the "easy" ones); 6–9 spill into 3.tř.
        let timesOrder = [2, 5, 10, 3, 4, 6, 7, 8, 9]

        for (i, n) in timesOrder.enumerated() {
            let prev = i == 0 ? "sub_within_100_borrow" : "times_\(timesOrder[i - 1])"
            let grade: CzechGrade = (n <= 5 || n == 10) ? .grade2 : .grade3
            skills.append(Skill(
                id: "times_\(n)", grade: grade,
                displayKey: "skill.times_\(n)", shortLabel: "× \(n)",
                prerequisites: [prev],
                primaryOperation: .multiply,
                generate: {
                    let other = Int.random(in: 1...10)
                    return MathProblem(operand1: n, operand2: other, operation: .multiply, correctAnswer: n * other)
                }
            ))
        }

        // Division by 2, 5, 10, 3, 4 introduced in 2.tř alongside the easy tables.
        // Division by 6–9 lands in 3.tř.
        for n in [2, 5, 10, 3, 4] {
            skills.append(Skill(
                id: "divide_by_\(n)", grade: .grade2,
                displayKey: "skill.divide_by_\(n)", shortLabel: "÷ \(n)",
                prerequisites: ["times_\(n)"],
                primaryOperation: .divide,
                generate: {
                    let q = Int.random(in: 1...10)
                    let dividend = q * n
                    return MathProblem(operand1: dividend, operand2: n, operation: .divide, correctAnswer: q)
                }
            ))
        }

        // ───────────────────── 3. třída (age 8–9) ─────────────────────

        for n in [6, 7, 8, 9] {
            skills.append(Skill(
                id: "divide_by_\(n)", grade: .grade3,
                displayKey: "skill.divide_by_\(n)", shortLabel: "÷ \(n)",
                prerequisites: ["times_\(n)"],
                primaryOperation: .divide,
                generate: {
                    let q = Int.random(in: 1...10)
                    let dividend = q * n
                    return MathProblem(operand1: dividend, operand2: n, operation: .divide, correctAnswer: q)
                }
            ))
        }

        skills.append(Skill(
            id: "divide_with_remainder_within_100", grade: .grade3,
            displayKey: "skill.divide_with_remainder_within_100", shortLabel: "÷ with remainder (within 100)",
            prerequisites: ["divide_by_9"], primaryOperation: .divide,
            generate: {
                // Quotient-only (kid types the integer result, remainder implicit).
                let (d, div) = retryPair(
                    gen: {
                        let divisor = Int.random(in: 2...9)
                        let dividend = Int.random(in: 10...100)
                        return (dividend, divisor)
                    },
                    accept: { $0.0 % $0.1 != 0 }
                )
                return MathProblem(operand1: d, operand2: div, operation: .divide, correctAnswer: d / div)
            }
        ))

        skills.append(Skill(
            id: "add_within_1000", grade: .grade3,
            displayKey: "skill.add_within_1000", shortLabel: "+ within 1000",
            prerequisites: ["sub_within_100_borrow"], primaryOperation: .add,
            generate: {
                let a = Int.random(in: 100...900)
                let b = Int.random(in: 10...(1000 - a))
                return MathProblem(operand1: a, operand2: b, operation: .add, correctAnswer: a + b)
            }
        ))

        skills.append(Skill(
            id: "sub_within_1000", grade: .grade3,
            displayKey: "skill.sub_within_1000", shortLabel: "− within 1000",
            prerequisites: ["add_within_1000"], primaryOperation: .subtract,
            generate: {
                let a = Int.random(in: 100...1000)
                let b = Int.random(in: 10...a)
                return MathProblem(operand1: a, operand2: b, operation: .subtract, correctAnswer: a - b)
            }
        ))

        // ───────────────────── 4. třída (age 9–10) ─────────────────────

        skills.append(Skill(
            id: "multiply_2digit_by_1digit", grade: .grade4,
            displayKey: "skill.multiply_2digit_by_1digit", shortLabel: "2-digit × 1-digit",
            prerequisites: ["divide_by_9"], primaryOperation: .multiply,
            generate: {
                let (a, b) = retryPair(
                    gen: {
                        let a = Int.random(in: 11...50)
                        let b = Int.random(in: 2...9)
                        return (a, b)
                    },
                    accept: { $0.0 * $0.1 <= 500 }
                )
                return MathProblem(operand1: a, operand2: b, operation: .multiply, correctAnswer: a * b)
            }
        ))

        skills.append(Skill(
            id: "divide_2digit_by_1digit", grade: .grade4,
            displayKey: "skill.divide_2digit_by_1digit", shortLabel: "2-digit ÷ 1-digit",
            prerequisites: ["multiply_2digit_by_1digit"], primaryOperation: .divide,
            generate: {
                let (d, div, q) = retryTriple(
                    gen: {
                        let divisor = Int.random(in: 2...9)
                        let q = Int.random(in: 5...60)
                        let dividend = q * divisor
                        return (dividend, divisor, q)
                    },
                    accept: { $0.0 >= 20 && $0.0 <= 500 }
                )
                return MathProblem(operand1: d, operand2: div, operation: .divide, correctAnswer: q)
            }
        ))

        skills.append(Skill(
            id: "multiply_2digit_by_2digit", grade: .grade4,
            displayKey: "skill.multiply_2digit_by_2digit", shortLabel: "2-digit × 2-digit",
            prerequisites: ["multiply_2digit_by_1digit"], primaryOperation: .multiply,
            generate: {
                let (a, b) = retryPair(
                    gen: {
                        let a = Int.random(in: 11...50)
                        let b = Int.random(in: 11...50)
                        return (a, b)
                    },
                    accept: { $0.0 * $0.1 <= 1000 }
                )
                return MathProblem(operand1: a, operand2: b, operation: .multiply, correctAnswer: a * b)
            }
        ))

        // ───────────────────── 5. třída (age 10–11) ─────────────────────

        skills.append(Skill(
            id: "divide_by_2digit", grade: .grade5,
            displayKey: "skill.divide_by_2digit", shortLabel: "÷ 2-digit",
            prerequisites: ["divide_2digit_by_1digit", "multiply_2digit_by_2digit"],
            primaryOperation: .divide,
            generate: {
                let (d, div, q) = retryTriple(
                    gen: {
                        let divisor = Int.random(in: 11...30)
                        let q = Int.random(in: 2...30)
                        let dividend = q * divisor
                        return (dividend, divisor, q)
                    },
                    accept: { $0.0 <= 1000 }
                )
                return MathProblem(operand1: d, operand2: div, operation: .divide, correctAnswer: q)
            }
        ))

        skills.append(Skill(
            id: "divide_with_remainder_within_1000", grade: .grade5,
            displayKey: "skill.divide_with_remainder_within_1000", shortLabel: "÷ with remainder (within 1000)",
            prerequisites: ["divide_by_2digit"], primaryOperation: .divide,
            generate: {
                let (d, div) = retryPair(
                    gen: {
                        let divisor = Int.random(in: 3...20)
                        let dividend = Int.random(in: 100...1000)
                        return (dividend, divisor)
                    },
                    accept: { $0.0 % $0.1 != 0 }
                )
                return MathProblem(operand1: d, operand2: div, operation: .divide, correctAnswer: d / div)
            }
        ))

        return skills
    }
}

// MARK: - Local helpers

@inline(__always)
private func hasNoCarry(_ a: Int, _ b: Int) -> Bool {
    var x = a, y = b
    while x > 0 || y > 0 {
        if (x % 10) + (y % 10) >= 10 { return false }
        x /= 10; y /= 10
    }
    return true
}

@inline(__always)
private func hasNoBorrow(_ a: Int, _ b: Int) -> Bool {
    var x = a, y = b
    while y > 0 {
        if (x % 10) < (y % 10) { return false }
        x /= 10; y /= 10
    }
    return true
}

private func retryPair<A, B>(
    maxAttempts: Int = 200,
    gen: () -> (A, B),
    accept: ((A, B)) -> Bool
) -> (A, B) {
    var last = gen()
    if accept(last) { return last }
    for _ in 0..<maxAttempts {
        last = gen()
        if accept(last) { return last }
    }
    return last
}

private func retryTriple<A, B, C>(
    maxAttempts: Int = 200,
    gen: () -> (A, B, C),
    accept: ((A, B, C)) -> Bool
) -> (A, B, C) {
    var last = gen()
    if accept(last) { return last }
    for _ in 0..<maxAttempts {
        last = gen()
        if accept(last) { return last }
    }
    return last
}
