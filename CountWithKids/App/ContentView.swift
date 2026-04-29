import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(StoreManager.self) private var store
    @Query private var settingsArray: [AppSettings]
    @State private var languageRefreshId = UUID()
    @State private var selectedTab: Tab = .practice
    @State private var showGuidedOnboarding = false

    enum Tab: String, CaseIterable {
        case practice, dashboard, trophyShelf, guide, settings

        var label: String {
            switch self {
            case .practice: return loc("Practice")
            case .guide: return loc("Guide")
            case .dashboard: return loc("Dashboard")
            case .trophyShelf: return loc("Trophies")
            case .settings: return loc("Settings")
            }
        }

        var icon: String {
            switch self {
            case .practice: return "pencil.and.list.clipboard"
            case .guide: return "graduationcap.fill"
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
            case "emoji": return .emoji(mascot: settings.customEmojiRaw)
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
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .environment(\.appTheme, theme)
        .environment(\.locale, locale)
        .environment(\.appLanguage, settings.languageRaw)
        .onChange(of: settings.languageRaw) { _, newLang in
            AppLanguageManager.shared.currentLanguage = newLang
            languageRefreshId = UUID()
        }
        .onChange(of: store.isGuidedActive) { _, active in
            // First-time activation: default toggle ON and show one-time onboarding.
            if active && !settings.hasSeenGuidedOnboarding {
                settings.guidedModeEnabled = true
                showGuidedOnboarding = true
            }
        }
        .sheet(isPresented: $showGuidedOnboarding) {
            GuidedOnboardingSheet {
                settings.hasSeenGuidedOnboarding = true
                showGuidedOnboarding = false
            }
            .environment(\.appTheme, theme)
        }
        .onAppear {
            store.start(settings: settings)
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

            TrophyShelfView(challengeWins: settings.challengeWins)
                .tabItem {
                    Label(loc("Trophies"), systemImage: "trophy.fill")
                }
                .tag(Tab.trophyShelf)

            guideTabContent
                .tabItem {
                    Label(loc("Guide"), systemImage: "graduationcap.fill")
                }
                .tag(Tab.guide)

            SettingsView(settings: settings)
                .tabItem {
                    Label(loc("Settings"), systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
    }

    private var iPadLayout: some View {
        let theme: AppTheme = {
            switch settings.themeRaw {
            case "unicorn": return .unicorn
            case "penguin": return .penguin
            case "lion": return .lion
            case "emoji": return .emoji(mascot: settings.customEmojiRaw)
            default: return .dinosaur
            }
        }()
        return NavigationSplitView {
            List {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        Label(tab.label, systemImage: tab.icon)
                    }
                    .listRowBackground(selectedTab == tab ? theme.primaryColor.opacity(0.15) : Color.clear)
                }
            }
            .navigationTitle("Count with Kids")
        } detail: {
            switch selectedTab {
            case .practice:
                PracticeView(settings: settings)
            case .guide:
                guideTabContent
            case .dashboard:
                DashboardView(settings: settings)
            case .trophyShelf:
                TrophyShelfView(challengeWins: settings.challengeWins)
            case .settings:
                SettingsView(settings: settings)
            }
        }
    }

    /// Subscribers see the GuidedHomeView; non-subscribers see a teaser that
    /// opens the paywall. Embedding both inside the tab keeps the bottom bar
    /// stable for everyone.
    @ViewBuilder
    private var guideTabContent: some View {
        if store.isGuidedActive {
            GuidedHomeView(settings: settings, showsCloseButton: false)
        } else {
            GuidedTeaserView(settings: settings, store: store)
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
