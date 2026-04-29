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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    @State private var showButton = false
    @State private var floatingEmojis: [FloatingEmoji] = []
    @State private var emojiDrift = false

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
        GeometryReader { proxy in
            ZStack {
                theme.backgroundColor.ignoresSafeArea()

                // Floating background emojis — slow vertical drift adds life;
                // skipped entirely under reduce-motion.
                if !reduceMotion {
                    ForEach(floatingEmojis) { item in
                        Text(item.emoji)
                            .font(.system(size: item.size))
                            .position(x: item.x, y: emojiDrift ? item.y - item.driftDistance : item.y)
                            .opacity(item.opacity)
                            .animation(
                                .easeInOut(duration: item.driftDuration)
                                    .repeatForever(autoreverses: true)
                                    .delay(item.delay),
                                value: emojiDrift
                            )
                    }
                }

                VStack(spacing: 32) {
                    Spacer()

                    // Trophy / Medal
                    Text(emoji)
                        .font(.system(size: appeared ? 120 : 40))
                        .scaleEffect(appeared ? 1.0 : 0.3)
                        .opacity(appeared ? 1.0 : 0.0)
                        .animation(reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.6, dampingFraction: 0.5), value: appeared)
                        .accessibilityHidden(true)

                    // Title
                    Text(title)
                        .playfulFont(.title)
                        .foregroundColor(accentColor)
                        .opacity(appeared ? 1.0 : 0.0)
                        .offset(y: appeared ? 0 : (reduceMotion ? 0 : 20))
                        .animation(.easeOut(duration: 0.5).delay(reduceMotion ? 0 : 0.3), value: appeared)

                    // Clean sheets count
                    VStack(spacing: 8) {
                        Text(loc("Clean sheets in a row"))
                            .playfulFont(.callout, weight: .medium)
                            .foregroundColor(.secondary)

                        Text("\(info.streak)")
                            .playfulFont(size: 64)
                            .foregroundColor(theme.primaryColor)
                    }
                    .opacity(appeared ? 1.0 : 0.0)
                    .offset(y: appeared ? 0 : (reduceMotion ? 0 : 20))
                    .animation(.easeOut(duration: 0.5).delay(reduceMotion ? 0 : 0.5), value: appeared)

                    Spacer()

                    // Continue button
                    if showButton {
                        Button(loc("Continue")) {
                            onDismiss()
                        }
                        .buttonStyle(PlayfulButtonStyle(color: accentColor))
                        .padding(.horizontal, 40)
                        .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
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
                if !reduceMotion {
                    generateFloatingEmojis(in: proxy.size)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        emojiDrift = true
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        showButton = true
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: loc("%@ %d clean sheets in a row"), title, info.streak))
    }

    private func generateFloatingEmojis(in size: CGSize) {
        let emojis = info.type == .gold
            ? ["🎉", "✨", "🏆", "🥇", "👑"]
            : ["🎉", "✨", "🥈", "🎊", "💫"]

        let width = max(size.width, 1)
        let height = max(size.height, 1)

        floatingEmojis = (0..<20).map { _ in
            FloatingEmoji(
                emoji: emojis.randomElement()!,
                x: CGFloat.random(in: 20...max(20, width - 20)),
                y: CGFloat.random(in: 40...max(40, height - 40)),
                size: CGFloat.random(in: 22...44),
                opacity: Double.random(in: 0.35...0.65),
                driftDistance: CGFloat.random(in: 12...28),
                driftDuration: Double.random(in: 2.4...3.6),
                delay: Double.random(in: 0...0.8)
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
    let driftDistance: CGFloat
    let driftDuration: Double
    let delay: Double
}
