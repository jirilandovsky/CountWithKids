import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query private var settingsArray: [AppSettings]
    @State private var languageRefreshId = UUID()
    @State private var selectedTab: Tab = .practice

    enum Tab: String, CaseIterable {
        case practice, dashboard, trophyShelf, settings

        var label: String {
            switch self {
            case .practice: return loc("Practice")
            case .dashboard: return loc("Dashboard")
            case .trophyShelf: return loc("Trophies")
            case .settings: return loc("Settings")
            }
        }

        var icon: String {
            switch self {
            case .practice: return "pencil.and.list.clipboard"
            case .dashboard: return "chart.bar.fill"
            case .trophyShelf: return "trophy.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    private var settings: AppSettings {
        if let existing = settingsArray.first {
            return existing
        }
        let newSettings = AppSettings()
        modelContext.insert(newSettings)
        return newSettings
    }

    var body: some View {
        let _ = updateLanguageIfNeeded()
        let theme: AppTheme = {
            switch settings.themeRaw {
            case "unicorn": return .unicorn
            case "penguin": return .penguin
            case "lion": return .lion
            default: return .dinosaur
            }
        }()
        let locale = Locale(identifier: settings.languageRaw)

        Group {
            if horizontalSizeClass == .regular {
                iPadLayout
            } else {
                iPhoneLayout
            }
        }
        .id(languageRefreshId)
        .tint(theme.primaryColor)
        .preferredColorScheme(preferredColorScheme)
        .environment(\.appTheme, theme)
        .environment(\.locale, locale)
        .environment(\.appLanguage, settings.languageRaw)
        .onChange(of: settings.languageRaw) { _, newLang in
            AppLanguageManager.shared.currentLanguage = newLang
            languageRefreshId = UUID()
        }
    }

    private var iPhoneLayout: some View {
        TabView(selection: $selectedTab) {
            PracticeView(settings: settings)
                .tabItem {
                    Label(loc("Practice"), systemImage: "pencil.and.list.clipboard")
                }
                .tag(Tab.practice)

            DashboardView(settings: settings)
                .tabItem {
                    Label(loc("Dashboard"), systemImage: "chart.bar.fill")
                }
                .tag(Tab.dashboard)

            TrophyShelfView()
                .tabItem {
                    Label(loc("Trophies"), systemImage: "trophy.fill")
                }
                .tag(Tab.trophyShelf)

            SettingsView(settings: settings)
                .tabItem {
                    Label(loc("Settings"), systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
    }

    private var iPadLayout: some View {
        NavigationSplitView {
            List {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        Label(tab.label, systemImage: tab.icon)
                    }
                    .listRowBackground(selectedTab == tab ? Color.accentColor.opacity(0.15) : Color.clear)
                }
            }
            .navigationTitle("Count with Kids")
        } detail: {
            switch selectedTab {
            case .practice:
                PracticeView(settings: settings)
            case .dashboard:
                DashboardView(settings: settings)
            case .trophyShelf:
                TrophyShelfView()
            case .settings:
                SettingsView(settings: settings)
            }
        }
    }

    private var preferredColorScheme: ColorScheme? {
        switch settings.appearanceModeRaw {
        case "light": return .light
        case "dark": return .dark
        default: return nil  // system default
        }
    }

    private func updateLanguageIfNeeded() {
        if AppLanguageManager.shared.currentLanguage != settings.languageRaw {
            AppLanguageManager.shared.currentLanguage = settings.languageRaw
        }
    }
}
