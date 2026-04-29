import SwiftUI

struct ProblemRowView: View {
    @Environment(\.appTheme) var theme
    let problem: MathProblem
    let index: Int
    @Binding var answer: String
    let isNegative: Bool
    let isFocused: Bool
    var result: Bool?
    var isLocked: Bool = false
    let onToggleNegative: () -> Void
    let onSubmit: () -> Void
    let onFocus: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text("\(index).")
                .playfulFont(.callout, weight: .medium)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .trailing)

            Text(problem.displayString)
                .playfulFont(.title2)
                .foregroundColor(.primary)
                .environment(\.layoutDirection, .leftToRight)

            // Negative toggle button
            if problem.operation == .subtract {
                Button(action: onToggleNegative) {
                    Text(isNegative ? "−" : "+/−")
                        .playfulFont(.callout)
                        .foregroundColor(isNegative ? theme.secondaryColor : .secondary)
                        .frame(width: 48, height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isNegative ? theme.secondaryColor.opacity(0.15) : Color.gray.opacity(0.1))
                        )
                }
                .accessibilityLabel(loc(isNegative ? "Negative answer on" : "Toggle negative answer"))
                .disabled(isLocked)
            }

            // Answer field
            HStack(spacing: 2) {
                if isNegative {
                    Text("−")
                        .playfulFont(.title)
                        .foregroundColor(theme.secondaryColor)
                }

                TextField("?", text: $answer)
                    .accessibilityLabel(String(format: loc("Answer for problem %d"), index))
                    .playfulFont(.title)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 80, height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isFocused && !isLocked ? theme.primaryColor.opacity(0.15) : resultBackgroundColor)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isFocused && !isLocked ? theme.primaryColor : resultBorderColor, lineWidth: isFocused && !isLocked ? 3 : 2)
                    )
                    .disabled(isLocked)
                    .onSubmit(onSubmit)
                    .onChange(of: answer) { _, newValue in
                        answer = newValue.filter { $0.isNumber }
                    }
            }

            // Result indicator
            if let result = result {
                Image(systemName: result ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(result ? .green : theme.secondaryColor)
                    .font(.title2)
                    .transition(.scale.combined(with: .opacity))
            }

            if let result = result, !result {
                Text("\(problem.correctAnswer)")
                    .playfulFont(.headline)
                    .foregroundColor(.green)
            }

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .clayCard(
            cornerRadius: 20,
            elevation: isFocused ? .raised : .resting,
            fill: isFocused ? theme.primaryColor.opacity(0.08) : theme.cardBackgroundColor
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isFocused ? theme.primaryColor : .clear, lineWidth: 2.5)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: result)
        .contentShape(Rectangle())
        .onTapGesture { if !isLocked { onFocus() } }
    }

    private var resultBackgroundColor: Color {
        guard let result = result else { return Color.gray.opacity(0.08) }
        return result ? Color.green.opacity(0.1) : theme.secondaryColor.opacity(0.1)
    }

    private var resultBorderColor: Color {
        guard let result = result else { return Color.gray.opacity(0.2) }
        return result ? Color.green : theme.secondaryColor
    }
}
