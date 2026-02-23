import SwiftUI
import SwiftData

struct PracticeView: View {
    @Environment(\.appTheme) var theme
    @Environment(\.modelContext) private var modelContext
    @Bindable var settings: AppSettings
    @State private var viewModel = PracticeViewModel()
    @FocusState private var focusedProblemId: UUID?

    var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundColor.ignoresSafeArea()

                switch viewModel.state {
                case .ready:
                    readyView
                case .inProgress:
                    inProgressView
                case .finished:
                    PracticeResultView(
                        viewModel: viewModel,
                        settings: settings,
                        onSaveAndRestart: saveAndRestart,
                        onSaveAndFinish: saveAndFinish
                    )
                }
            }
            .navigationTitle(loc("Practice"))
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var readyView: some View {
        VStack(spacing: 24) {
            Spacer()

            Text(theme.mascotEmoji)
                .font(.system(size: 100))

            Text(loc("Ready to practice?"))
                .playfulFont(size: 28)
                .foregroundColor(theme.primaryColor)

            VStack(spacing: 8) {
                Text(settings.difficultyDisplayName)
                    .playfulFont(size: 16, weight: .medium)
                    .foregroundColor(.secondary)

                if settings.deadlineSeconds > 0 {
                    Text(loc("Time limit:") + " \(settings.deadlineSeconds)s")
                        .playfulFont(size: 14, weight: .regular)
                        .foregroundColor(.secondary)
                }
            }

            Button(loc("Start!")) {
                viewModel.startPractice(settings: settings)
                // Auto-focus the first problem after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if let firstId = viewModel.problems.first?.id {
                        focusedProblemId = firstId
                    }
                }
            }
            .buttonStyle(PlayfulButtonStyle())

            Spacer()
        }
        .padding()
    }

    private var inProgressView: some View {
        VStack(spacing: 0) {
            // Timer header
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(theme.primaryColor)
                Text(viewModel.timeString)
                    .playfulFont(size: 22)
                    .foregroundColor(theme.primaryColor)
                    .monospacedDigit()

                Spacer()

                if viewModel.deadlineSeconds > 0 {
                    Text("\(viewModel.remainingSeconds) " + loc("s left"))
                        .playfulFont(size: 16)
                        .foregroundColor(viewModel.deadlineProgress > 0.8 ? theme.secondaryColor : .secondary)
                }
            }
            .padding()

            if viewModel.deadlineSeconds > 0 {
                ProgressView(value: viewModel.deadlineProgress)
                    .tint(viewModel.deadlineProgress > 0.8 ? theme.secondaryColor : theme.primaryColor)
                    .padding(.horizontal)
            }

            // Problems list
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Array(viewModel.problems.enumerated()), id: \.element.id) { index, problem in
                        ProblemRowView(
                            problem: problem,
                            index: index + 1,
                            answer: Binding(
                                get: { viewModel.answers[problem.id, default: ""] },
                                set: { viewModel.answers[problem.id] = $0 }
                            ),
                            isNegative: viewModel.isNegative[problem.id, default: false],
                            isFocused: focusedProblemId == problem.id,
                            result: viewModel.results[problem.id],
                            onToggleNegative: { viewModel.toggleNegative(for: problem.id) },
                            onSubmit: {
                                viewModel.checkAnswer(for: problem)
                                // Auto-advance to next problem
                                if index + 1 < viewModel.problems.count {
                                    focusedProblemId = viewModel.problems[index + 1].id
                                }
                            },
                            onFocus: { focusedProblemId = problem.id }
                        )
                        .focused($focusedProblemId, equals: problem.id)
                    }
                }
                .padding()
            }

            // Submit button
            Button(loc("Check All")) {
                focusedProblemId = nil
                viewModel.submitAll()
            }
            .buttonStyle(PlayfulButtonStyle(color: theme.secondaryColor))
            .padding()
        }
    }

    private func saveAndRestart() {
        saveSession()
        viewModel.startPractice(settings: settings)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let firstId = viewModel.problems.first?.id {
                focusedProblemId = firstId
            }
        }
    }

    private func saveAndFinish() {
        saveSession()
        focusedProblemId = nil
        viewModel.reset()
    }

    private func saveSession() {
        let session = PracticeSession(
            duration: viewModel.elapsedSeconds,
            errors: viewModel.errorCount,
            total: viewModel.problems.count,
            settings: settings
        )
        modelContext.insert(session)
    }
}
