import SwiftUI
import UIKit

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

    /// Creates an adaptive color that automatically switches between light and dark variants.
    private static func adaptiveColor(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? dark : light
        })
    }

    // Dinosaur theme - parasaurolophus
    static let dinosaur = AppTheme(
        name: "dinosaur",
        primaryColor: Color(red: 0.1, green: 0.74, blue: 0.61),    // Teal #1ABC9C
        secondaryColor: Color(red: 1.0, green: 0.42, blue: 0.42),  // Coral #FF6B6B
        accentColor: Color(red: 1.0, green: 0.85, blue: 0.24),     // Yellow #FFD93D
        backgroundColor: adaptiveColor(
            light: UIColor(red: 1.0, green: 0.976, blue: 0.94, alpha: 1),  // Cream #FFF9F0
            dark: UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)    // Near black
        ),
        cardBackgroundColor: adaptiveColor(
            light: .white,
            dark: UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1)
        ),
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
        backgroundColor: adaptiveColor(
            light: UIColor(red: 1.0, green: 0.97, blue: 1.0, alpha: 1),    // Soft Pink White
            dark: UIColor(red: 0.11, green: 0.10, blue: 0.13, alpha: 1)    // Dark purple-tinted
        ),
        cardBackgroundColor: adaptiveColor(
            light: .white,
            dark: UIColor(red: 0.17, green: 0.16, blue: 0.19, alpha: 1)
        ),
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
        backgroundColor: adaptiveColor(
            light: UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1),  // Cool light grey
            dark: UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
        ),
        cardBackgroundColor: adaptiveColor(
            light: .white,
            dark: UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1)
        ),
        mascotEmoji: "🐧",
        celebrationEmoji: "❄️",
        tabPracticeIcon: "pencil.and.list.clipboard",
        tabDashboardIcon: "chart.bar.fill",
        tabSettingsIcon: "gearshape.fill"
    )

    // Lion theme - unlockable reward (5 gold cups)
    static let lion = AppTheme(
        name: "lion",
        primaryColor: Color(red: 0.85, green: 0.55, blue: 0.1),    // Warm amber
        secondaryColor: Color(red: 0.75, green: 0.2, blue: 0.15),  // Deep red-brown
        accentColor: Color(red: 1.0, green: 0.84, blue: 0.0),      // Gold
        backgroundColor: adaptiveColor(
            light: UIColor(red: 1.0, green: 0.98, blue: 0.94, alpha: 1),  // Warm cream
            dark: UIColor(red: 0.13, green: 0.11, blue: 0.09, alpha: 1)   // Warm dark
        ),
        cardBackgroundColor: adaptiveColor(
            light: .white,
            dark: UIColor(red: 0.19, green: 0.17, blue: 0.15, alpha: 1)
        ),
        mascotEmoji: "🦁",
        celebrationEmoji: "👑",
        tabPracticeIcon: "pencil.and.list.clipboard",
        tabDashboardIcon: "chart.bar.fill",
        tabSettingsIcon: "gearshape.fill"
    )

    // Emoji theme - unlockable reward (15 gold cups), predominantly white
    static func emoji(mascot: String) -> AppTheme {
        AppTheme(
            name: "emoji",
            primaryColor: Color(red: 0.45, green: 0.47, blue: 0.52),     // Medium gray
            secondaryColor: Color(red: 0.55, green: 0.55, blue: 0.60),   // Mid grey
            accentColor: Color(red: 0.95, green: 0.4, blue: 0.45),       // Soft coral pop
            backgroundColor: adaptiveColor(
                light: UIColor(red: 0.98, green: 0.98, blue: 0.99, alpha: 1),  // Near white
                dark: UIColor(red: 0.10, green: 0.10, blue: 0.11, alpha: 1)
            ),
            cardBackgroundColor: adaptiveColor(
                light: .white,
                dark: UIColor(red: 0.16, green: 0.16, blue: 0.17, alpha: 1)
            ),
            mascotEmoji: mascot,
            celebrationEmoji: mascot,
            tabPracticeIcon: "pencil.and.list.clipboard",
            tabDashboardIcon: "chart.bar.fill",
            tabSettingsIcon: "gearshape.fill"
        )
    }

    static func == (lhs: AppTheme, rhs: AppTheme) -> Bool {
        lhs.name == rhs.name && lhs.mascotEmoji == rhs.mascotEmoji
    }
}
