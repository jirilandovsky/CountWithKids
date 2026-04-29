import SwiftUI

// Shown in the Guide tab when no subscription is active. Pitches the value
// and offers a single CTA into the paywall.
struct GuidedTeaserView: View {
    @Environment(\.appTheme) var theme
    @Bindable var settings: AppSettings
    let store: StoreManager

    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    Text("🧭")
                        .font(.system(size: 90))
                        .padding(.top, 24)

                    Text(loc("Guide"))
                        .playfulFont(.title, weight: .bold)
                        .foregroundColor(theme.primaryColor)

                    Text(loc("A daily plan that grows with your child."))
                        .playfulFont(.body, weight: .medium)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 14) {
                        teaserRow("calendar", loc("Adaptive daily plan: Warmup, Focus, Challenge"))
                        teaserRow("chart.line.uptrend.xyaxis", loc("Levels track your child's mastery for +, −, ×, ÷"))
                        teaserRow("lightbulb.fill", loc("Scaffolded hints in challenge mode"))
                        teaserRow("envelope.fill", loc("Weekly parent report"))
                    }
                    .frame(maxWidth: 460)
                    .padding(.horizontal)

                    Button(loc("Try 7 days free")) {
                        showPaywall = true
                    }
                    .buttonStyle(PlayfulButtonStyle())
                    .padding(.horizontal, 40)

                    Spacer(minLength: 32)
                }
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationTitle(loc("Guide"))
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showPaywall) {
                PaywallView(settings: settings, store: store)
                    .environment(\.appTheme, theme)
            }
        }
    }

    private func teaserRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(theme.primaryColor)
                .frame(width: 28)
            Text(text)
                .playfulFont(.subheadline, weight: .medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
    }
}
