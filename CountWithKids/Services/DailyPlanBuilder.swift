import Foundation
import SwiftData

// Builds today's three guided sessions from the curriculum graph.
//
// Rewritten from the per-operation L1–L10 design. Now skill-graph driven:
//   • Warmup   = previously-mastered skill in the same family/area as Focus
//                (build confidence on something the kid already knows).
//   • Focus    = the currently-active skill (the one being worked on).
//   • Challenge = mixed review of mastered skills, OR — if everything in the
//                 active skill's grade is mastered — the next skill ahead
//                 as a stretch goal.
//
// Skippable. Deterministic per-day so the kid sees the same plan if they
// come back later in the day.
enum DailyPlanBuilder {
    enum Slot: String, CaseIterable, Codable {
        case warmup, focus, challenge
    }

    struct Card: Equatable, Identifiable {
        let slot: Slot
        /// Localized short label of the activity (e.g. "+ do 20 bez přechodu").
        let label: String
        /// Skills to draw problems from. One element for warmup/focus,
        /// multiple for challenge (mixed review).
        let skillIDs: [String]
        let problemCount: Int

        var id: String { slot.rawValue }
    }

    struct Plan: Equatable {
        let date: Date
        let warmup: Card
        let focus: Card
        let challenge: Card

        var cards: [Card] { [warmup, focus, challenge] }
    }

    static let problemsPerSession = 5

    /// Pure builder. The caller resolves the active skill and the mastered
    /// set (from CurriculumService) before calling this so the function stays
    /// testable without a SwiftData context.
    static func build(
        activeSkill: Skill,
        masteredSkillIDs: Set<String>,
        today: Date = Date(),
        calendar: Calendar = .current
    ) -> Plan {
        let warmup = warmupCard(for: activeSkill, mastered: masteredSkillIDs)
        let focus = focusCard(for: activeSkill)
        let challenge = challengeCard(for: activeSkill, mastered: masteredSkillIDs)
        return Plan(
            date: calendar.startOfDay(for: today),
            warmup: warmup,
            focus: focus,
            challenge: challenge
        )
    }

    // MARK: - Slot composition

    private static func focusCard(for skill: Skill) -> Card {
        Card(slot: .focus, label: skill.localizedLabel, skillIDs: [skill.id], problemCount: problemsPerSession)
    }

    /// Warmup is *easier* than Focus — designed to build confidence.
    ///   1. If the kid has mastered something with the same primary operation,
    ///      pick the most recent of those.
    ///   2. Otherwise, fall back to the catalog neighbor one step before the
    ///      active skill (a preview of what the kid is about to leave behind,
    ///      or the catalog floor if active is the very first skill).
    private static func warmupCard(for active: Skill, mastered: Set<String>) -> Card {
        if let op = active.primaryOperation {
            // Exclude the active skill itself — otherwise Warmup ends up
            // identical to Focus (active can land in `mastered` mid-advance).
            let sameOp = SkillCatalog.allSkills.filter {
                $0.id != active.id
                    && mastered.contains($0.id)
                    && $0.primaryOperation == op
            }
            if let pick = sameOp.last {
                return Card(slot: .warmup, label: pick.localizedLabel, skillIDs: [pick.id], problemCount: problemsPerSession)
            }
        }
        // No same-op mastery — step back one skill from the active one.
        let prev = SkillCatalog.neighbor(of: active.id, offset: -1) ?? active
        return Card(slot: .warmup, label: prev.localizedLabel, skillIDs: [prev.id], problemCount: problemsPerSession)
    }

    /// Challenge is *harder* than Focus — a glimpse ahead.
    ///   1. If the kid has 2+ mastered skills, mix the last few as review.
    ///   2. Otherwise, take the next skill in catalog order as a preview
    ///      (stretch goal). For a brand-new kid this surfaces the level
    ///      *after* their active skill — never the same skill as Focus.
    private static func challengeCard(for active: Skill, mastered: Set<String>) -> Card {
        // Exclude the active skill from the review pool so Challenge never
        // duplicates Focus, even if active.id sits in `mastered`.
        let masteredSkills = SkillCatalog.allSkills.filter {
            $0.id != active.id && mastered.contains($0.id)
        }
        let recent = Array(masteredSkills.suffix(4))
        if recent.count >= 2 {
            return Card(
                slot: .challenge,
                label: loc("Mixed"),
                skillIDs: recent.map(\.id),
                problemCount: problemsPerSession
            )
        }
        // Stretch goal: next skill in catalog order, with active.id banned so
        // we never duplicate Focus.
        let next = SkillCatalog.neighbor(of: active.id, offset: 1) ?? active
        let ahead = next.id == active.id
            ? (SkillCatalog.neighbor(of: active.id, offset: -1) ?? active)
            : next
        return Card(slot: .challenge, label: ahead.localizedLabel, skillIDs: [ahead.id], problemCount: problemsPerSession)
    }
}

// MARK: - Convenience that talks to SwiftData

extension DailyPlanBuilder {
    /// Builds a plan from the live SwiftData state. UI layer entrypoint.
    static func build(settings: AppSettings, in context: ModelContext, today: Date = Date()) -> Plan {
        let active = CurriculumService.currentActiveSkill(settings: settings, in: context)
        let mastered = CurriculumService.masteredSkillIDs(in: context)
        return build(activeSkill: active, masteredSkillIDs: mastered, today: today)
    }
}
