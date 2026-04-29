import Foundation
import SwiftData

@Model
final class AppSettings {
    var countingRange: Int = 20
    var operationsRaw: [String] = ["+"]
    var examplesPerPage: Int = 5
    var deadlineSeconds: Int = 60
    var themeRaw: String = "dinosaur"
    var appearanceModeRaw: String = "system"
    var languageRaw: String = "en"
    var customEmojiRaw: String = "⭐"
    var hasDiscoveredChallenge: Bool = false
    var challengeWins: Int = 0
    var createdAt: Date = Date()
    var isUnlocked: Bool = false

    /// Whether the kid uses Guided mode (adaptive plan, hints) when a subscription
    /// is active. NOT a substitute for the live `StoreManager.isGuidedActive`
    /// entitlement — it's a UX preference layered on top of it. Defaults to ON
    /// after a successful subscription per GUIDED_LEARNING_DEV_PLAN.md §3.5.
    var guidedModeEnabled: Bool = true

    /// One-time flag so the post-purchase onboarding sheet only shows once.
    var hasSeenGuidedOnboarding: Bool = false

    // MARK: - Curriculum (skill-graph rewrite)

    /// Parent-declared age (5–10). Used as a starting estimate when no school
    /// grade is provided.
    var kidAge: Int = 6

    /// Parent-declared school grade (1–5). 0 = none/preschool.
    var schoolGradeRaw: Int = 0

    /// Set after the placement warmup completes for the first time. While
    /// false, opening the Guide tab routes to the onboarding flow.
    var placementCompleted: Bool = false

    /// Stable Skill.id of the current focus skill. Empty until placement runs.
    var activeSkillID: String = ""

    init() {}

    var operations: Set<MathOperation> {
        get {
            Set(operationsRaw.compactMap { MathOperation(rawValue: $0) })
        }
    }

    func toggleOperation(_ op: MathOperation) {
        if operationsRaw.contains(op.rawValue) {
            if operationsRaw.count > 1 {
                operationsRaw.removeAll { $0 == op.rawValue }
            }
        } else {
            operationsRaw.append(op.rawValue)
        }
    }

    var difficultyKey: String {
        let ops = operationsRaw.sorted().joined()
        return "\(countingRange)_\(ops)_\(examplesPerPage)"
    }

    var difficultyDisplayName: String {
        let ops = operationsRaw.sorted().joined(separator: " ")
        return loc("To") + " \(countingRange), \(ops), \(examplesPerPage) " + loc("per page")
    }
}
