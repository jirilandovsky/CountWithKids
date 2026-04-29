#if DEBUG
import SwiftUI
import SwiftData

// Internal-only screen for verifying the curriculum graph and entitlements.
// Reachable by long-pressing the version label in Settings. Not present in release builds.
struct MasteryDebugView: View {
    @Environment(\.appTheme) var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var flags = DebugFlags.shared
    @Bindable var settings: AppSettings
    @Query private var skillRows: [SkillProgress]
    @State private var lastOutcome: String = ""

    var body: some View {
        NavigationStack {
            Form {
                entitlementSection
                onboardingSection
                skillsSection
                hintTierSection
                if !lastOutcome.isEmpty {
                    Section { Text(lastOutcome).font(.callout) }
                }
            }
            .navigationTitle("Debug")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    // MARK: - Sections

    private var entitlementSection: some View {
        Section("Entitlements") {
            Toggle("Force Guided Active", isOn: $flags.forceGuidedActive)
                .tint(theme.primaryColor)
            Toggle("Force Full Unlock ($3.99)", isOn: $settings.isUnlocked)
                .tint(theme.primaryColor)
            Text("Pretends a purchase is active. Persists in SwiftData — flip off when done.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var onboardingSection: some View {
        Section("Onboarding") {
            Toggle("Placement completed", isOn: $settings.placementCompleted)
                .tint(theme.primaryColor)
            HStack {
                Text("Active skill")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(settings.activeSkillID.isEmpty ? "—" : settings.activeSkillID)
                    .font(.caption.monospaced())
            }
            HStack {
                Text("Age / Grade")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(settings.kidAge) / \(settings.schoolGradeRaw)")
                    .font(.caption.monospaced())
            }
            Button(role: .destructive) {
                resetOnboarding()
            } label: {
                Label("Reset onboarding (re-show placement)", systemImage: "arrow.counterclockwise")
            }
        }
    }

    private var skillsSection: some View {
        Section("Skills") {
            ForEach(CzechGrade.allCases) { grade in
                gradeBlock(grade)
            }
            Button(role: .destructive) {
                resetAllSkills()
            } label: {
                Label("Reset all skill progress", systemImage: "arrow.counterclockwise")
            }
        }
    }

    private func gradeBlock(_ grade: CzechGrade) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(grade.displayName)
                .font(.headline)
            ForEach(SkillCatalog.skills(in: grade)) { skill in
                skillRowView(skill)
            }
        }
        .padding(.vertical, 4)
    }

    private func skillRowView(_ skill: Skill) -> some View {
        let row = progressRow(for: skill.id)
        let mastered = row?.isCompleted ?? false
        let count = row?.consecutiveCleanSheets ?? 0
        let total = CurriculumService.masteryThreshold

        return HStack(spacing: 8) {
            Image(systemName: mastered ? "checkmark.seal.fill" : "circle")
                .foregroundColor(mastered ? .green : .secondary)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(skill.localizedLabel)
                    .font(.subheadline)
                Text("\(count)/\(total)  ·  \(skill.id)")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                toggleMastery(skill)
            } label: {
                Image(systemName: mastered ? "minus.circle" : "plus.circle.fill")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            Button {
                settings.activeSkillID = skill.id
                lastOutcome = "Active skill → \(skill.localizedLabel)"
            } label: {
                Image(systemName: "target")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    private var hintTierSection: some View {
        Section("Hint debug") {
            Picker("Forced hint tier", selection: $flags.forceHintTier) {
                Text("None").tag(0)
                Text("Nudge (5s)").tag(1)
                Text("Strategy (10s)").tag(2)
                Text("Worked example (20s)").tag(3)
            }
        }
    }

    // MARK: - Actions

    private func progressRow(for id: String) -> SkillProgress? {
        skillRows.first(where: { $0.skillID == id })
    }

    private func toggleMastery(_ skill: Skill) {
        let row = CurriculumService.progress(for: skill.id, in: modelContext)
        if row.isCompleted {
            row.isCompleted = false
            row.consecutiveCleanSheets = 0
            lastOutcome = "Reset \(skill.localizedLabel)"
        } else {
            row.isCompleted = true
            row.consecutiveCleanSheets = CurriculumService.masteryThreshold
            lastOutcome = "Mastered \(skill.localizedLabel)"
        }
    }

    private func resetAllSkills() {
        for row in skillRows {
            row.isCompleted = false
            row.consecutiveCleanSheets = 0
        }
        lastOutcome = "All skills reset"
    }

    private func resetOnboarding() {
        settings.placementCompleted = false
        settings.activeSkillID = ""
        DailyPlanState.reset()
        lastOutcome = "Onboarding reset — close and reopen the Guide tab"
    }
}
#endif
