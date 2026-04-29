import SwiftUI
import SwiftData
import StoreKit
import UIKit

struct SettingsView: View {
    @Environment(\.appTheme) var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreManager.self) private var store
    @Bindable var settings: AppSettings
    @Query(sort: \PracticeSession.completedAt, order: .reverse) private var sessions: [PracticeSession]
    @State private var showResetConfirmation = false
    @State private var showParentGate = false
    @State private var showPaywall = false
    @State private var paywallFocus: PaywallView.Focus = .both
    #if DEBUG
    @State private var showDebug = false
    #endif

    private var streakResult: StreakResult {
        StreakCalculator.compute(sessions: sessions)
    }

    private let emojiChoices = [
        "⭐", "🌈", "🔥", "💎", "🚀", "🎯", "🍀", "🌸",
        "🐱", "🐶", "🐰", "🦊", "🐻", "🐼", "🐸", "🦋",
        "⚽", "🎸", "🎨", "🐨", "🍕", "🍩", "🌍", "❤️"
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
                    guidedSection
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
                PaywallView(settings: settings, store: store, focus: paywallFocus)
                    .environment(\.appTheme, theme)
            }
            #if DEBUG
            .sheet(isPresented: $showDebug) {
                MasteryDebugView(settings: settings)
                    .environment(\.appTheme, theme)
            }
            #endif
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
                        .playfulFont(.callout, weight: .medium)
                    Spacer()
                }
            }
        } else {
            Section {
                Button {
                    paywallFocus = .fullUnlockOnly
                    showPaywall = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.open.fill")
                            .foregroundColor(theme.primaryColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(loc("Unlock full version"))
                                .playfulFont(.callout, weight: .bold)
                                .foregroundColor(theme.primaryColor)
                            Text(loc("All operations, themes, print & scan"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(store.displayPrice)
                            .playfulFont(.subheadline, weight: .bold)
                            .foregroundColor(theme.primaryColor)
                    }
                }
                .buttonStyle(.plain)

                Button(loc("Restore Purchases")) {
                    Task { await store.restore() }
                }
                .playfulFont(.footnote, weight: .medium)
            }
        }
    }

    @ViewBuilder
    private var guidedSection: some View {
        if store.isGuidedActive {
            Section {
                Toggle(isOn: $settings.guidedModeEnabled) {
                    Label(loc("Guided mode"), systemImage: "graduationcap.fill")
                        .playfulFont(.callout, weight: .medium)
                }
                .tint(theme.primaryColor)

                Button {
                    Task { await openManageSubscriptions() }
                } label: {
                    Label(loc("Manage subscription"), systemImage: "creditcard")
                        .playfulFont(.subheadline, weight: .medium)
                        .foregroundColor(theme.primaryColor)
                }
            } header: {
                Text(loc("Guide"))
            }
        } else {
            Section {
                Button {
                    paywallFocus = .guidedOnly
                    showPaywall = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "graduationcap.fill")
                            .foregroundColor(theme.primaryColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(loc("Guide (subscription) — Inactive"))
                                .playfulFont(.callout, weight: .bold)
                                .foregroundColor(theme.primaryColor)
                            Text(loc("Adaptive daily plan, hints, weekly report"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
            } header: {
                Text(loc("Guide"))
            }
        }
    }

    private func openManageSubscriptions() async {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return }
        do {
            try await AppStore.showManageSubscriptions(in: scene)
        } catch {
            print("[SettingsView] showManageSubscriptions failed: \(error)")
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
            .playfulFont(.callout, weight: .medium)

            if !settings.isUnlocked {
                lockedRow(loc("Larger ranges (to 100, 1000)"))
            }

            // Operations
            VStack(alignment: .leading, spacing: 8) {
                Text(loc("Operations"))
                    .playfulFont(.callout, weight: .medium)

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
            .playfulFont(.callout, weight: .medium)
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
                .playfulFont(.callout, weight: .medium)
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
        }
    }

    private func lockedRow(_ text: String) -> some View {
        Button {
            paywallFocus = .fullUnlockOnly
            showPaywall = true
        } label: {
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(.secondary)
                Text(text)
                    .playfulFont(.footnote, weight: .medium)
                    .foregroundColor(.secondary)
                Spacer()
                Text(loc("Unlock"))
                    .playfulFont(.caption, weight: .bold)
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
                paywallFocus = .fullUnlockOnly
                showPaywall = true
            } else {
                settings.toggleOperation(op)
            }
        }) {
            ZStack(alignment: .topTrailing) {
                Text(op.rawValue)
                    .playfulFont(.title3)
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
        .accessibilityLabel(operationAccessibilityLabel(op))
        .accessibilityValue(isSelected ? loc("On") : loc("Off"))
        .accessibilityHint(isLocked ? loc("Locked, requires full unlock") : "")
    }

    private func operationAccessibilityLabel(_ op: MathOperation) -> String {
        switch op.rawValue {
        case "+": return loc("Addition")
        case "−", "-": return loc("Subtraction")
        case "×", "*": return loc("Multiplication")
        case "÷", "/": return loc("Division")
        default: return op.rawValue
        }
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
            .playfulFont(.callout, weight: .medium)

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
            .playfulFont(.callout, weight: .medium)
        } header: {
            Text(loc("Appearance"))
        }
    }

    private var emojiPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(loc("Choose your emoji"))
                .playfulFont(.footnote, weight: .medium)
                .foregroundColor(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 8), spacing: 8) {
                ForEach(emojiChoices, id: \.self) { emoji in
                    Button {
                        settings.customEmojiRaw = emoji
                    } label: {
                        Text(emoji)
                            .font(.system(size: 28))
                            .frame(maxWidth: .infinity, minHeight: 44)
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
                    .accessibilityLabel(loc("Mascot emoji"))
                    .accessibilityValue(emoji)
                    .accessibilityAddTraits(settings.customEmojiRaw == emoji ? .isSelected : [])
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
            .playfulFont(.callout, weight: .medium)
        } header: {
            Text(loc("Language"))
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text(loc("Version"))
                    .playfulFont(.callout, weight: .medium)
                Spacer()
                Text("3.0")
                    .foregroundColor(.secondary)
            }
            #if DEBUG
            .contentShape(Rectangle())
            .onLongPressGesture(minimumDuration: 1.0) {
                showDebug = true
            }
            #endif
        } header: {
            Text(loc("About"))
        }
    }

    private var resetSection: some View {
        Section {
            Button(role: .destructive) {
                showParentGate = true
            } label: {
                HStack {
                    Spacer()
                    Text(loc("Reset All Results"))
                        .playfulFont(.callout, weight: .medium)
                    Spacer()
                }
            }
            .sheet(isPresented: $showParentGate) {
                ParentGateView(
                    title: loc("Adults only"),
                    message: loc("This deletes all practice results. Solve to continue.")
                ) {
                    showParentGate = false
                    showResetConfirmation = true
                } onCancel: {
                    showParentGate = false
                }
                .environment(\.appTheme, theme)
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

// Parent gate: a two-digit multiplication problem only an adult is likely to solve quickly.
// Used in front of destructive actions and any future purchase confirmations to comply
// with App Store guidance for kids' apps.
private struct ParentGateView: View {
    @Environment(\.appTheme) var theme
    @Environment(\.dismiss) private var dismiss
    let title: String
    let message: String
    let onPass: () -> Void
    let onCancel: () -> Void

    @State private var a: Int = 0
    @State private var b: Int = 0
    @State private var input: String = ""
    @State private var showError: Bool = false
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundColor.ignoresSafeArea()

                VStack(spacing: 24) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 56))
                        .foregroundColor(theme.primaryColor)
                        .padding(.top, 16)

                    Text(title)
                        .playfulFont(.title2)
                        .foregroundColor(.primary)

                    Text(message)
                        .playfulFont(.subheadline, weight: .medium)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    HStack(spacing: 12) {
                        Text("\(a) × \(b) =")
                            .playfulFont(.title)
                            .foregroundColor(.primary)
                            .environment(\.layoutDirection, .leftToRight)

                        TextField("?", text: $input)
                            .keyboardType(.numberPad)
                            .playfulFont(.title)
                            .multilineTextAlignment(.center)
                            .frame(width: 100, height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(theme.primaryColor.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(showError ? Color.red : theme.primaryColor, lineWidth: 2)
                            )
                            .focused($focused)
                            .onChange(of: input) { _, newValue in
                                input = newValue.filter { $0.isNumber }
                                showError = false
                            }
                            .accessibilityLabel(loc("Adult check answer"))
                    }
                    .padding(.top, 8)

                    if showError {
                        Text(loc("Not quite. Try again."))
                            .playfulFont(.footnote, weight: .medium)
                            .foregroundColor(.red)
                    }

                    Spacer()

                    Button(loc("Continue")) {
                        check()
                    }
                    .buttonStyle(PlayfulButtonStyle())
                    .disabled(input.isEmpty)
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 12)
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(loc("Cancel")) { onCancel() }
                }
            }
            .onAppear {
                generateProblem()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    focused = true
                }
            }
        }
    }

    private func generateProblem() {
        a = Int.random(in: 11...19)
        b = Int.random(in: 11...19)
        input = ""
        showError = false
    }

    private func check() {
        guard let value = Int(input) else { return }
        if value == a * b {
            onPass()
        } else {
            showError = true
            input = ""
            generateProblem()
        }
    }
}
