import SwiftUI

// One-time sheet shown the first time a Guided Learning subscription activates.
// Per GUIDED_LEARNING_DEV_PLAN.md §3.5: "Průvodce je zapnutý. Vypnout můžete v Nastavení."
struct GuidedOnboardingSheet: View {
    @Environment(\.appTheme) var theme
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("🎉")
                .font(.system(size: 80))

            Text(loc("Welcome to Guide"))
                .playfulFont(.title2, weight: .bold)
                .foregroundColor(theme.primaryColor)

            Text(loc("Guide is on. You can switch it off anytime in Settings."))
                .playfulFont(.callout, weight: .medium)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            Button(loc("Got it!")) {
                onDismiss()
            }
            .buttonStyle(PlayfulButtonStyle())
            .padding(.horizontal, 40)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.backgroundColor.ignoresSafeArea())
    }
}
