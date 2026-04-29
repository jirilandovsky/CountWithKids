import SwiftUI
import SwiftData

@main
struct CountWithKidsApp: App {
    @State private var store = StoreManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            AppSettings.self,
            PracticeSession.self,
            MasteryProgress.self,  // legacy (pre-curriculum-rewrite); kept so existing installs migrate
            SkillProgress.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
        .modelContainer(sharedModelContainer)
    }
}
