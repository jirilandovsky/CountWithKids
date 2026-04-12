import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.appTheme) var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreManager.self) private var store
    @Bindable var settings: AppSettings
    @Query(sort: \PracticeSession.completedAt, order: .reverse) private var sessions: [PracticeSession]
    @State private var showResetConfirmation = false
    @State private var showPaywall = false

    private var streakResult: StreakResult {
        StreakCalculator.compute(sessions: sessions)
    }

    private let emojiChoices = [
        "⭐", "🌈", "🔥", "💎", "🚀", "🎯", "🍀", "🌸",
        "🐱", "🐶", "🐰", "🦊", "🐻", "🐼", "🐸", "🦋",
        "⚽", "🎸", "🎨", "🧩", "🍕", "🍩", "🌍", "❤️"
    ]

    private let countingRanges = [10, 20, 100, 1000]
    private let languages = [
        ("en", "English"),
        ("cs", "Čeština"),
        ("he", "עברית")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundColor.ignoresSafeArea()

                Form {
                    unlockSection
                    difficultySection
                    appearanceSection
                    languageSection
                    aboutSection
                    resetSection
                }
                .scrollContentBackground(.hidden)
                .formStyle(.grouped)
            }
            .navigationTitle(loc("Settings"))
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showPaywall) {
                PaywallView(settings: settings, store: store)
                    .environment(\.appTheme, theme)
            }
            .alert(
                store.restoreMessage ?? "",
                isPresented: Binding(
                    get: { store.restoreMessage != nil },
                    set: { if !$0 { store.restoreMessage = nil } }
                )
            ) {
                Button(loc("OK"), role: .cancel) { store.restoreMessage = nil }
            }
        }
    }

    @ViewBuilder
    private var unlockSection: some View {
        if settings.isUnlocked {
            Section {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                    Text(loc("Full version unlocked"))
                        .playfulFont(size: 16, weight: .medium)
                    Spacer()
                }
            }
        } else {
            Section {
                Button {
                    showPaywall = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.open.fill")
                            .foregroundColor(theme.primaryColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(loc("Unlock full version"))
                                .playfulFont(size: 16, weight: .bold)
                                .foregroundColor(theme.primaryColor)
                            Text(loc("All operations, themes, print & scan"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(store.displayPrice)
                            .playfulFont(size: 15, weight: .bold)
                            .foregroundColor(theme.primaryColor)
                    }
                }
                .buttonStyle(.plain)

                Button(loc("Restore Purchases")) {
                    Task { await store.restore() }
                }
                .playfulFont(size: 14, weight: .medium)
            }
        }
    }

    private var availableRanges: [Int] {
        settings.isUnlocked ? countingRanges : [10, 20]
    }

    private var difficultySection: some View {
        Section {
            // Counting range
            Picker(loc("Counting range"), selection: $settings.countingRange) {
                ForEach(availableRanges, id: \.self) { range in
                    Text(loc("To") + " \(range)").tag(range)
                }
            }
            .playfulFont(size: 16, weight: .medium)

            if !settings.isUnlocked {
                lockedRow(loc("Larger ranges (to 100, 1000)"))
            }

            // Operations
            VStack(alignment: .leading, spacing: 8) {
                Text(loc("Operations"))
                    .playfulFont(size: 16, weight: .medium)

                HStack(spacing: 12) {
                    ForEach(MathOperation.allCases) { op in
                        operationToggle(op)
                    }
                }
            }
            .padding(.vertical, 4)

            // Examples per page
            Stepper(
                loc("Examples per page:") + " \(settings.examplesPerPage)",
                value: $settings.examplesPerPage,
                in: 1...10
            )
            .playfulFont(size: 16, weight: .medium)
            .disabled(!settings.isUnlocked)
            .opacity(settings.isUnlocked ? 1 : 0.5)

            if !settings.isUnlocked {
                lockedRow(loc("Custom examples per page"))
            }

            // Deadline
            VStack(alignment: .leading, spacing: 4) {
                Stepper(
                    settings.deadlineSeconds > 0
                        ? loc("Deadline:") + " \(settings.deadlineSeconds)s"
                        : loc("Deadline: Off"),
                    value: $settings.deadlineSeconds,
                    in: 0...300,
                    step: 10
                )
                .playfulFont(size: 16, weight: .medium)
                .disabled(!settings.isUnlocked)
                .opacity(settings.isUnlocked ? 1 : 0.5)

                if settings.deadlineSeconds > 0 {
                    Text(loc("Page must be completed in") + " \(settings.deadlineSeconds) " + loc("seconds"))
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }

            if !settings.isUnlocked {
                lockedRow(loc("Custom deadline"))
            }
        } header: {
            Text(loc("Difficulty"))
                .playfulFont(size: 14, weight: .bold)
        }
    }

    private func lockedRow(_ text: String) -> some View {
        Button {
            showPaywall = true
        } label: {
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(.secondary)
                Text(text)
                    .playfulFont(size: 14, weight: .medium)
                    .foregroundColor(.secondary)
                Spacer()
                Text(loc("Unlock"))
                    .playfulFont(size: 13, weight: .bold)
                    .foregroundColor(theme.primaryColor)
            }
        }
        .buttonStyle(.plain)
    }

    private func operationToggle(_ op: MathOperation) -> some View {
        let isSelected = settings.operationsRaw.contains(op.rawValue)
        let isLocked = !settings.isUnlocked && op.rawValue != "+"
        return Button(action: {
            if isLocked {
                showPaywall = true
            } else {
                settings.toggleOperation(op)
            }
        }) {
            ZStack(alignment: .topTrailing) {
                Text(op.rawValue)
                    .playfulFont(size: 22)
                    .foregroundColor(isSelected ? .white : theme.primaryColor)
                    .frame(width: 50, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? theme.primaryColor : theme.primaryColor.opacity(0.1))
                    )
                    .opacity(isLocked ? 0.5 : 1)

                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .padding(3)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var appearanceSection: some View {
        Section {
            Picker(loc("Theme"), selection: $settings.themeRaw) {
                HStack {
                    Text("🦕")
                    Text(loc("Dinosaur"))
                }
                .tag("dinosaur")

                HStack {
                    Text("🦄")
                    Text(loc("Unicorn"))
                }
                .tag("unicorn")

                if settings.isUnlocked {
                    HStack {
                        Text("🐧")
                        Text(loc("Penguin"))
                    }
                    .tag("penguin")
                }

                if streakResult.lionUnlocked && settings.isUnlocked {
                    HStack {
                        Text("🦁")
                        Text(loc("Lion"))
                    }
                    .tag("lion")
                }

                if streakResult.emojiThemeUnlocked && settings.isUnlocked {
                    HStack {
                        Text(settings.customEmojiRaw)
                        Text(loc("Emoji"))
                    }
                    .tag("emoji")
                }
            }
            .playfulFont(size: 16, weight: .medium)

            if !settings.isUnlocked {
                lockedRow(loc("Penguin theme"))
            }

            if settings.themeRaw == "emoji" {
                emojiPicker
            }

            Picker(loc("Mode"), selection: $settings.appearanceModeRaw) {
                Text(loc("System")).tag("system")
                Text(loc("Light")).tag("light")
                Text(loc("Dark")).tag("dark")
            }
            .playfulFont(size: 16, weight: .medium)
        } header: {
            Text(loc("Appearance"))
                .playfulFont(size: 14, weight: .bold)
        }
    }

    private var emojiPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(loc("Choose your emoji"))
                .playfulFont(size: 14, weight: .medium)
                .foregroundColor(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 8), spacing: 8) {
                ForEach(emojiChoices, id: \.self) { emoji in
                    Button {
                        settings.customEmojiRaw = emoji
                    } label: {
                        Text(emoji)
                            .font(.system(size: 28))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(settings.customEmojiRaw == emoji
                                          ? theme.primaryColor.opacity(0.2)
                                          : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(settings.customEmojiRaw == emoji
                                            ? theme.primaryColor
                                            : Color.clear, lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var languageSection: some View {
        Section {
            Picker(loc("Language"), selection: $settings.languageRaw) {
                ForEach(languages, id: \.0) { code, name in
                    Text(name).tag(code)
                }
            }
            .playfulFont(size: 16, weight: .medium)
        } header: {
            Text(loc("Language"))
                .playfulFont(size: 14, weight: .bold)
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text(loc("Version"))
                    .playfulFont(size: 16, weight: .medium)
                Spacer()
                Text("2.0")
                    .foregroundColor(.secondary)
            }
        } header: {
            Text(loc("About"))
                .playfulFont(size: 14, weight: .bold)
        }
    }

    private var resetSection: some View {
        Section {
            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                HStack {
                    Spacer()
                    Text(loc("Reset All Results"))
                        .playfulFont(size: 16, weight: .medium)
                    Spacer()
                }
            }
            .alert(loc("Are you sure you really want to delete all results?"), isPresented: $showResetConfirmation) {
                Button(loc("Delete All"), role: .destructive) {
                    do {
                        try modelContext.delete(model: PracticeSession.self)
                    } catch {
                        // silently fail
                    }
                }
                Button(loc("Cancel"), role: .cancel) { }
            }
        }
    }
}
