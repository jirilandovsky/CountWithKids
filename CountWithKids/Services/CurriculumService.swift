import Foundation
import SwiftData

// Drives the skill-graph progression for the Guided Learning tier.
//
// Replaces MasteryService (per-operation L1–L10). A skill is considered
// "mastered" once the kid completes `masteryThreshold` consecutive clean
// sheets at it. Mastered skills:
//   • stop blocking progression (their dependents become reachable),
//   • keep showing up in Warmup / Challenge cards as review.
//
// Rules in plain Czech-friendly terms:
//   • 5 čistých konteček v řadě → dovednost zvládnutá.
//   • Chyba kdykoli → counter zpět na 0.
//   • Zvládnutí dovednosti odemkne další skill(y) podle prerequisites.
struct CurriculumService {
    static let masteryThreshold = 5  // consecutive clean sheets

    enum Outcome: Equatable {
        case noChange
        case progress              // clean sheet, but not yet mastered
        case mastered(skillID: String, gradeCompleted: CzechGrade?)
    }

    /// Records the result of a guided session at the given skill.
    @discardableResult
    static func recordResult(
        skillID: String,
        errorCount: Int,
        in context: ModelContext,
        now: Date = Date()
    ) -> Outcome {
        let row = fetchOrCreate(skillID: skillID, in: context)
        row.lastPracticedAt = now

        guard errorCount == 0 else {
            row.consecutiveCleanSheets = 0
            return .noChange
        }
        // Already mastered — keep counting clean sheets but don't re-trigger
        // the celebration.
        if row.isCompleted {
            row.consecutiveCleanSheets += 1
            return .progress
        }
        row.consecutiveCleanSheets += 1
        guard row.consecutiveCleanSheets >= masteryThreshold else {
            return .progress
        }

        row.isCompleted = true
        row.consecutiveCleanSheets = masteryThreshold

        // Did the kid finish a whole grade?
        let grade = SkillCatalog.skill(skillID)?.grade
        let completedGrade = grade.flatMap { isGradeComplete($0, in: context) ? $0 : nil }
        return .mastered(skillID: skillID, gradeCompleted: completedGrade)
    }

    /// True when every skill of a grade is completed.
    static func isGradeComplete(_ grade: CzechGrade, in context: ModelContext) -> Bool {
        let ids = SkillCatalog.skills(in: grade).map(\.id)
        let mastered = masteredSkillIDs(in: context)
        return ids.allSatisfy { mastered.contains($0) }
    }

    /// All skills the kid has mastered, as a Set of IDs.
    static func masteredSkillIDs(in context: ModelContext) -> Set<String> {
        let descriptor = FetchDescriptor<SkillProgress>(
            predicate: #Predicate { $0.isCompleted }
        )
        let rows = (try? context.fetch(descriptor)) ?? []
        return Set(rows.map(\.skillID))
    }

    /// Skills whose prerequisites are all mastered (reachable next steps).
    static func unlockedSkills(in context: ModelContext) -> [Skill] {
        let mastered = masteredSkillIDs(in: context)
        return SkillCatalog.allSkills.filter { skill in
            // Mastered skills are always "reachable" (for review).
            if mastered.contains(skill.id) { return true }
            return skill.prerequisites.allSatisfy { mastered.contains($0) }
        }
    }

    /// First non-mastered skill the kid can work on right now. Used as the
    /// fallback when AppSettings.activeSkillID is empty or stale.
    static func nextActiveSkill(in context: ModelContext) -> Skill {
        let mastered = masteredSkillIDs(in: context)
        for skill in SkillCatalog.allSkills {
            if mastered.contains(skill.id) { continue }
            if skill.prerequisites.allSatisfy({ mastered.contains($0) }) {
                return skill
            }
        }
        // Everything mastered — stay on the very last skill for review.
        return SkillCatalog.allSkills.last ?? SkillCatalog.allSkills[0]
    }

    /// Resolves the current active skill, repairing AppSettings if it's empty
    /// or points at a now-mastered skill.
    static func currentActiveSkill(settings: AppSettings, in context: ModelContext) -> Skill {
        if let s = SkillCatalog.skill(settings.activeSkillID),
           !masteredSkillIDs(in: context).contains(s.id) {
            return s
        }
        let next = nextActiveSkill(in: context)
        settings.activeSkillID = next.id
        return next
    }

    /// Read-only view of one skill's progress. Inserts the row on first use.
    static func progress(for skillID: String, in context: ModelContext) -> SkillProgress {
        fetchOrCreate(skillID: skillID, in: context)
    }

    /// Fraction (0.0 ... 1.0) of mastered skills in the kid's current grade.
    static func gradeCompletionRatio(_ grade: CzechGrade, in context: ModelContext) -> Double {
        let skills = SkillCatalog.skills(in: grade)
        guard !skills.isEmpty else { return 0 }
        let mastered = masteredSkillIDs(in: context)
        let done = skills.filter { mastered.contains($0.id) }.count
        return Double(done) / Double(skills.count)
    }

    /// Best estimate of the grade the kid is currently working in (the grade
    /// of their first non-mastered skill).
    static func currentGrade(in context: ModelContext) -> CzechGrade {
        nextActiveSkill(in: context).grade
    }

    // MARK: - Private

    static func fetchOrCreate(skillID: String, in context: ModelContext) -> SkillProgress {
        let id = skillID
        let descriptor = FetchDescriptor<SkillProgress>(
            predicate: #Predicate { $0.skillID == id }
        )
        if let existing = (try? context.fetch(descriptor))?.first {
            return existing
        }
        let row = SkillProgress(skillID: skillID)
        context.insert(row)
        return row
    }
}
