import Foundation
import SwiftUI
import Combine

@Observable
class PracticeViewModel {
    enum PracticeState {
        case ready
        case inProgress
        case finished
    }

    var state: PracticeState = .ready
    var problems: [MathProblem] = []
    var answers: [UUID: String] = [:]
    var results: [UUID: Bool] = [:]
    var isNegative: [UUID: Bool] = [:]
    var elapsedSeconds: Double = 0
    var deadlineSeconds: Int = 0
    var errorCount: Int = 0
    var showDeadlineExpired: Bool = false

    private var timer: Timer?
    private var startTime: Date?

    var isAllAnswered: Bool {
        problems.allSatisfy { problem in
            let answer = answers[problem.id, default: ""]
            return !answer.isEmpty
        }
    }

    var timeString: String {
        let mins = Int(elapsedSeconds) / 60
        let secs = Int(elapsedSeconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    var deadlineProgress: Double {
        guard deadlineSeconds > 0 else { return 0 }
        return min(elapsedSeconds / Double(deadlineSeconds), 1.0)
    }

    var remainingSeconds: Int {
        guard deadlineSeconds > 0 else { return 0 }
        return max(0, deadlineSeconds - Int(elapsedSeconds))
    }

    func startPractice(settings: AppSettings) {
        problems = ProblemGenerator.generate(
            count: settings.examplesPerPage,
            range: settings.countingRange,
            operations: settings.operations
        )
        answers = [:]
        results = [:]
        isNegative = [:]
        elapsedSeconds = 0
        errorCount = 0
        deadlineSeconds = settings.deadlineSeconds
        showDeadlineExpired = false
        state = .inProgress
        startTime = Date()

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.startTime else { return }
            self.elapsedSeconds = Date().timeIntervalSince(start)

            if self.deadlineSeconds > 0 && self.elapsedSeconds >= Double(self.deadlineSeconds) {
                self.showDeadlineExpired = true
                self.finishPractice()
            }
        }
    }

    func toggleNegative(for problemId: UUID) {
        isNegative[problemId, default: false].toggle()
    }

    func getAnswer(for problemId: UUID) -> Int? {
        guard let text = answers[problemId], !text.isEmpty else { return nil }
        guard let absValue = Int(text) else { return nil }
        return isNegative[problemId, default: false] ? -absValue : absValue
    }

    func checkAnswer(for problem: MathProblem) {
        if let answer = getAnswer(for: problem.id) {
            results[problem.id] = answer == problem.correctAnswer
        }
    }

    func submitAll() {
        for problem in problems {
            if results[problem.id] == nil {
                if let answer = getAnswer(for: problem.id) {
                    results[problem.id] = answer == problem.correctAnswer
                } else {
                    results[problem.id] = false
                }
            }
        }
        finishPractice()
    }

    func finishPractice() {
        timer?.invalidate()
        timer = nil
        errorCount = results.values.filter { !$0 }.count
        state = .finished
    }

    func reset() {
        timer?.invalidate()
        timer = nil
        state = .ready
        problems = []
        answers = [:]
        results = [:]
        isNegative = [:]
        elapsedSeconds = 0
        errorCount = 0
        showDeadlineExpired = false
    }
}
