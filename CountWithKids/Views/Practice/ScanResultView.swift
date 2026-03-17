import SwiftUI
import SwiftData

struct ScanResultView: View {
    @Environment(\.appTheme) var theme
    @Environment(\.modelContext) private var modelContext
    let problems: [MathProblem]
    let settings: AppSettings
    @State private var answers: [String]
    @State private var evaluated = false
    let onDismiss: () -> Void

    init(problems: [MathProblem], detectedAnswers: [Int?], settings: AppSettings, onDismiss: @escaping () -> Void) {
        self.problems = problems
        self.settings = settings
        self.onDismiss = onDismiss
        _answers = State(initialValue: detectedAnswers.map { val in
            val.map(String.init) ?? ""
        })
    }

    private var errorCount: Int {
        zip(problems, answers).filter { problem, answer in
            guard let num = Int(answer) else { return true }
            return num != problem.correctAnswer
        }.count
    }

    private var isCleanSheet: Bool { evaluated && errorCount == 0 }

    var body: some View {
        if evaluated {
            resultsSummary
        } else {
            answersReview
        }
    }

    private var answersReview: some View {
        VStack(spacing: 16) {
            HStack {
                Button(loc("Cancel")) { onDismiss() }
                    .foregroundColor(theme.primaryColor)
                Spacer()
            }
            .padding(.horizontal)

            Text(loc("Review answers"))
                .playfulFont(size: 20)
                .foregroundColor(theme.primaryColor)

            Text(loc("Correct any answers the scanner may have misread"))
                .playfulFont(size: 14, weight: .regular)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Array(problems.enumerated()), id: \.element.id) { index, problem in
                        answerRow(index: index, problem: problem)
                    }
                }
                .padding(.vertical)
            }

            Button(loc("Evaluate")) {
                withAnimation { evaluated = true }
                saveSession()
            }
            .buttonStyle(PlayfulButtonStyle())
            .padding(.bottom, 24)
        }
    }

    private func answerRow(index: Int, problem: MathProblem) -> some View {
        HStack(spacing: 12) {
            Text("\(index + 1).")
                .playfulFont(size: 16, weight: .medium)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .trailing)

            Text(problem.displayString)
                .playfulFont(size: 20)

            TextField("?", text: $answers[index])
                .keyboardType(.numberPad)
                .frame(width: 70)
                .multilineTextAlignment(.center)
                .playfulFont(size: 20)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.cardBackgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.primaryColor, lineWidth: 1)
                )

            Spacer()
        }
        .padding(.horizontal)
    }

    private var resultsSummary: some View {
        VStack(spacing: 24) {
            Spacer()

            Text(isCleanSheet ? theme.celebrationEmoji : theme.mascotEmoji)
                .font(.system(size: 80))

            if isCleanSheet {
                Text(loc("Clean Sheet!"))
                    .playfulFont(size: 32)
                    .foregroundColor(theme.accentColor)
            }

            // Results list
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(Array(problems.enumerated()), id: \.element.id) { index, problem in
                        resultRow(index: index, problem: problem)
                    }
                }
                .padding(.vertical)
            }

            // Summary card
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(theme.primaryColor)
                        .frame(width: 30)
                    Text(loc("Errors"))
                        .playfulFont(size: 18, weight: .medium)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(errorCount) / \(problems.count)")
                        .playfulFont(size: 22)
                        .monospacedDigit()
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.cardBackgroundColor)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .padding(.horizontal)

            Button(loc("Done")) { onDismiss() }
                .buttonStyle(PlayfulButtonStyle(color: theme.secondaryColor))
                .padding(.bottom, 32)
        }
        .padding()
    }

    private func saveSession() {
        let session = PracticeSession(
            duration: 0,
            errors: errorCount,
            total: problems.count,
            settings: settings
        )
        modelContext.insert(session)
    }

    private func resultRow(index: Int, problem: MathProblem) -> some View {
        let answer = Int(answers[index])
        let correct = answer == problem.correctAnswer

        return HStack(spacing: 12) {
            Text("\(index + 1).")
                .playfulFont(size: 16, weight: .medium)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .trailing)

            Text(problem.displayString)
                .playfulFont(size: 18)

            Text(answers[index].isEmpty ? "—" : answers[index])
                .playfulFont(size: 18)
                .foregroundColor(correct ? .green : .red)

            if !correct {
                Text("(\(problem.correctAnswer))")
                    .playfulFont(size: 16, weight: .medium)
                    .foregroundColor(.green)
            }

            Spacer()

            Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(correct ? .green : .red)
        }
        .padding(.horizontal)
    }
}
