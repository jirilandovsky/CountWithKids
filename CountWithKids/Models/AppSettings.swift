import Foundation
import SwiftData

@Model
final class AppSettings {
    var countingRange: Int = 20
    var operationsRaw: [String] = ["+"]
    var examplesPerPage: Int = 5
    var deadlineSeconds: Int = 60
    var themeRaw: String = "dinosaur"
    var languageRaw: String = "en"
    var createdAt: Date = Date()

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
