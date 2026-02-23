import SwiftUI

struct AppTheme: Equatable {
    let name: String
    let primaryColor: Color
    let secondaryColor: Color
    let accentColor: Color
    let backgroundColor: Color
    let cardBackgroundColor: Color
    let mascotEmoji: String
    let celebrationEmoji: String
    let tabPracticeIcon: String
    let tabDashboardIcon: String
    let tabSettingsIcon: String

    // Dinosaur theme - parasaurolophus
    static let dinosaur = AppTheme(
        name: "dinosaur",
        primaryColor: Color(red: 0.1, green: 0.74, blue: 0.61),    // Teal #1ABC9C
        secondaryColor: Color(red: 1.0, green: 0.42, blue: 0.42),  // Coral #FF6B6B
        accentColor: Color(red: 1.0, green: 0.85, blue: 0.24),     // Yellow #FFD93D
        backgroundColor: Color(red: 1.0, green: 0.976, blue: 0.94), // Cream #FFF9F0
        cardBackgroundColor: .white,
        mascotEmoji: "🦕",          // Sauropod (closest to parasaurolophus)
        celebrationEmoji: "🎉",
        tabPracticeIcon: "pencil.and.list.clipboard",
        tabDashboardIcon: "chart.bar.fill",
        tabSettingsIcon: "gearshape.fill"
    )

    // Unicorn theme
    static let unicorn = AppTheme(
        name: "unicorn",
        primaryColor: Color(red: 0.78, green: 0.44, blue: 0.86),   // Purple #C770DB
        secondaryColor: Color(red: 0.53, green: 0.81, blue: 0.98), // Sky Blue #87CEFA
        accentColor: Color(red: 1.0, green: 0.84, blue: 0.0),      // Gold #FFD700
        backgroundColor: Color(red: 1.0, green: 0.97, blue: 1.0),  // Soft Pink White
        cardBackgroundColor: .white,
        mascotEmoji: "🦄",
        celebrationEmoji: "✨",
        tabPracticeIcon: "pencil.and.list.clipboard",
        tabDashboardIcon: "chart.bar.fill",
        tabSettingsIcon: "gearshape.fill"
    )

    // Penguin theme - grey, gender-neutral
    static let penguin = AppTheme(
        name: "penguin",
        primaryColor: Color(red: 0.35, green: 0.45, blue: 0.55),   // Steel blue-grey
        secondaryColor: Color(red: 0.95, green: 0.55, blue: 0.25), // Warm orange
        accentColor: Color(red: 0.3, green: 0.75, blue: 0.85),     // Ice blue
        backgroundColor: Color(red: 0.96, green: 0.97, blue: 0.98), // Cool light grey
        cardBackgroundColor: .white,
        mascotEmoji: "🐧",
        celebrationEmoji: "❄️",
        tabPracticeIcon: "pencil.and.list.clipboard",
        tabDashboardIcon: "chart.bar.fill",
        tabSettingsIcon: "gearshape.fill"
    )

    static func == (lhs: AppTheme, rhs: AppTheme) -> Bool {
        lhs.name == rhs.name
    }
}
