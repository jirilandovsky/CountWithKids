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
}
