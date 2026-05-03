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

// MARK: - Semantic colors (theme-independent)

extension Color {
    /// Fixed wrong-answer red. Stays consistent across all themes so kids
    /// learn the signal regardless of which mascot is selected. Tested for
    /// 4.5:1 contrast on cream and dark backgrounds.
    static let appWrong = Color(
        light: Color(red: 0.83, green: 0.18, blue: 0.22),
        dark: Color(red: 1.00, green: 0.42, blue: 0.45)
    )

    /// Fixed correct-answer green for parity (currently we use .green which
    /// is fine, but having a token simplifies any future tuning).
    static let appCorrect = Color(
        light: Color(red: 0.20, green: 0.65, blue: 0.32),
        dark: Color(red: 0.40, green: 0.85, blue: 0.50)
    )

    fileprivate init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

extension View {
    func themedBackground() -> some View {
        modifier(ThemedBackgroundModifier())
    }

    /// Fixed-size variant. Use only for decorative emoji / large display numerics
    /// where Dynamic Type scaling would break layout.
    func playfulFont(size: CGFloat = 18, weight: Font.Weight = .bold) -> some View {
        self.font(.system(size: size, weight: weight, design: .rounded))
    }

    /// Dynamic-Type-aware variant. Pass a TextStyle and Font scales with the
    /// user's accessibility text-size setting (capped at app root).
    func playfulFont(_ style: Font.TextStyle, weight: Font.Weight = .bold) -> some View {
        self.font(.system(style, design: .rounded).weight(weight))
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var color: Color?

    func makeBody(configuration: Configuration) -> some View {
        let fillColor = color ?? theme.primaryColor
        return configuration.label
            .font(.system(.title3, design: .rounded).weight(.bold))
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(fillColor)
                    // Clay double-shadow: outer drop + tighter contact shadow.
                    .shadow(color: fillColor.opacity(0.35), radius: 10, x: 0, y: 6)
                    .shadow(color: fillColor.opacity(0.25), radius: 2, x: 0, y: 1)
            )
            .overlay(
                // Top highlight gives the squishy/clay bevel.
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.45), Color.white.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(
                reduceMotion
                    ? .easeInOut(duration: 0.1)
                    : .spring(response: 0.3, dampingFraction: 0.6),
                value: configuration.isPressed
            )
    }
}

// MARK: - Claymorphism cards

enum ClayElevation {
    case resting   // standard cards on background
    case raised    // focused / winner / hero card
    case floating  // celebration / modal surfaces
}

struct ClayCardModifier: ViewModifier {
    @Environment(\.appTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    let cornerRadius: CGFloat
    let elevation: ClayElevation
    let fill: Color?

    private var shadowOuterOpacity: Double {
        switch elevation {
        case .resting: return colorScheme == .dark ? 0.30 : 0.08
        case .raised:  return colorScheme == .dark ? 0.40 : 0.12
        case .floating:return colorScheme == .dark ? 0.50 : 0.18
        }
    }

    private var shadowOuterRadius: CGFloat {
        switch elevation {
        case .resting: return 12
        case .raised: return 18
        case .floating: return 28
        }
    }

    private var shadowOuterY: CGFloat {
        switch elevation {
        case .resting: return 4
        case .raised: return 8
        case .floating: return 12
        }
    }

    private var highlightOpacity: Double {
        // Top bevel — softer in dark mode so it doesn't look like a stroke.
        switch (elevation, colorScheme) {
        case (.resting, .light): return 0.55
        case (.raised, .light):  return 0.65
        case (.floating, .light):return 0.75
        case (.resting, .dark):  return 0.10
        case (.raised, .dark):   return 0.14
        case (.floating, .dark): return 0.18
        default: return 0.5
        }
    }

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return content
            .background(
                shape
                    .fill(fill ?? theme.cardBackgroundColor)
                    .shadow(color: .black.opacity(shadowOuterOpacity),
                            radius: shadowOuterRadius, x: 0, y: shadowOuterY)
                    .shadow(color: .black.opacity(shadowOuterOpacity * 0.5),
                            radius: 2, x: 0, y: 1)
            )
            .overlay(
                shape.stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(highlightOpacity),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
            )
    }
}

extension View {
    /// Clay-style card surface with double-stack shadow + top bevel highlight.
    /// Use for kid-facing surfaces: Practice ready, Trophy cards, Challenge prompt,
    /// Milestone celebration, Guided plan cards, Paywall feature cards.
    func clayCard(cornerRadius: CGFloat = 24,
                  elevation: ClayElevation = .resting,
                  fill: Color? = nil) -> some View {
        modifier(ClayCardModifier(cornerRadius: cornerRadius, elevation: elevation, fill: fill))
    }
}
