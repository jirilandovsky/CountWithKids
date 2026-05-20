import SwiftUI

// Parent gate: a two-digit multiplication problem only an adult is likely to solve quickly.
//
// Required by the App Store "Kids" category (Guideline 1.3 / 5.1.4): the user must
// pass this gate before any commerce (buy, subscribe, restore, manage subscription)
// or before any link out of the app. The gate is always shown in front of those
// actions and there is no setting to disable it.
//
// Used in front of: the paywall (which contains purchase/restore + Terms/Privacy
// links), the standalone Restore Purchases action, Manage subscription, and the
// destructive "Reset All Results" action.
struct ParentGateView: View {
    @Environment(\.appTheme) var theme
    @Environment(\.dismiss) private var dismiss
    let title: String
    let message: String
    let onPass: () -> Void
    let onCancel: () -> Void

    @State private var a: Int = 0
    @State private var b: Int = 0
    @State private var input: String = ""
    @State private var showError: Bool = false
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundColor.ignoresSafeArea()

                VStack(spacing: 24) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 56))
                        .foregroundColor(theme.primaryColor)
                        .padding(.top, 16)

                    Text(title)
                        .playfulFont(.title2)
                        .foregroundColor(.primary)

                    Text(message)
                        .playfulFont(.subheadline, weight: .medium)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    HStack(spacing: 12) {
                        Text("\(a) × \(b) =")
                            .playfulFont(.title)
                            .foregroundColor(.primary)
                            .environment(\.layoutDirection, .leftToRight)

                        TextField("?", text: $input)
                            .keyboardType(.numberPad)
                            .playfulFont(.title)
                            .multilineTextAlignment(.center)
                            .frame(width: 100, height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(theme.primaryColor.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(showError ? Color.red : theme.primaryColor, lineWidth: 2)
                            )
                            .focused($focused)
                            .onChange(of: input) { _, newValue in
                                input = newValue.filter { $0.isNumber }
                                showError = false
                            }
                            .accessibilityLabel(loc("Adult check answer"))
                    }
                    .padding(.top, 8)

                    if showError {
                        Text(loc("Not quite. Try again."))
                            .playfulFont(.footnote, weight: .medium)
                            .foregroundColor(.red)
                    }

                    Spacer()

                    Button(loc("Continue")) {
                        check()
                    }
                    .buttonStyle(PlayfulButtonStyle())
                    .disabled(input.isEmpty)
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 12)
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(loc("Cancel")) { onCancel() }
                }
            }
            .onAppear {
                generateProblem()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    focused = true
                }
            }
        }
    }

    private func generateProblem() {
        a = Int.random(in: 11...19)
        b = Int.random(in: 11...19)
        input = ""
        showError = false
    }

    private func check() {
        guard let value = Int(input) else { return }
        if value == a * b {
            onPass()
        } else {
            showError = true
            input = ""
            generateProblem()
        }
    }
}

extension View {
    /// Presents a non-disableable parental gate in front of a commerce action or a
    /// link out of the app. `onPass` runs only after an adult solves the problem;
    /// cancelling simply dismisses the gate. Required for the App Store Kids category.
    func parentGate(
        isPresented: Binding<Bool>,
        message: String,
        theme: AppTheme,
        onPass: @escaping () -> Void
    ) -> some View {
        sheet(isPresented: isPresented) {
            ParentGateView(
                title: loc("Ask a grown-up"),
                message: message,
                onPass: {
                    isPresented.wrappedValue = false
                    onPass()
                },
                onCancel: {
                    isPresented.wrappedValue = false
                }
            )
            .environment(\.appTheme, theme)
        }
    }
}
