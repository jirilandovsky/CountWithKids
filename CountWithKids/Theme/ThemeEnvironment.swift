import SwiftUI

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = .dinosaur
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

extension View {
    func themedBackground() -> some View {
        modifier(ThemedBackgroundModifier())
    }

    func playfulFont(size: CGFloat = 18, weight: Font.Weight = .bold) -> some View {
        self.font(.system(size: size, weight: weight, design: .rounded))
    }
}

struct ThemedBackgroundModifier: ViewModifier {
    @Environment(\.appTheme) var theme

    func body(content: Content) -> some View {
        content
            .background(theme.backgroundColor.ignoresSafeArea())
    }
}

struct PlayfulButtonStyle: ButtonStyle {
    @Environment(\.appTheme) var theme
    var color: Color?

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(color ?? theme.primaryColor)
                    .shadow(color: (color ?? theme.primaryColor).opacity(0.3), radius: 4, x: 0, y: 3)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
