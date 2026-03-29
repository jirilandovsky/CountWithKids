import SwiftUI
import UIKit

enum MilestoneType {
    case gold
    case silver
}

struct MilestoneInfo: Identifiable {
    let id = UUID()
    let type: MilestoneType
    let streak: Int
}

struct MilestoneCelebrationView: View {
    let info: MilestoneInfo
    let onDismiss: () -> Void

    @Environment(\.appTheme) private var theme
    @State private var appeared = false
    @State private var showButton = false
    @State private var floatingEmojis: [FloatingEmoji] = []

    private var emoji: String {
        info.type == .gold ? "🏆" : "🥈"
    }

    private var title: String {
        info.type == .gold ? loc("Gold Cup!") : loc("Silver Medal!")
    }

    private var accentColor: Color {
        info.type == .gold
            ? Color(red: 1.0, green: 0.84, blue: 0.0)
            : Color(red: 0.75, green: 0.75, blue: 0.80)
    }

    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()

            // Floating background emojis
            ForEach(floatingEmojis) { item in
                Text(item.emoji)
                    .font(.system(size: item.size))
                    .position(x: item.x, y: item.y)
                    .opacity(item.opacity)
            }

            VStack(spacing: 32) {
                Spacer()

                // Trophy / Medal
                Text(emoji)
                    .font(.system(size: appeared ? 120 : 40))
                    .scaleEffect(appeared ? 1.0 : 0.3)
                    .opacity(appeared ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.5), value: appeared)

                // Title
                Text(title)
                    .playfulFont(size: 32)
                    .foregroundColor(accentColor)
                    .opacity(appeared ? 1.0 : 0.0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: appeared)

                // Clean sheets count
                VStack(spacing: 8) {
                    Text(loc("Clean sheets in a row"))
                        .playfulFont(size: 16, weight: .medium)
                        .foregroundColor(.secondary)

                    Text("\(info.streak)")
                        .playfulFont(size: 64)
                        .foregroundColor(theme.primaryColor)
                }
                .opacity(appeared ? 1.0 : 0.0)
                .offset(y: appeared ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.5), value: appeared)

                Spacer()

                // Continue button
                if showButton {
                    Button(loc("Continue")) {
                        onDismiss()
                    }
                    .buttonStyle(PlayfulButtonStyle(color: accentColor))
                    .padding(.horizontal, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer()
                    .frame(height: 40)
            }
            .padding()
        }
        .onAppear {
            withAnimation {
                appeared = true
            }
            generateFloatingEmojis()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeOut(duration: 0.4)) {
                    showButton = true
                }
            }
        }
    }

    private func generateFloatingEmojis() {
        let emojis = info.type == .gold
            ? ["🎉", "✨", "🏆", "🥇", "👑"]
            : ["🎉", "✨", "🥈", "🎊", "💫"]

        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        floatingEmojis = (0..<20).map { _ in
            FloatingEmoji(
                emoji: emojis.randomElement()!,
                x: CGFloat.random(in: 20...(screenWidth - 20)),
                y: CGFloat.random(in: 40...(screenHeight - 40)),
                size: CGFloat.random(in: 20...40),
                opacity: Double.random(in: 0.15...0.35)
            )
        }
    }
}

private struct FloatingEmoji: Identifiable {
    let id = UUID()
    let emoji: String
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let opacity: Double
}
