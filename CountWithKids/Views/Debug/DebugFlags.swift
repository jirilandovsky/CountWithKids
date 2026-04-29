import Foundation

// Compile-time debug-only flags. These are runtime values, but the *settings UI*
// that flips them is gated behind `#if DEBUG`, so release builds keep the
// hard-coded defaults.
//
// See GUIDED_LEARNING_DEV_PLAN.md Task 2.1 — `forceGuidedActive` lets us build
// and verify the Guided UI before StoreKit is wired up.
final class DebugFlags: ObservableObject, @unchecked Sendable {
    static let shared = DebugFlags()

    private let forceGuidedKey = "debug.forceGuidedActive"
    private let forceHintTierKey = "debug.forceHintTier"

    @Published var forceGuidedActive: Bool {
        didSet { UserDefaults.standard.set(forceGuidedActive, forKey: forceGuidedKey) }
    }

    /// 0 = none (real timing), 1 = nudge (5s), 2 = strategy (10s), 3 = worked example (20s)
    /// Used by ChallengeViewModel to bypass timer waits while testing hint copy.
    @Published var forceHintTier: Int {
        didSet { UserDefaults.standard.set(forceHintTier, forKey: forceHintTierKey) }
    }

    private init() {
        self.forceGuidedActive = UserDefaults.standard.bool(forKey: forceGuidedKey)
        self.forceHintTier = UserDefaults.standard.integer(forKey: forceHintTierKey)
    }
}
