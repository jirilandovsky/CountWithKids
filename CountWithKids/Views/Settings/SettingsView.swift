import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.appTheme) var theme
    @Bindable var settings: AppSettings

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
                    difficultySection
                    appearanceSection
                    languageSection
                    aboutSection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(loc("Settings"))
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var difficultySection: some View {
        Section {
            // Counting range
            Picker(loc("Counting range"), selection: $settings.countingRange) {
                ForEach(countingRanges, id: \.self) { range in
                    Text(loc("To") + " \(range)").tag(range)
                }
            }
            .playfulFont(size: 16, weight: .medium)

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

                if settings.deadlineSeconds > 0 {
                    Text(loc("Page must be completed in") + " \(settings.deadlineSeconds) " + loc("seconds"))
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text(loc("Difficulty"))
                .playfulFont(size: 14, weight: .bold)
        }
    }

    private func operationToggle(_ op: MathOperation) -> some View {
        let isSelected = settings.operationsRaw.contains(op.rawValue)
        return Button(action: {
            settings.toggleOperation(op)
        }) {
            Text(op.rawValue)
                .playfulFont(size: 22)
                .foregroundColor(isSelected ? .white : theme.primaryColor)
                .frame(width: 50, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? theme.primaryColor : theme.primaryColor.opacity(0.1))
                )
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

                HStack {
                    Text("🐧")
                    Text(loc("Penguin"))
                }
                .tag("penguin")
            }
            .playfulFont(size: 16, weight: .medium)
        } header: {
            Text(loc("Appearance"))
                .playfulFont(size: 14, weight: .bold)
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
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }
        } header: {
            Text(loc("About"))
                .playfulFont(size: 14, weight: .bold)
        }
    }
}
