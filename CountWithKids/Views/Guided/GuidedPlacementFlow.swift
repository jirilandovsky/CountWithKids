import SwiftUI
import SwiftData

// First-launch onboarding for the Guide tab.
//
// Two screens: parent enters age + (optional) school grade, then the kid runs
// a 6-problem mascot warmup that tunes activeSkillID up or down from the
// anchor by one band, max two bands away. Always closes on a positive note.
//
// Sources of this flow:
//   • Prodigy / IXL / DreamBox use a parent-anchor + adaptive refinement.
//   • Hejný diagnostic philosophy: never frame as a test, always positive.
//   • Length capped at ~3 min per attention-span guidance for ages 6–8.
struct GuidedPlacementFlow: View {
    @Environment(\.appTheme) var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var settings: AppSettings

    enum Step { case parentInfo, warmup, done }
    @State private var step: Step = .parentInfo
    @State private var anchorSkillID: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundColor.ignoresSafeArea()
                switch step {
                case .parentInfo:
                    ParentInfoStep(settings: settings) {
                        anchorSkillID = SkillCatalog.anchorSkill(
                            age: settings.kidAge,
                            grade: gradeFromRaw(settings.schoolGradeRaw)
                        ).id
                        step = .warmup
                    }
                case .warmup:
                    PlacementWarmupStep(
                        anchorSkillID: anchorSkillID,
                        onFinish: { finalSkillID in
                            settings.activeSkillID = finalSkillID
                            settings.placementCompleted = true
                            step = .done
                        }
                    )
                    .environment(\.appTheme, theme)
                case .done:
                    DonePlacementStep {
                        dismiss()
                    }
                }
            }
        }
    }

    private func gradeFromRaw(_ raw: Int) -> CzechGrade? {
        CzechGrade(rawValue: raw)
    }
}

// MARK: - Step 1: parent provides age & grade

private struct ParentInfoStep: View {
    @Environment(\.appTheme) var theme
    @Bindable var settings: AppSettings
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("👋")
                    .font(.system(size: 80))
                    .padding(.top, 32)

                Text(loc("Let's set up Guide for your child"))
                    .playfulFont(.title3, weight: .bold)
                    .foregroundColor(theme.primaryColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 16) {
                    ageRow
                    gradeRow
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(theme.cardBackgroundColor)
                )
                .padding(.horizontal)

                Text(loc("We'll then run a quick warmup with your child to find the right starting point."))
                    .playfulFont(.caption, weight: .medium)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button(loc("Continue")) { onContinue() }
                    .buttonStyle(PlayfulButtonStyle())
                    .padding(.horizontal, 40)
                    .padding(.top, 8)

                Spacer(minLength: 24)
            }
        }
    }

    private var ageRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(loc("Child's age"))
                .playfulFont(.caption, weight: .bold)
                .foregroundColor(.secondary)
            Stepper(
                value: $settings.kidAge,
                in: 5...10,
                step: 1
            ) {
                Text("\(settings.kidAge) " + loc("years"))
                    .playfulFont(.body, weight: .medium)
            }
        }
    }

    private var gradeRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(loc("School grade"))
                .playfulFont(.caption, weight: .bold)
                .foregroundColor(.secondary)
            Picker("", selection: $settings.schoolGradeRaw) {
                Text(loc("Not yet")).tag(0)
                ForEach(CzechGrade.allCases) { grade in
                    Text(grade.displayName).tag(grade.rawValue)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

// MARK: - Step 2: adaptive warmup

private struct PlacementWarmupStep: View {
    @Environment(\.appTheme) var theme
    let anchorSkillID: String
    let onFinish: (String) -> Void

    @State private var currentSkillID: String = ""
    @State private var streakAtBand = 0     // consecutive correct at current band
    @State private var wrongAtBand = 0      // consecutive wrong at current band
    @State private var bandsTraveled = 0    // total ±1 movements applied
    @State private var problemsAsked = 0
    @State private var seenProblemKeys: Set<String> = []
    @State private var currentProblem: MathProblem?
    @State private var currentAnswer: String = ""
    @State private var isNegative: Bool = false
    @State private var lastResult: Bool? = nil  // brief flash, then advance
    @FocusState private var inputFocused: Bool

    private static let maxProblems = 8
    private static let promoteAfter = 3   // consecutive correct → step up one skill
    private static let demoteAfter = 2    // consecutive wrong → step down one skill
    private static let bandsCap = 2       // never end more than 2 skills away from the anchor

    var body: some View {
        VStack(spacing: 16) {
            header
            Spacer()
            if let problem = currentProblem {
                problemView(problem)
            }
            Spacer()
            footerNote
        }
        .padding()
        .onAppear(perform: setup)
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text(theme.mascotEmoji)
                .font(.system(size: 60))
            Text(loc("Warmup with the mascot"))
                .playfulFont(.title3, weight: .bold)
                .foregroundColor(theme.primaryColor)
            Text(loc("No score, no timer — just a few problems."))
                .playfulFont(.caption, weight: .medium)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var footerNote: some View {
        HStack(spacing: 6) {
            ForEach(0..<Self.maxProblems, id: \.self) { i in
                Circle()
                    .fill(i < problemsAsked ? theme.primaryColor : Color.gray.opacity(0.2))
                    .frame(width: 8, height: 8)
            }
        }
    }

    private func problemView(_ problem: MathProblem) -> some View {
        VStack(spacing: 18) {
            HStack(spacing: 12) {
                Text(problem.displayString)
                    .playfulFont(.largeTitle)
                    .environment(\.layoutDirection, .leftToRight)

                if problem.operation == .subtract {
                    Button {
                        isNegative.toggle()
                    } label: {
                        HStack(spacing: 0) {
                            Text("+")
                                .playfulFont(.title3)
                                .frame(width: 26, height: 44)
                                .foregroundColor(isNegative ? .secondary : theme.primaryColor)
                                .background(isNegative ? Color.clear : theme.primaryColor.opacity(0.20))
                            Text("−")
                                .playfulFont(.title3)
                                .frame(width: 26, height: 44)
                                .foregroundColor(isNegative ? Color.appWrong : .secondary)
                                .background(isNegative ? Color.appWrong.opacity(0.18) : Color.clear)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                        )
                    }
                    .accessibilityLabel(loc("Sign of answer"))
                    .accessibilityValue(loc(isNegative ? "negative" : "positive"))
                }

                HStack(spacing: 2) {
                    if isNegative {
                        Text("−").playfulFont(.title2).foregroundColor(Color.appWrong)
                    }
                    TextField("?", text: $currentAnswer)
                        .keyboardType(.numberPad)
                        .playfulFont(.title)
                        .multilineTextAlignment(.center)
                        .frame(width: 90, height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(theme.primaryColor.opacity(0.15))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(resultBorder, lineWidth: 3)
                        )
                        .focused($inputFocused)
                        .onSubmit { submit() }
                        .onChange(of: currentAnswer) { _, newValue in
                            currentAnswer = newValue.filter { $0.isNumber }
                        }
                }
            }

            Button(loc("Next")) { submit() }
                .buttonStyle(PlayfulButtonStyle())
                .disabled(currentAnswer.isEmpty)
        }
    }

    private var resultBorder: Color {
        switch lastResult {
        case .some(true): return .green
        case .some(false): return theme.secondaryColor
        default: return theme.primaryColor
        }
    }

    // MARK: - Adaptive logic

    private func setup() {
        currentSkillID = anchorSkillID
        nextProblem()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            inputFocused = true
        }
    }

    private func nextProblem() {
        currentAnswer = ""
        isNegative = false
        lastResult = nil
        if let s = SkillCatalog.skill(currentSkillID) {
            // Avoid serving the same problem twice within a single placement.
            // Some skills (count_to_10) only have 10 unique problems, so we
            // bail after a reasonable number of attempts rather than loop
            // forever.
            var p = s.generate()
            for _ in 0..<30 {
                let key = "\(p.operand1)\(p.operation.rawValue)\(p.operand2)"
                if !seenProblemKeys.contains(key) { break }
                p = s.generate()
            }
            seenProblemKeys.insert("\(p.operand1)\(p.operation.rawValue)\(p.operand2)")
            currentProblem = p
        }
        inputFocused = true
    }

    private func submit() {
        guard let problem = currentProblem else { return }
        let typed = Int(currentAnswer) ?? 0
        let signed = isNegative ? -typed : typed
        let correct = signed == problem.correctAnswer
        lastResult = correct
        problemsAsked += 1

        if correct {
            streakAtBand += 1
            wrongAtBand = 0
        } else {
            wrongAtBand += 1
            streakAtBand = 0
        }

        // Adaptive band move:
        //   • 3 in a row right at this band → promote one skill, reset counter
        //   • 2 in a row wrong → demote one skill, reset counter
        // Cap total bands traveled at ±2 from the anchor so we don't fling
        // the kid wildly away from the parent's stated grade.
        if streakAtBand >= Self.promoteAfter, bandsTraveled < Self.bandsCap,
           let next = SkillCatalog.neighbor(of: currentSkillID, offset: 1) {
            currentSkillID = next.id
            bandsTraveled += 1
            streakAtBand = 0
        } else if wrongAtBand >= Self.demoteAfter, bandsTraveled > -Self.bandsCap,
                  let prev = SkillCatalog.neighbor(of: currentSkillID, offset: -1) {
            currentSkillID = prev.id
            bandsTraveled -= 1
            wrongAtBand = 0
        }

        // Brief flash of the result, then advance.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            if shouldStop() {
                onFinish(currentSkillID)
            } else {
                nextProblem()
            }
        }
    }

    private func shouldStop() -> Bool {
        // Hard cap.
        if problemsAsked >= Self.maxProblems { return true }
        // Soft cap: 6 problems is the goal; keep going only if we've ALSO
        // moved bands recently (kid is actively re-finding their level).
        if problemsAsked >= 6 && streakAtBand == 0 && wrongAtBand == 0 { return true }
        return false
    }
}

// MARK: - Step 3: Done

private struct DonePlacementStep: View {
    @Environment(\.appTheme) var theme
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("🎉").font(.system(size: 100))
            Text(loc("All set!"))
                .playfulFont(.title2, weight: .bold)
                .foregroundColor(theme.primaryColor)
            Text(loc("We've picked a starting point. Open the daily plan to begin."))
                .playfulFont(.callout, weight: .medium)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Button(loc("Open daily plan")) { onDismiss() }
                .buttonStyle(PlayfulButtonStyle())
                .padding(.horizontal, 40)
                .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.backgroundColor.ignoresSafeArea())
    }
}
