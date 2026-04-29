import SwiftUI
import SwiftData
import StoreKit
import UIKit

struct PracticeView: View {
    @Environment(\.appTheme) var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.requestReview) private var requestReview
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(StoreManager.self) private var store
    @Bindable var settings: AppSettings
    @State private var showPaywall = false
    @Query(sort: \PracticeSession.completedAt, order: .reverse) private var sessions: [PracticeSession]
    @State private var viewModel = PracticeViewModel()
    @FocusState private var focusedProblemId: UUID?
    @State private var showScanner = false
    @State private var scanProblems: [MathProblem]?
    @State private var scanDetectedAnswers: [Int?]?
    @State private var showScanError = false
    @State private var milestoneInfo: MilestoneInfo?
    @State private var showChallenge = false
    @State private var mascotWiggle = false
    @State private var mascotBreathing = false
    @State private var didFireDeadlineWarning = false

    private var showingScanResult: Bool {
        scanProblems != nil
    }

    /// Streak including the current (not yet saved) practice result.
    private var effectiveStreak: StreakResult {
        guard viewModel.state == .finished else {
            return StreakCalculator.compute(sessions: sessions)
        }
        let tempSession = PracticeSession(
            duration: viewModel.elapsedSeconds,
            errors: viewModel.errorCount,
            total: viewModel.problems.count,
            settings: settings
        )
        return StreakCalculator.compute(sessions: [tempSession] + sessions)
    }

    /// Returns milestone type if the current streak just hit a milestone (multiple of 5 or 10).
    private var milestoneAchievement: MilestoneType? {
        let streak = effectiveStreak.currentStreak
        guard streak > 0, viewModel.errorCount == 0 else { return nil }
        if streak.isMultiple(of: 10) { return .gold }
        if streak.isMultiple(of: 5) { return .silver }
        return nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundColor.ignoresSafeArea()

                if showingScanResult {
                    ScanResultView(
                        problems: scanProblems!,
                        detectedAnswers: scanDetectedAnswers ?? Array(repeating: nil, count: scanProblems!.count),
                        settings: settings,
                        onDismiss: {
                            scanProblems = nil
                            scanDetectedAnswers = nil
                        }
                    )
                } else {
                    if viewModel.state == .ready {
                        readyView
                    } else {
                        inProgressView
                    }
                }
            }
            .navigationTitle(viewModel.state == .inProgress || viewModel.state == .finished ? "" : loc(showingScanResult ? "Scan Results" : "Practice"))
            .navigationBarTitleDisplayMode(viewModel.state == .inProgress || viewModel.state == .finished ? .inline : .large)
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
            .alert(loc("Could not read the printed page. Make sure the QR code is visible."), isPresented: $showScanError) {
                Button(loc("OK"), role: .cancel) { }
            }
            .onChange(of: viewModel.state) { _, newState in
                if newState == .finished {
                    DispatchQueue.main.async {
                        if let type = milestoneAchievement {
                            milestoneInfo = MilestoneInfo(
                                type: type,
                                streak: effectiveStreak.currentStreak
                            )
                        }
                    }
                }
                if newState != .inProgress {
                    didFireDeadlineWarning = false
                }
            }
            .onChange(of: viewModel.deadlineProgress) { _, progress in
                guard viewModel.state == .inProgress, viewModel.deadlineSeconds > 0 else { return }
                if progress >= 0.8 && !didFireDeadlineWarning {
                    didFireDeadlineWarning = true
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
            .onChange(of: viewModel.showDeadlineExpired) { _, expired in
                if expired {
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                }
            }
            .fullScreenCover(item: $milestoneInfo) { info in
                MilestoneCelebrationView(
                    info: info,
                    onDismiss: {
                        milestoneInfo = nil
                    }
                )
                .environment(\.appTheme, theme)
            }
            .sheet(isPresented: $showPaywall) {
                // All paywall triggers in this view (mascot challenge, Print, Scan)
                // gate features tied to the one-time $3.99 unlock — never the
                // Guided subscription.
                PaywallView(settings: settings, store: store, focus: .fullUnlockOnly)
                    .environment(\.appTheme, theme)
            }
            .fullScreenCover(isPresented: $showChallenge) {
                ChallengeView(
                    settings: settings,
                    onDismiss: {
                        showChallenge = false
                    }
                )
                .environment(\.appTheme, theme)
            }
        }
    }

    private var readyView: some View {
        VStack(spacing: 24) {
            Spacer()

            Text(theme.mascotEmoji)
                .font(.system(size: 100))
                .scaleEffect(mascotBreathing ? 1.03 : 1.0)
                .animation(
                    reduceMotion
                        ? .default
                        : .easeInOut(duration: 2.4).repeatForever(autoreverses: true),
                    value: mascotBreathing
                )
                .rotationEffect(.degrees(mascotWiggle ? 8 : 0))
                .animation(
                    mascotWiggle
                        ? .easeInOut(duration: 0.15).repeatCount(5, autoreverses: true)
                        : .default,
                    value: mascotWiggle
                )
                .accessibilityLabel(loc("Mascot. Tap to race against the mascot."))
                .accessibilityAddTraits(.isButton)
                .onTapGesture {
                    if !settings.isUnlocked {
                        showPaywall = true
                        return
                    }
                    showChallenge = true
                    if !settings.hasDiscoveredChallenge {
                        settings.hasDiscoveredChallenge = true
                    }
                }
                .onAppear {
                    if !reduceMotion {
                        mascotBreathing = true
                    }
                    if !settings.hasDiscoveredChallenge && !reduceMotion {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            mascotWiggle = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                mascotWiggle = false
                            }
                        }
                    }
                }

            Text(loc("Ready to practice?"))
                .playfulFont(.title)
                .foregroundColor(theme.primaryColor)

            VStack(spacing: 8) {
                Text(settings.difficultyDisplayName)
                    .playfulFont(.callout, weight: .medium)
                    .foregroundColor(.secondary)

                if settings.deadlineSeconds > 0 {
                    Text(loc("Time limit:") + " \(settings.deadlineSeconds)s")
                        .playfulFont(.footnote, weight: .regular)
                        .foregroundColor(.secondary)
                }
            }

            StreakBannerView(streak: StreakCalculator.compute(sessions: sessions))
                .padding(.horizontal)

            Button(loc("Start!")) {
                viewModel.startPractice(settings: settings)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if let firstId = viewModel.problems.first?.id {
                        focusedProblemId = firstId
                    }
                }
            }
            .buttonStyle(PlayfulButtonStyle())

            HStack(spacing: 16) {
                Button {
                    if settings.isUnlocked {
                        printPracticePage()
                    } else {
                        showPaywall = true
                    }
                } label: {
                    Label(loc("Print"), systemImage: settings.isUnlocked ? "printer" : "lock.fill")
                }
                .buttonStyle(PlayfulButtonStyle(color: theme.accentColor))

                Button {
                    if settings.isUnlocked {
                        showScanner = true
                    } else {
                        showPaywall = true
                    }
                } label: {
                    Label(loc("Scan"), systemImage: settings.isUnlocked ? "doc.viewfinder" : "lock.fill")
                }
                .buttonStyle(PlayfulButtonStyle(color: theme.secondaryColor))
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: horizontalSizeClass == .regular ? 600 : .infinity)
        .frame(maxWidth: .infinity)
    }

    private var isCompactHeight: Bool {
        horizontalSizeClass == .regular
    }

    private var isFinished: Bool { viewModel.state == .finished }

    private var inProgressView: some View {
        VStack(spacing: 0) {
            // Header: timer or results summary
            if isFinished {
                finishedHeaderView
            } else {
                timerHeaderView
            }

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: isCompactHeight ? 8 : 12) {
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
                                isLocked: isFinished,
                                onToggleNegative: { viewModel.toggleNegative(for: problem.id) },
                                onSubmit: {
                                    viewModel.checkAnswer(for: problem)
                                    if index + 1 < viewModel.problems.count {
                                        focusedProblemId = viewModel.problems[index + 1].id
                                    }
                                },
                                onFocus: { focusedProblemId = problem.id }
                            )
                            .id(problem.id)
                            .focused($focusedProblemId, equals: problem.id)
                        }

                        if isFinished {
                            StreakBannerView(streak: effectiveStreak)
                                .padding(.top, 8)
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

            // Bottom buttons
            if isFinished {
                VStack(spacing: 12) {
                    Button(loc("Try Again")) {
                        saveAndRestart()
                    }
                    .buttonStyle(PlayfulButtonStyle())

                    Button(loc("Done")) {
                        saveAndFinish()
                    }
                    .buttonStyle(PlayfulButtonStyle(color: theme.secondaryColor))
                }
                .padding(.horizontal)
                .padding(.vertical, isCompactHeight ? 6 : 16)
            } else {
                Button(loc("Check All")) {
                    focusedProblemId = nil
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    viewModel.submitAll()
                }
                .buttonStyle(PlayfulButtonStyle(color: theme.secondaryColor))
                .padding(.horizontal)
                .padding(.vertical, isCompactHeight ? 6 : 16)
            }
        }
        .frame(maxWidth: horizontalSizeClass == .regular ? 700 : .infinity)
        .frame(maxWidth: .infinity)
    }

    private var timerHeaderView: some View {
        HStack {
            Image(systemName: "clock")
                .foregroundColor(theme.primaryColor)
                .font(isCompactHeight ? .footnote : .body)
            Text(viewModel.timeString)
                .playfulFont(size: isCompactHeight ? 16 : 22)
                .foregroundColor(theme.primaryColor)
                .monospacedDigit()

            if viewModel.deadlineSeconds > 0 {
                ProgressView(value: viewModel.deadlineProgress)
                    .tint(viewModel.deadlineProgress > 0.8 ? theme.secondaryColor : theme.primaryColor)
                    .frame(maxWidth: isCompactHeight ? 200 : .infinity)
            }

            Spacer()

            if viewModel.deadlineSeconds > 0 {
                Text("\(viewModel.remainingSeconds) " + loc("s left"))
                    .playfulFont(size: isCompactHeight ? 13 : 16)
                    .foregroundColor(viewModel.deadlineProgress > 0.8 ? theme.secondaryColor : .secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, isCompactHeight ? 6 : 16)
    }

    private var finishedHeaderView: some View {
        VStack(spacing: 8) {
            if viewModel.errorCount == 0 {
                Text(theme.celebrationEmoji)
                    .font(.system(size: 50))
                Text(loc("Clean Sheet!"))
                    .playfulFont(.title2)
                    .foregroundColor(theme.accentColor)
            }

            if viewModel.showDeadlineExpired {
                Text(loc("Time's up!"))
                    .playfulFont(.headline)
                    .foregroundColor(theme.secondaryColor)
            }

            HStack(spacing: 24) {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .foregroundColor(theme.primaryColor)
                    Text(viewModel.timeString)
                        .playfulFont(.headline)
                        .foregroundColor(theme.primaryColor)
                        .monospacedDigit()
                }

                HStack(spacing: 6) {
                    Image(systemName: viewModel.errorCount == 0 ? "checkmark.circle" : "xmark.circle")
                        .foregroundColor(viewModel.errorCount == 0 ? .green : theme.secondaryColor)
                    Text(loc("Errors") + ": \(viewModel.errorCount) / \(viewModel.problems.count)")
                        .playfulFont(.headline)
                        .foregroundColor(.primary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(theme.cardBackgroundColor)
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
        requestReviewIfAppropriate()
        focusedProblemId = nil
        viewModel.reset()
    }

    private func requestReviewIfAppropriate() {
        let key = "completedSessionCount"
        let count = UserDefaults.standard.integer(forKey: key) + 1
        UserDefaults.standard.set(count, forKey: key)
        if count == 3 || count % 15 == 0 {
            requestReview()
        }
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
        showScanner = false
        Task {
            let result = await ScanEvaluator.evaluate(images: images)
            await MainActor.run {
                if let result {
                    scanProblems = result.problems
                    scanDetectedAnswers = result.detectedAnswers
                } else {
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
