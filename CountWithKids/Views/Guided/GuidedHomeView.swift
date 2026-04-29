import SwiftUI
import SwiftData

// Main hub for Guided Learning subscribers.
//
// Skill-graph rewrite. Shows:
//   • Daily-plan streak banner with today's slot completion (e.g. "2/3").
//   • 3 daily-plan cards (Warmup / Focus / Challenge), each with a checkmark
//     when completed today.
//   • Current grade with a progress bar across that grade's skills.
//   • Mastered-skills count + a "Skills" button to see the full list.
//
// Routes to onboarding when placement hasn't run yet.
struct GuidedHomeView: View {
    @Environment(\.appTheme) var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var settings: AppSettings
    @Query private var skillRows: [SkillProgress]

    @State private var activeCard: DailyPlanBuilder.Card?
    @State private var showWeeklyReport = false
    @State private var showOnboarding = false
    @State private var completedToday: Set<DailyPlanBuilder.Slot> = DailyPlanState.completedSlots()
    @State private var dailyPlanStreak: Int = DailyPlanState.fullDayStreak()
    /// Used to support both standalone (sheet) and tab-embedded presentations.
    var showsCloseButton: Bool = true

    private var plan: DailyPlanBuilder.Plan {
        DailyPlanBuilder.build(settings: settings, in: modelContext)
    }

    private var currentGrade: CzechGrade {
        CurriculumService.currentGrade(in: modelContext)
    }

    private var gradeRatio: Double {
        CurriculumService.gradeCompletionRatio(currentGrade, in: modelContext)
    }

    private var activeSkill: Skill {
        CurriculumService.currentActiveSkill(settings: settings, in: modelContext)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    streakBanner
                    dailyPlanSection
                    gradeProgressSection
                    weeklyReportButton
                    Spacer(minLength: 12)
                }
                .padding()
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationTitle(loc("Guide"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if showsCloseButton {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.secondary)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle().fill(Color.secondary.opacity(0.12))
                                )
                        }
                        .accessibilityLabel(loc("Close"))
                    }
                }
            }
            .sheet(item: $activeCard) { card in
                GuidedSessionView(
                    settings: settings,
                    card: card,
                    onComplete: {
                        DailyPlanState.markCompleted(card.slot)
                        completedToday = DailyPlanState.completedSlots()
                        dailyPlanStreak = DailyPlanState.fullDayStreak()
                    }
                )
                .environment(\.appTheme, theme)
            }
            .sheet(isPresented: $showWeeklyReport) {
                WeeklyReportView()
                    .environment(\.appTheme, theme)
            }
            .sheet(isPresented: $showOnboarding) {
                GuidedPlacementFlow(settings: settings)
                    .environment(\.appTheme, theme)
                    .interactiveDismissDisabled(true)
            }
            .onAppear {
                if !settings.placementCompleted {
                    showOnboarding = true
                }
            }
        }
    }

    // MARK: - Streak banner

    private var streakBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Text("🔥").font(.system(size: 32))
                VStack(alignment: .leading, spacing: 2) {
                    Text(loc("Daily plan streak"))
                        .playfulFont(.caption, weight: .medium)
                        .foregroundColor(.secondary)
                    Text("\(dailyPlanStreak)")
                        .playfulFont(.title2, weight: .bold)
                        .foregroundColor(theme.primaryColor)
                }
                Spacer()
                Text("\(completedToday.count)/\(DailyPlanBuilder.Slot.allCases.count)")
                    .playfulFont(.footnote, weight: .medium)
                    .foregroundColor(.secondary)
            }
            Text(loc("Finish at least one session from all three tasks below"))
                .playfulFont(.caption2, weight: .medium)
                .foregroundColor(.secondary)
        }
        .padding()
        .clayCard(cornerRadius: 22, elevation: .resting)
    }

    // MARK: - Daily plan

    private var dailyPlanSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(loc("Today's plan"))
                    .playfulFont(.headline, weight: .bold)
                    .foregroundColor(.primary)
                Spacer()
                if completedToday.count == DailyPlanBuilder.Slot.allCases.count {
                    Text(loc("All done!"))
                        .playfulFont(.caption, weight: .bold)
                        .foregroundColor(theme.accentColor)
                }
            }

            ForEach(plan.cards) { card in
                planCard(card, done: completedToday.contains(card.slot))
            }
        }
    }

    private func planCard(_ card: DailyPlanBuilder.Card, done: Bool) -> some View {
        Button { activeCard = card } label: {
            HStack(spacing: 14) {
                Text(emoji(for: card.slot))
                    .font(.system(size: 36))
                    .opacity(done ? 0.5 : 1)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title(for: card.slot))
                        .playfulFont(.body, weight: .bold)
                        .foregroundColor(theme.primaryColor)
                    Text(card.label)
                        .playfulFont(.caption, weight: .medium)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                if done {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(theme.accentColor)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .clayCard(cornerRadius: 22, elevation: .resting)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Grade progress

    private var gradeProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(loc("Your progress"))
                .playfulFont(.headline, weight: .bold)
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(currentGrade.displayName)
                        .playfulFont(.body, weight: .bold)
                        .foregroundColor(theme.primaryColor)
                    Spacer()
                    Text(progressFraction)
                        .playfulFont(.footnote, weight: .medium)
                        .foregroundColor(.secondary)
                }

                ProgressView(value: gradeRatio)
                    .tint(theme.primaryColor)

                HStack(spacing: 8) {
                    Image(systemName: "target")
                        .foregroundColor(theme.accentColor)
                    Text(loc("Now learning") + ": ")
                        .playfulFont(.caption, weight: .medium)
                        .foregroundColor(.secondary)
                    Text(activeSkill.localizedLabel)
                        .playfulFont(.footnote, weight: .bold)
                        .foregroundColor(.primary)
                    Spacer(minLength: 0)
                }
                .padding(.top, 4)
            }
            .padding()
            .clayCard(cornerRadius: 22, elevation: .resting)
        }
    }

    private var progressFraction: String {
        let skills = SkillCatalog.skills(in: currentGrade)
        let mastered = CurriculumService.masteredSkillIDs(in: modelContext)
        let done = skills.filter { mastered.contains($0.id) }.count
        return "\(done)/\(skills.count)"
    }

    // MARK: - Weekly report

    private var weeklyReportButton: some View {
        Button { showWeeklyReport = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "envelope.fill")
                    .foregroundColor(theme.primaryColor)
                Text(loc("Weekly report"))
                    .playfulFont(.callout, weight: .bold)
                    .foregroundColor(theme.primaryColor)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .clayCard(cornerRadius: 22, elevation: .resting)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Slot copy

    private func emoji(for slot: DailyPlanBuilder.Slot) -> String {
        switch slot {
        case .warmup: return "💪"
        case .focus: return "🎯"
        case .challenge: return "🏆"
        }
    }

    private func title(for slot: DailyPlanBuilder.Slot) -> String {
        switch slot {
        case .warmup: return loc("Warmup")
        case .focus: return loc("Focus")
        case .challenge: return loc("Challenge")
        }
    }
}
