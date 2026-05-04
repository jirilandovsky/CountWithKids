import SwiftUI
import SwiftData

// Guided Learning practice session — skill-graph rewrite.
//
// Pulls problems from the active skill (Focus) or recently-mastered skills
// (Warmup / Challenge), records progress through CurriculumService on
// finish, and surfaces:
//   • clean-sheet count toward mastery (e.g. "3/5"),
//   • mastery celebration when the kid hits the threshold,
//   • grade-graduation full-screen when the last skill of a grade lands.
struct GuidedSessionView: View {
    @Environment(\.appTheme) var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Bindable var settings: AppSettings
    let card: DailyPlanBuilder.Card
    let onComplete: () -> Void

    @State private var viewModel = PracticeViewModel()
    @FocusState private var focusedProblemId: UUID?
    @State private var masteredEvents: [MasteredEvent] = []
    @State private var didStart = false
    @State private var showGradeCelebration: CzechGrade?

    struct MasteredEvent: Identifiable {
        let skillID: String
        let label: String
        let gradeCompleted: CzechGrade?
        var id: String { skillID }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundColor.ignoresSafeArea()
                if viewModel.state == .ready {
                    readyView
                } else {
                    inProgressView
                }
            }
            .navigationTitle(slotTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(loc("Close")) { dismiss() }
                }
            }
            .fullScreenCover(item: $showGradeCelebration) { grade in
                GradeGraduationView(grade: grade) {
                    showGradeCelebration = nil
                    finishAndDismiss()
                }
                .environment(\.appTheme, theme)
            }
        }
    }

    // MARK: - Ready

    private var readyView: some View {
        VStack(spacing: 20) {
            Spacer()
            Text(slotEmoji).font(.system(size: 90))
            Text(slotTitle)
                .playfulFont(.title2)
                .foregroundColor(theme.primaryColor)
            Text(card.label)
                .playfulFont(.body, weight: .medium)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            if card.skillIDs.count == 1, let s = SkillCatalog.skill(card.skillIDs[0]) {
                masteryProgressLine(for: s)
            }
            Button(loc("Start!")) { startSession() }
                .buttonStyle(PlayfulButtonStyle())
            Spacer()
        }
        .padding()
    }

    private func masteryProgressLine(for skill: Skill) -> some View {
        let row = CurriculumService.progress(for: skill.id, in: modelContext)
        let total = CurriculumService.masteryThreshold
        let done = min(row.consecutiveCleanSheets, total)
        return HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { i in
                Circle()
                    .fill(i < done ? theme.primaryColor : Color.gray.opacity(0.25))
                    .frame(width: 9, height: 9)
            }
            Text("\(done)/\(total)")
                .playfulFont(.caption2, weight: .medium)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - In progress

    private var inProgressView: some View {
        VStack(spacing: 0) {
            if viewModel.state == .finished {
                finishedHeader
            } else {
                timerHeader
            }

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: horizontalSizeClass == .regular ? 8 : 12) {
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
                                isLocked: viewModel.state == .finished,
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

                        // Bottom inset so the last problem can scroll above
                        // the keyboard + Check All — kids miss it otherwise.
                        Color.clear.frame(height: 96)
                    }
                    .padding()
                }
                .onChange(of: focusedProblemId) { _, newId in
                    guard let newId else { return }
                    withAnimation(.easeInOut(duration: 0.25)) {
                        proxy.scrollTo(newId, anchor: .center)
                    }
                }
            }

            if viewModel.state == .finished {
                VStack(spacing: 12) {
                    if !masteredEvents.isEmpty {
                        masteryBanner
                    }
                    Button(loc("Done")) { handleDone() }
                        .buttonStyle(PlayfulButtonStyle())
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            } else {
                Button(loc("Check All")) {
                    focusedProblemId = nil
                    viewModel.submitAll()
                    recordResults()
                }
                .buttonStyle(PlayfulButtonStyle(color: theme.secondaryColor))
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
        }
    }

    private var timerHeader: some View {
        HStack {
            Image(systemName: "clock").foregroundColor(theme.primaryColor)
            Text(viewModel.timeString)
                .playfulFont(.headline)
                .foregroundColor(theme.primaryColor)
                .monospacedDigit()
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    private var finishedHeader: some View {
        VStack(spacing: 8) {
            if viewModel.errorCount == 0 {
                Text(theme.celebrationEmoji).font(.system(size: 50))
                Text(loc("Clean Sheet!"))
                    .playfulFont(.title2)
                    .foregroundColor(theme.primaryColor)
            }
            Text(loc("Errors") + ": \(viewModel.errorCount) / \(viewModel.problems.count)")
                .playfulFont(.callout, weight: .medium)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(theme.cardBackgroundColor)
    }

    @ViewBuilder
    private var masteryBanner: some View {
        VStack(spacing: 8) {
            Text(masteredEvents.count > 1 ? loc("Skills mastered!") : loc("Skill mastered!"))
                .playfulFont(.title3)
                .foregroundColor(theme.primaryColor)
            ForEach(masteredEvents) { ev in
                Text("✨ \(ev.label)")
                    .playfulFont(.subheadline, weight: .medium)
                    .foregroundColor(.primary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Slot copy

    private var slotEmoji: String {
        switch card.slot {
        case .warmup: return "💪"
        case .focus: return "🎯"
        case .challenge: return "🏆"
        }
    }

    private var slotTitle: String {
        switch card.slot {
        case .warmup: return loc("Warmup")
        case .focus: return loc("Focus")
        case .challenge: return loc("Challenge")
        }
    }

    // MARK: - Lifecycle

    private func startSession() {
        let problems = generateProblems()
        viewModel.startPractice(problems: problems, deadlineSeconds: 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let firstId = viewModel.problems.first?.id {
                focusedProblemId = firstId
            }
        }
        didStart = true
    }

    private func generateProblems() -> [MathProblem] {
        // Pull problems by round-robining over the card's skill IDs and
        // calling each skill's generator. Then dedup as the legacy generator
        // does so we never repeat the same problem twice in a session.
        let skills = card.skillIDs.compactMap { SkillCatalog.skill($0) }
        guard !skills.isEmpty else { return [] }

        var problems: [MathProblem] = []
        var seen = Set<String>()
        var answerCounts: [Int: Int] = [:]
        let target = card.problemCount
        var attempts = 0
        var skillIndex = 0
        while problems.count < target && attempts < target * 50 {
            attempts += 1
            let p = skills[skillIndex % skills.count].generate()
            skillIndex += 1
            let key = "\(p.operand1)\(p.operation.rawValue)\(p.operand2)"
            if seen.contains(key) { continue }
            if (answerCounts[p.correctAnswer] ?? 0) >= 2 { continue }
            seen.insert(key)
            answerCounts[p.correctAnswer, default: 0] += 1
            problems.append(p)
        }
        // Top up if dedup couldn't fill (very narrow skill).
        while problems.count < target {
            problems.append(skills[problems.count % skills.count].generate())
        }
        return problems.shuffled()
    }

    private func recordResults() {
        // Tally errors per skill from the actual problems generated. We map
        // a problem back to a skill by primary operation when the card has
        // multiple skills (Challenge) — same primary op = same skill bucket.
        // For the common single-skill card this collapses to one bucket.
        var errorsBySkillID: [String: Int] = [:]
        for skillID in card.skillIDs {
            errorsBySkillID[skillID] = 0
        }

        let cardSkills = card.skillIDs.compactMap { SkillCatalog.skill($0) }
        for problem in viewModel.problems {
            let correct = viewModel.results[problem.id] ?? false
            // Find the skill in this card that owns this problem's operation.
            // Falls back to the first skill if no match (mixed-op skill or
            // counting/concept skill).
            let owner = cardSkills.first(where: { $0.primaryOperation == problem.operation })?.id
                ?? card.skillIDs.first ?? ""
            if !correct {
                errorsBySkillID[owner, default: 0] += 1
            }
        }

        var events: [MasteredEvent] = []
        for (skillID, errs) in errorsBySkillID {
            let outcome = CurriculumService.recordResult(skillID: skillID, errorCount: errs, in: modelContext)
            if case let .mastered(id, gradeCompleted) = outcome,
               let s = SkillCatalog.skill(id) {
                events.append(MasteredEvent(skillID: id, label: s.localizedLabel, gradeCompleted: gradeCompleted))
            }
        }
        // Keep order deterministic for the banner.
        masteredEvents = events.sorted { $0.skillID < $1.skillID }

        // Repair active skill if Focus just got mastered.
        _ = CurriculumService.currentActiveSkill(settings: settings, in: modelContext)

        // Save a session for dashboard/weekly-report aggregation.
        let session = PracticeSession(
            duration: viewModel.elapsedSeconds,
            errors: viewModel.errorCount,
            total: viewModel.problems.count,
            settings: settings
        )
        session.operationsRaw = Array(Set(viewModel.problems.map { $0.operation.rawValue })).sorted()
        modelContext.insert(session)

        let total = WeeklyReportService.incrementGuidedSessionCount()
        Task { await WeeklyReportService.didCompleteGuidedSession(totalGuidedSessions: total) }
    }

    private func handleDone() {
        if let grade = masteredEvents.compactMap(\.gradeCompleted).first {
            showGradeCelebration = grade
        } else {
            finishAndDismiss()
        }
    }

    private func finishAndDismiss() {
        onComplete()
        dismiss()
    }
}

// MARK: - Grade graduation

struct GradeGraduationView: View {
    @Environment(\.appTheme) var theme
    let grade: CzechGrade
    let onDismiss: () -> Void
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("🎓")
                .font(.system(size: 110))
                .scaleEffect(appeared ? 1.0 : 0.4)
                .animation(.spring(response: 0.6, dampingFraction: 0.5), value: appeared)
            Text(loc("Grade complete!"))
                .playfulFont(.title, weight: .bold)
                .foregroundColor(theme.primaryColor)
            Text(loc("You finished") + " " + grade.displayName)
                .playfulFont(.headline, weight: .medium)
                .foregroundColor(.secondary)
            Spacer()
            Button(loc("Continue")) { onDismiss() }
                .buttonStyle(PlayfulButtonStyle())
                .padding(.horizontal, 40)
                .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.backgroundColor.ignoresSafeArea())
        .onAppear { withAnimation { appeared = true } }
    }
}
