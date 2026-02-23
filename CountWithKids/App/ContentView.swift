import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsArray: [AppSettings]
    @State private var languageRefreshId = UUID()

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
            default: return .dinosaur
            }
        }()
        let locale = Locale(identifier: settings.languageRaw)

        TabView {
            PracticeView(settings: settings)
                .tabItem {
                    Label(loc("Practice"), systemImage: "pencil.and.list.clipboard")
                }

            DashboardView(settings: settings)
                .tabItem {
                    Label(loc("Dashboard"), systemImage: "chart.bar.fill")
                }

            SettingsView(settings: settings)
                .tabItem {
                    Label(loc("Settings"), systemImage: "gearshape.fill")
                }
        }
        .id(languageRefreshId)
        .tint(theme.primaryColor)
        .environment(\.appTheme, theme)
        .environment(\.locale, locale)
        .environment(\.appLanguage, settings.languageRaw)
        .onChange(of: settings.languageRaw) { _, newLang in
            AppLanguageManager.shared.currentLanguage = newLang
            languageRefreshId = UUID()
        }
    }

    private func updateLanguageIfNeeded() {
        if AppLanguageManager.shared.currentLanguage != settings.languageRaw {
            AppLanguageManager.shared.currentLanguage = settings.languageRaw
        }
    }
}
