import Foundation
import SwiftData

// Drives adaptive difficulty for the Guided Learning tier.
//
// Advancement rule (from GUIDED_LEARNING_DEV_PLAN.md §2.1):
//   • 3 consecutive clean sheets at the current level  →  level + 1
//   • 2 sessions with 3 or more errors                 →  level − 1
//   • Floor 1, ceiling 10
//
// Calls into SwiftData via the supplied ModelContext. Returns whether the
// level changed so callers can show celebrations.
struct MasteryService {
    static let levelUpThreshold = 3       // consecutive clean sheets
    static let levelDownThreshold = 2     // consecutive rough sessions
    static let roughSessionErrorCount = 3 // 3+ errors counts as a rough session

    enum Outcome: Equatable {
        case noChange
        case leveledUp(from: Int, to: Int)
        case leveledDown(from: Int, to: Int)
    }

    /// Records a guided practice result against a single operation. Inserts
    /// the MasteryProgress row on first use.
    @discardableResult
    static func recordResult(
        operation: MathOperation,
        errorCount: Int,
        in context: ModelContext,
        now: Date = Date()
    ) -> Outcome {
        let progress = fetchOrCreate(operation: operation, in: context)
        let previousLevel = progress.level
        progress.lastPracticedAt = now

        if errorCount == 0 {
            progress.consecutiveCleanSheets += 1
            progress.consecutiveRoughSessions = 0
            if progress.consecutiveCleanSheets >= levelUpThreshold && progress.level < LevelLadder.maxLevel {
                progress.level += 1
                progress.consecutiveCleanSheets = 0
                return .leveledUp(from: previousLevel, to: progress.level)
            }
        } else if errorCount >= roughSessionErrorCount {
            progress.consecutiveRoughSessions += 1
            progress.consecutiveCleanSheets = 0
            if progress.consecutiveRoughSessions >= levelDownThreshold && progress.level > LevelLadder.minLevel {
                progress.level -= 1
                progress.consecutiveRoughSessions = 0
                return .leveledDown(from: previousLevel, to: progress.level)
            }
        } else {
            // 1–2 errors: shaky session. Resets both counters — clean-sheet
            // streak must be consecutive, rough streak shouldn't carry through
            // a near-clean session.
            progress.consecutiveCleanSheets = 0
            progress.consecutiveRoughSessions = 0
        }

        return .noChange
    }

    /// Convenience used by guided home/UI: get current level for an operation,
    /// inserting a default row if none exists.
    static func currentLevel(for operation: MathOperation, in context: ModelContext) -> Int {
        fetchOrCreate(operation: operation, in: context).level
    }

    /// Returns all MasteryProgress rows, creating any missing ones for the four
    /// canonical operations. Used by GuidedHomeView and DailyPlanBuilder.
    static func allProgress(in context: ModelContext) -> [MasteryProgress] {
        for op in MathOperation.allCases {
            _ = fetchOrCreate(operation: op, in: context)
        }
        let descriptor = FetchDescriptor<MasteryProgress>()
        return (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Private

    static func fetchOrCreate(operation: MathOperation, in context: ModelContext) -> MasteryProgress {
        let raw = operation.rawValue
        let descriptor = FetchDescriptor<MasteryProgress>(
            predicate: #Predicate { $0.operationRaw == raw }
        )
        if let existing = (try? context.fetch(descriptor))?.first {
            return existing
        }
        let row = MasteryProgress(operation: operation)
        context.insert(row)
        return row
    }
}
