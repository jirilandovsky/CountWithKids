import Foundation
import SwiftUI

@Observable
class ChallengeViewModel {
    enum ChallengeState: Equatable {
        case prompt
        case racing
        case finished
    }

    enum ChallengeResult: Equatable {
        case playerWins
        case mascotWins
    }

    static let problemCount = 5

    var state: ChallengeState = .prompt
    var problems: [MathProblem] = []
    var currentProblemIndex: Int = 0
    var playerSolved: Int = 0
    var mascotSolved: Int = 0
    var currentAnswer: String = ""
    var isCurrentNegative: Bool = false
    var lastAnswerCorrect: Bool?
    var playerResults: [Bool] = []
    var result: ChallengeResult?
    var elapsedSeconds: Double = 0
    var playerFinishTime: Double?
    var mascotFinishTime: Double?
    /// Index for rotating encouraging messages (randomized per race)
    var messageIndex: Int = 0

    private var mascotTimer: Timer?
    private var clockTimer: Timer?
    private var startTime: Date?
    private var mascotInterval: TimeInterval = 5.0

    var currentProblem: MathProblem? {
        guard currentProblemIndex < problems.count else { return nil }
        return problems[currentProblemIndex]
    }

    /// Total time the mascot needs to finish all problems.
    var mascotTotalTime: Double {
        mascotInterval * Double(Self.problemCount)
    }

    /// Countdown: mascot total time minus elapsed, floored at 0.
    var countdownSeconds: Double {
        max(0, mascotTotalTime - elapsedSeconds)
    }

    var countdownString: String {
        let total = Int(ceil(countdownSeconds))
        let mins = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", mins, secs)
    }

    func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        let tenths = Int((seconds - Double(Int(seconds))) * 10)
        return String(format: "%d:%02d.%d", mins, secs, tenths)
    }

    var playerFinished: Bool {
        currentProblemIndex >= Self.problemCount
    }

    func startRace(settings: AppSettings) {
        problems = ProblemGenerator.generate(
            count: Self.problemCount,
            range: settings.countingRange,
            operations: settings.operations
        )
        currentProblemIndex = 0
        playerSolved = 0
        mascotSolved = 0
        currentAnswer = ""
        isCurrentNegative = false
        lastAnswerCorrect = nil
        playerResults = []
        result = nil
        elapsedSeconds = 0
        playerFinishTime = nil
        mascotFinishTime = nil
        messageIndex = Int.random(in: 0..<10)

        mascotInterval = Self.mascotSpeed(
            range: settings.countingRange,
            operations: settings.operations
        )

        state = .racing
        startTime = Date()

        clockTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self, let start = self.startTime else { return }
            self.elapsedSeconds = Date().timeIntervalSince(start)

            // When time is up and player hasn't finished, mark remaining as wrong
            if self.elapsedSeconds >= self.mascotTotalTime && !self.playerFinished {
                self.autoFailRemaining()
            }
        }

        scheduleMascotStep()
    }

    func submitAnswer() {
        guard let problem = currentProblem else { return }

        let parsedAnswer: Int? = {
            guard !currentAnswer.isEmpty, let absValue = Int(currentAnswer) else { return nil }
            return isCurrentNegative ? -absValue : absValue
        }()

        let correct = parsedAnswer == problem.correctAnswer
        lastAnswerCorrect = correct
        playerResults.append(correct)

        if correct {
            playerSolved += 1
        }

        currentProblemIndex += 1
        currentAnswer = ""
        isCurrentNegative = false

        // Record player finish time when all problems answered
        if currentProblemIndex >= Self.problemCount && playerFinishTime == nil {
            playerFinishTime = elapsedSeconds
        }

        checkForFinish()
    }

    func toggleNegative() {
        isCurrentNegative.toggle()
    }

    func reset() {
        mascotTimer?.invalidate()
        clockTimer?.invalidate()
        mascotTimer = nil
        clockTimer = nil
        state = .prompt
        problems = []
        currentProblemIndex = 0
        playerSolved = 0
        mascotSolved = 0
        currentAnswer = ""
        isCurrentNegative = false
        lastAnswerCorrect = nil
        playerResults = []
        result = nil
        elapsedSeconds = 0
        playerFinishTime = nil
        mascotFinishTime = nil
        messageIndex = 0
    }

    /// When time runs out, fill all remaining player answers as wrong.
    private func autoFailRemaining() {
        while currentProblemIndex < Self.problemCount {
            playerResults.append(false)
            currentProblemIndex += 1
        }
        playerFinishTime = elapsedSeconds
        currentAnswer = ""
        isCurrentNegative = false
        checkForFinish()
    }

    // MARK: - Mascot AI

    private func scheduleMascotStep() {
        mascotTimer?.invalidate()
        mascotTimer = Timer.scheduledTimer(withTimeInterval: mascotInterval, repeats: false) { [weak self] _ in
            guard let self, self.state == .racing else { return }
            self.mascotSolved += 1

            // Record mascot finish time when all solved
            if self.mascotSolved >= Self.problemCount && self.mascotFinishTime == nil {
                self.mascotFinishTime = self.elapsedSeconds
            }

            if !self.checkForFinish() {
                if self.mascotSolved < Self.problemCount {
                    self.scheduleMascotStep()
                }
            }
        }
    }

    @discardableResult
    private func checkForFinish() -> Bool {
        let bothFinished = playerFinished && mascotSolved >= Self.problemCount

        guard bothFinished else { return false }

        // Determine result:
        // Kid must have ALL correct AND be faster to win
        let playerPerfect = playerResults.allSatisfy { $0 }

        let outcome: ChallengeResult
        if playerPerfect, let pTime = playerFinishTime, let mTime = mascotFinishTime, pTime < mTime {
            outcome = .playerWins
        } else {
            outcome = .mascotWins
        }

        // Small delay so the UI can render the last checkmark before transitioning
        clockTimer?.invalidate()
        clockTimer = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.finish(result: outcome)
        }
        return true
    }

    private func finish(result: ChallengeResult) {
        self.result = result
        mascotTimer?.invalidate()
        clockTimer?.invalidate()
        mascotTimer = nil
        clockTimer = nil
        state = .finished
    }

    // MARK: - Speed calibration

    static func mascotSpeed(range: Int, operations: Set<MathOperation>) -> TimeInterval {
        let base: TimeInterval = switch range {
        case ...10: 4.0
        case ...20: 6.0
        case ...100: 9.0
        default: 13.0
        }

        let hasOnlyAddition = operations == [.add]
        let hasDivision = operations.contains(.divide)
        let hasMultiplication = operations.contains(.multiply)

        var multiplier = 1.0
        if hasOnlyAddition { multiplier = 0.85 }
        else if hasDivision { multiplier = 1.15 }
        else if hasMultiplication { multiplier = 1.1 }

        return base * multiplier * 1.3
    }
}
