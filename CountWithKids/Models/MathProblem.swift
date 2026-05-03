import Foundation

enum MathOperation: String, CaseIterable, Codable, Identifiable {
    case add = "+"
    case subtract = "-"
    case multiply = "*"
    case divide = "/"

    var id: String { rawValue }

    var symbol: String { rawValue }

    var localizedKey: String {
        switch self {
        case .add: return "operation.add"
        case .subtract: return "operation.subtract"
        case .multiply: return "operation.multiply"
        case .divide: return "operation.divide"
        }
    }
}

struct MathProblem: Identifiable {
    let id = UUID()
    let operand1: Int
    let operand2: Int
    let operation: MathOperation
    let correctAnswer: Int

    var displayString: String {
        "\(operand1) \(operation.symbol) \(operand2) ="
    }

    /// Spoken form for VoiceOver. Avoids the trailing "= ?" which reads as
    /// "equals question mark." Operator words come from Localizable.xcstrings
    /// so each language gets its own ("plus" / "plus" / "ועוד" etc).
    var spokenLabel: String {
        let op: String
        switch operation {
        case .add: op = loc("plus")
        case .subtract: op = loc("minus")
        case .multiply: op = loc("times")
        case .divide: op = loc("divided by")
        }
        return "\(operand1) \(op) \(operand2)"
    }
}
