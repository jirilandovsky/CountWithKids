import SwiftUI
import SwiftData
import UIKit

struct PracticeView: View {
    @Environment(\.appTheme) var theme
    @Environment(\.modelContext) private var modelContext
    @Bindable var settings: AppSettings
    @State private var viewModel = PracticeViewModel()
    @FocusState private var focusedProblemId: UUID?
    @State private var showScanner = false
    @State private var scanProblems: [MathProblem]?
    @State private var scanDetectedAnswers: [Int?]?
    @State private var showScanResult = false
    @State private var showScanError = false

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

            HStack(spacing: 16) {
                Button {
                    printPracticePage()
                } label: {
                    Label(loc("Print"), systemImage: "printer")
                }
                .buttonStyle(PlayfulButtonStyle(color: theme.accentColor))

                Button {
                    showScanner = true
                } label: {
                    Label(loc("Scan"), systemImage: "doc.viewfinder")
                }
                .buttonStyle(PlayfulButtonStyle(color: theme.secondaryColor))
            }

            Spacer()
        }
        .padding()
        .sheet(isPresented: $showScanner) {
            ScannerView(
                onScanCompleted: { images in
                    processScan(images: images)
                },
                onCancelled: {
                    showScanner = false
                }
            )
        }
        .sheet(isPresented: $showScanResult) {
            if let problems = scanProblems {
                ScanResultView(
                    problems: problems,
                    detectedAnswers: scanDetectedAnswers ?? Array(repeating: nil, count: problems.count),
                    settings: settings,
                    onDismiss: {
                        showScanResult = false
                        scanProblems = nil
                        scanDetectedAnswers = nil
                    }
                )
            }
        }
        .alert(loc("Could not read the printed page. Make sure the QR code is visible."), isPresented: $showScanError) {
            Button(loc("OK"), role: .cancel) { }
        }
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
            ScrollViewReader { proxy in
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
                            .id(problem.id)
                            .focused($focusedProblemId, equals: problem.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: focusedProblemId) { _, newId in
                    guard let newId else { return }
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo(newId, anchor: .top)
                    }
                }
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

    private func printPracticePage() {
        let problems = ProblemGenerator.generate(
            count: settings.examplesPerPage,
            range: settings.countingRange,
            operations: settings.operations
        )
        let renderer = PrintablePageRenderer(
            problems: problems,
            settings: settings,
            title: loc("Math Practice")
        )
        let pdfData = renderer.generatePDF()

        let printController = UIPrintInteractionController.shared
        printController.printingItem = pdfData

        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = loc("Math Practice")
        printInfo.outputType = .general
        printController.printInfo = printInfo

        printController.present(animated: true)
    }

    private func processScan(images: [UIImage]) {
        Task {
            if let result = await ScanEvaluator.evaluate(images: images) {
                await MainActor.run {
                    scanProblems = result.problems
                    scanDetectedAnswers = result.detectedAnswers
                    showScanResult = true
                }
            } else {
                await MainActor.run {
                    showScanError = true
                }
            }
        }
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
