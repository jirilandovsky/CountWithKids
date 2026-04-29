import Foundation
import SwiftData

// One row per Skill.id (`SkillCatalog.allSkills`). Tracks how close the kid
// is to mastering that skill and whether it's already complete.
//
// Owned by CurriculumService — UI should treat fields as read-only.
@Model
final class SkillProgress {
    /// Stable Skill.id — see SkillCatalog. Unique per catalog entry.
    @Attribute(.unique) var skillID: String = ""

    /// Resets to 0 when the kid makes any error.
    var consecutiveCleanSheets: Int = 0

    /// Becomes true when `consecutiveCleanSheets` first hits the mastery
    /// threshold. Stays true after that — completed skills are still pulled
    /// into Warmup / Challenge cards (review), they just stop blocking
    /// progression.
    var isCompleted: Bool = false

    var lastPracticedAt: Date = Date.distantPast

    init() {}

    init(skillID: String) {
        self.skillID = skillID
    }
}
