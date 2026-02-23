import SwiftUI

/// In-app language switching helper.
/// `String(localized:)` does NOT respect Bundle swizzling or `.environment(\.locale)`.
/// This provides a `loc()` function that reads from the correct .lproj bundle
/// based on the app's language setting stored in AppLanguageManager.

final class AppLanguageManager {
    static let shared = AppLanguageManager()

    var currentLanguage: String = "en" {
        didSet {
            updateBundle()
        }
    }

    private(set) var bundle: Bundle = .main

    private init() {
        updateBundle()
    }

    private func updateBundle() {
        if let path = Bundle.main.path(forResource: currentLanguage, ofType: "lproj"),
           let langBundle = Bundle(path: path) {
            bundle = langBundle
        } else {
            bundle = .main
        }
    }
}

/// Localize a string using the in-app selected language.
func loc(_ key: String) -> String {
    AppLanguageManager.shared.bundle.localizedString(forKey: key, value: key, table: nil)
}

// Environment key for the selected language code (triggers SwiftUI re-renders)
private struct AppLanguageKey: EnvironmentKey {
    static let defaultValue: String = "en"
}

extension EnvironmentValues {
    var appLanguage: String {
        get { self[AppLanguageKey.self] }
        set { self[AppLanguageKey.self] = newValue }
    }
}
