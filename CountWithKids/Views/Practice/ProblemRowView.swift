import SwiftUI

struct ProblemRowView: View {
    @Environment(\.appTheme) var theme
    let problem: MathProblem
    let index: Int
    @Binding var answer: String
    let isNegative: Bool
    let isFocused: Bool
    var result: Bool?
    let onToggleNegative: () -> Void
    let onSubmit: () -> Void
    let onFocus: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text("\(index).")
                .playfulFont(size: 16, weight: .medium)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .trailing)

            Text(problem.displayString)
                .playfulFont(size: 24)
                .foregroundColor(.primary)
                .environment(\.layoutDirection, .leftToRight)

            // Negative toggle button
            if problem.operation == .subtract {
                Button(action: onToggleNegative) {
                    Text(isNegative ? "−" : "+/−")
                        .playfulFont(size: 14)
                        .foregroundColor(isNegative ? theme.secondaryColor : .secondary)
                        .frame(width: 36, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isNegative ? theme.secondaryColor.opacity(0.15) : Color.gray.opacity(0.1))
                        )
                }
            }

            // Answer field
            HStack(spacing: 2) {
                if isNegative {
                    Text("−")
                        .playfulFont(size: 24)
                        .foregroundColor(theme.secondaryColor)
                }

                TextField("?", text: $answer)
                    .playfulFont(size: 24)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 70, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isFocused ? theme.primaryColor.opacity(0.15) : resultBackgroundColor)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isFocused ? theme.primaryColor : resultBorderColor, lineWidth: isFocused ? 3 : 2)
                    )
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
                    .playfulFont(size: 18)
                    .foregroundColor(.green)
            }

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isFocused ? theme.primaryColor.opacity(0.08) : theme.cardBackgroundColor)
                .shadow(color: isFocused ? theme.primaryColor.opacity(0.25) : .black.opacity(0.05), radius: isFocused ? 6 : 2, x: 0, y: isFocused ? 2 : 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isFocused ? theme.primaryColor : .clear, lineWidth: 2.5)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: result)
        .contentShape(Rectangle())
        .onTapGesture { onFocus() }
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
