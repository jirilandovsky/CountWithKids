import SwiftUI

// Two-tier paywall:
//   1. Odemknout vše — one-time 3,99 $ (existing, untouched)
//   2. Průvodce — monthly/yearly subscription (new)
//
// Per GUIDED_LEARNING_DEV_PLAN.md §3.4 the disclosure copy and ToS/Privacy
// links above the subscribe button are MANDATORY for App Store review.
struct PaywallView: View {
    @Environment(\.appTheme) var theme
    @Environment(\.dismiss) private var dismiss
    @Bindable var settings: AppSettings
    let store: StoreManager
    /// Controls which tier(s) the paywall presents. Triggers tied to the
    /// $3.99 unlock (mascot challenge, print, scan, dashboard cards) pass
    /// `.fullUnlockOnly` so users aren't pushed toward a subscription that
    /// has nothing to do with the gated feature.
    var focus: Focus = .both

    @State private var selectedPlan: GuidedPlan = .yearly

    enum GuidedPlan { case monthly, yearly }
    enum Focus { case both, fullUnlockOnly, guidedOnly }

    private var headline: String {
        switch focus {
        case .both: return loc("Choose how you want to learn")
        case .fullUnlockOnly: return loc("Unlock the full adventure")
        case .guidedOnly: return loc("Try Guide free for 7 days")
        }
    }

    private static let termsURL = URL(string: "https://countwithkids.com/terms")!
    private static let privacyURL = URL(string: "https://countwithkids.com/privacy")!

    var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundColor.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        Text(theme.mascotEmoji)
                            .font(.system(size: 90))
                            .padding(.top, 24)

                        Text(headline)
                            .playfulFont(.title2)
                            .foregroundColor(theme.primaryColor)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        // Hide the one-time unlock when the user already owns it
                        // (avoid offering them a product they've already paid for).
                        let showGuided = focus != .fullUnlockOnly
                        let showOneTime = focus != .guidedOnly && !settings.isUnlocked

                        if showGuided {
                            guidedSection
                        }
                        if showGuided && showOneTime {
                            Divider().padding(.horizontal, 32)
                        }
                        if showOneTime {
                            oneTimeSection
                        }

                        Button(loc("Restore Purchases")) {
                            Task { await store.restore() }
                        }
                        .playfulFont(.footnote, weight: .medium)
                        .foregroundColor(theme.primaryColor)

                        Text(loc("Bought this app before it went free? Tap Restore."))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        if let error = store.lastError {
                            Text(error)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }

                        Spacer(minLength: 20)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle().fill(Color.secondary.opacity(0.12))
                            )
                    }
                    .accessibilityLabel(loc("Close"))
                }
            }
            .onChange(of: settings.isUnlocked) { _, unlocked in
                if unlocked { dismiss() }
            }
            .onChange(of: store.isGuidedActive) { _, active in
                if active { dismiss() }
            }
            .alert(
                store.restoreMessage ?? "",
                isPresented: Binding(
                    get: { store.restoreMessage != nil },
                    set: { if !$0 { store.restoreMessage = nil } }
                )
            ) {
                Button(loc("OK"), role: .cancel) { store.restoreMessage = nil }
            }
        }
    }

    // MARK: - Guided subscription card

    private var guidedSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(loc("Guide"), systemImage: "graduationcap.fill")
                .playfulFont(.headline, weight: .bold)
                .foregroundColor(theme.primaryColor)

            VStack(alignment: .leading, spacing: 10) {
                featureRow("calendar", loc("Adaptive daily plan that grows with your child"))
                featureRow("lightbulb.fill", loc("Scaffolded hints in challenge mode"))
                featureRow("envelope.fill", loc("Weekly parent report"))
            }

            HStack(spacing: 12) {
                planTile(.yearly, title: loc("Yearly"),
                         price: store.guidedYearlyDisplayPrice,
                         caption: loc("7 days free, then billed yearly"))
                planTile(.monthly, title: loc("Monthly"),
                         price: store.guidedMonthlyDisplayPrice,
                         caption: loc("7 days free, then billed monthly"))
            }

            // MANDATORY DISCLOSURE — do not abbreviate. App Store rejects.
            Text(disclosureCopy)
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)

            HStack(spacing: 16) {
                Link(loc("Terms of Service"), destination: Self.termsURL)
                Link(loc("Privacy Policy"), destination: Self.privacyURL)
            }
            .font(.footnote)

            Button {
                Task { await store.purchaseGuided(monthly: selectedPlan == .monthly) }
            } label: {
                HStack {
                    if store.isPurchasing {
                        ProgressView().tint(.white)
                    } else {
                        Text(loc("Start 7-day free trial"))
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PlayfulButtonStyle())
            .disabled(store.isPurchasing)
        }
        .padding()
        .clayCard(cornerRadius: 26, elevation: .raised)
        .padding(.horizontal)
    }

    private func planTile(_ plan: GuidedPlan, title: String, price: String, caption: String) -> some View {
        let isSelected = selectedPlan == plan
        return Button { selectedPlan = plan } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .playfulFont(.subheadline, weight: .bold)
                    .foregroundColor(isSelected ? theme.primaryColor : .primary)
                Text(price)
                    .playfulFont(.headline, weight: .bold)
                    .foregroundColor(isSelected ? theme.primaryColor : .primary)
                Text(caption)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? theme.primaryColor.opacity(0.10) : Color.gray.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? theme.primaryColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var disclosureCopy: String {
        let price = selectedPlan == .monthly
            ? store.guidedMonthlyDisplayPrice
            : store.guidedYearlyDisplayPrice
        let cadence = selectedPlan == .monthly
            ? loc("month")
            : loc("year")
        // Renewal terms + cancellation + relationship to one-time unlock.
        // §3.4 of the dev plan locks this copy for App Store compliance.
        return loc("Auto-renews. Cancel anytime in Apple ID Settings. 7 days free, then ") +
               "\(price)/\(cadence). " +
               loc("Adds to the one-time unlock — does not replace it.")
    }

    // MARK: - One-time unlock card (preserves existing $3.99 flow)

    private var oneTimeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(loc("Unlock everything"), systemImage: "lock.open.fill")
                .playfulFont(.headline, weight: .bold)
                .foregroundColor(theme.primaryColor)

            VStack(alignment: .leading, spacing: 10) {
                featureRow("plus.slash.minus", loc("All operations (+, −, ×, ÷)"))
                featureRow("slider.horizontal.3", loc("Full difficulty range up to 1000"))
                featureRow("gamecontroller.fill", loc("Challenge mode vs. mascot"))
                featureRow("printer.fill", loc("Print & scan practice pages"))
                featureRow("paintpalette.fill", loc("All themes"))
                featureRow("infinity", loc("One-time purchase, yours forever"))
            }

            Button {
                Task { await store.purchase() }
            } label: {
                HStack {
                    if store.isPurchasing {
                        ProgressView().tint(.white)
                    } else {
                        Text(loc("Unlock for") + " " + store.displayPrice)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PlayfulButtonStyle(color: theme.secondaryColor))
            .disabled(store.isPurchasing)
        }
        .padding()
        .clayCard(cornerRadius: 26, elevation: .raised)
        .padding(.horizontal)
    }

    private func featureRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(theme.primaryColor)
                .frame(width: 28)
            Text(text)
                .playfulFont(.subheadline, weight: .medium)
            Spacer(minLength: 0)
        }
    }
}
