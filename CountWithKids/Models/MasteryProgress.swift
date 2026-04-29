import Foundation
import SwiftData

// One row per math operation. Tracks the kid's adaptive difficulty level
// and the rolling counters that drive level-up / level-down transitions.
//
// Owned by MasteryService. UI should treat fields as read-only.
@Model
final class MasteryProgress {
    /// Raw value of MathOperation: "+", "-", "*", "/".
    @Attribute(.unique) var operationRaw: String = "+"

    /// 1...10. Floor and ceiling enforced by MasteryService.
    var level: Int = 1

    /// Resets to 0 when the kid makes any error.
    var consecutiveCleanSheets: Int = 0

    /// "Rough" = a session with 3 or more errors. Resets when the kid recovers.
    var consecutiveRoughSessions: Int = 0

    var lastPracticedAt: Date = Date.distantPast

    init() {}

    init(operation: MathOperation, level: Int = 1) {
        self.operationRaw = operation.rawValue
        self.level = level
    }

    var operation: MathOperation {
        MathOperation(rawValue: operationRaw) ?? .add
    }
}
