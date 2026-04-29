import SwiftUI

struct CupShelfView: View {
    @Environment(\.appTheme) var theme
    let goldCups: Int
    let silverCups: Int

    var body: some View {
        VStack(spacing: 16) {
            if goldCups == 0 && silverCups == 0 {
                Text(loc("No cups yet — keep going!"))
                    .playfulFont(.callout, weight: .regular)
                    .foregroundColor(.secondary)
            } else {
                if goldCups > 0 {
                    cupRow(emoji: "🏆", count: goldCups, label: loc("Gold cups"))
                }
                if silverCups > 0 {
                    cupRow(emoji: "🥈", count: silverCups, label: loc("Silver medals"))
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.cardBackgroundColor)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }

    private func cupRow(emoji: String, count: Int, label: String) -> some View {
        let maxVisible = 10
        let overflow = count > maxVisible ? count - maxVisible : 0
        let visible = min(count, maxVisible)

        return VStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(0..<visible, id: \.self) { _ in
                    Text(emoji)
                        .font(.system(size: 36))
                }
                if overflow > 0 {
                    Text("+\(overflow)")
                        .playfulFont(.headline, weight: .bold)
                        .foregroundColor(.secondary)
                }
            }

            // Shelf line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.55, green: 0.35, blue: 0.17),
                            Color(red: 0.65, green: 0.45, blue: 0.25)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 4)
                .cornerRadius(2)

            Text("\(label): \(count)")
                .playfulFont(.footnote, weight: .medium)
                .foregroundColor(.secondary)
        }
    }
}
