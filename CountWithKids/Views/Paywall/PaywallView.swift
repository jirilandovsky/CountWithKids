import SwiftUI

struct PaywallView: View {
    @Environment(\.appTheme) var theme
    @Environment(\.dismiss) private var dismiss
    @Bindable var settings: AppSettings
    let store: StoreManager

    var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundColor.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        Text(theme.mascotEmoji)
                            .font(.system(size: 90))
                            .padding(.top, 24)

                        Text(loc("Unlock the full adventure"))
                            .playfulFont(size: 26)
                            .foregroundColor(theme.primaryColor)
                            .multilineTextAlignment(.center)

                        VStack(alignment: .leading, spacing: 14) {
                            featureRow("plus.slash.minus", loc("All operations (+, −, ×, ÷)"))
                            featureRow("slider.horizontal.3", loc("Full difficulty range up to 1000"))
                            featureRow("gamecontroller.fill", loc("Challenge mode vs. mascot"))
                            featureRow("printer.fill", loc("Print & scan practice pages"))
                            featureRow("paintpalette.fill", loc("All themes"))
                            featureRow("infinity", loc("One-time purchase, yours forever"))
                        }
                        .frame(maxWidth: 420)
                        .padding(.horizontal)

                        VStack(spacing: 10) {
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
                            .buttonStyle(PlayfulButtonStyle())
                            .disabled(store.isPurchasing)

                            Button(loc("Restore Purchases")) {
                                Task { await store.restore() }
                            }
                            .playfulFont(size: 15, weight: .medium)
                            .foregroundColor(theme.primaryColor)
                            .padding(.top, 4)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)

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
                    Button(loc("Close")) { dismiss() }
                }
            }
            .onChange(of: settings.isUnlocked) { _, unlocked in
                if unlocked { dismiss() }
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

    private func featureRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(theme.primaryColor)
                .frame(width: 28)
            Text(text)
                .playfulFont(size: 16, weight: .medium)
            Spacer()
        }
    }
}
