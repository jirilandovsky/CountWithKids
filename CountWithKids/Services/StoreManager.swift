import Foundation
import StoreKit
import SwiftData
import UIKit

@Observable
@MainActor
final class StoreManager {
    static let productID = "com.countwithkids.fullunlock"

    /// Subscription product IDs for the Guided Learning tier (Phase 3 of
    /// GUIDED_LEARNING_DEV_PLAN.md). Both share the same subscription group
    /// so the App Store auto-handles upgrade/downgrade.
    static let guidedMonthlyID = "com.countwithkids.guided.monthly"
    static let guidedYearlyID = "com.countwithkids.guided.yearly"
    static let guidedSubscriptionGroupID = "A1B2C3D4-0000-4000-8000-000000000010"

    /// Major version at which the app transitioned from paid to free.
    /// Users whose original purchase version is strictly less than this
    /// paid for the old $1 app and keep full access automatically.
    static let firstFreeMajorVersion = 2

    private(set) var product: Product?
    private(set) var guidedMonthly: Product?
    private(set) var guidedYearly: Product?
    private(set) var isPurchasing = false
    private(set) var isRestoring = false
    private(set) var lastError: String?
    var restoreMessage: String?

    /// Live derivation from `Transaction.currentEntitlements`. Never persisted —
    /// per Apple guidelines and GUIDED_LEARNING_DEV_PLAN.md gotcha #1, persisting
    /// it allows users to retain access after subscription expires.
    private(set) var entitledGuidedMonthly: Bool = false
    private(set) var entitledGuidedYearly: Bool = false
    private(set) var guidedInGracePeriod: Bool = false

    private var updatesTask: Task<Void, Never>?
    private var lifecycleObserver: NSObjectProtocol?
    private var settings: AppSettings?

    // No deinit cleanup: StoreManager is a single, app-lifetime instance owned
    // by CountWithKidsApp. Manual teardown isn't needed and the actor-isolation
    // dance for accessing main-actor state from a nonisolated deinit isn't
    // worth the complexity here.

    func start(settings: AppSettings) {
        self.settings = settings
        updatesTask?.cancel()
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(transactionResult: result)
            }
        }
        Task {
            await loadProducts()
            await refreshEntitlements()
            await checkLegacyPurchase()
        }

        // Re-verify entitlements when the app returns to foreground. Subscriptions
        // can expire while the app is suspended; we want fresh state on return.
        if lifecycleObserver == nil {
            lifecycleObserver = NotificationCenter.default.addObserver(
                forName: UIApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { await self?.refreshEntitlements() }
            }
        }
    }

    var displayPrice: String {
        product?.displayPrice ?? "$3.99"
    }

    var guidedMonthlyDisplayPrice: String {
        guidedMonthly?.displayPrice ?? "79 Kč"
    }

    var guidedYearlyDisplayPrice: String {
        guidedYearly?.displayPrice ?? "690 Kč"
    }

    /// True when the user has an active Guided Learning subscription (any plan)
    /// or is currently in the App Store grace period.
    var isGuidedActive: Bool {
        #if DEBUG
        if DebugFlags.shared.forceGuidedActive { return true }
        #endif
        return entitledGuidedMonthly || entitledGuidedYearly || guidedInGracePeriod
    }

    func loadProducts() async {
        do {
            let ids = [Self.productID, Self.guidedMonthlyID, Self.guidedYearlyID]
            let products = try await Product.products(for: ids)
            for p in products {
                switch p.id {
                case Self.productID: self.product = p
                case Self.guidedMonthlyID: self.guidedMonthly = p
                case Self.guidedYearlyID: self.guidedYearly = p
                default: break
                }
            }
            if product == nil {
                print("[StoreManager] loadProducts: full-unlock product missing")
            }
            if guidedMonthly == nil || guidedYearly == nil {
                print("[StoreManager] loadProducts: subscription products missing — check Configuration.storekit")
            }
        } catch {
            lastError = error.localizedDescription
            print("[StoreManager] loadProducts failed: \(error)")
        }
    }

    /// Backwards-compatible alias used by older call sites.
    func loadProduct() async { await loadProducts() }

    func purchase() async {
        if product == nil {
            await loadProducts()
        }
        guard let product else {
            lastError = "Product not available. Check that the StoreKit configuration file is selected in Edit Scheme → Run → Options → StoreKit Configuration."
            print("[StoreManager] Purchase failed: product nil after loadProducts")
            return
        }
        await runPurchase(product: product, onVerifiedTransaction: { transaction in
            self.unlock()
            await transaction.finish()
        })
    }

    /// Buys one of the two Guided subscription tiers.
    func purchaseGuided(monthly: Bool) async {
        if guidedMonthly == nil || guidedYearly == nil {
            await loadProducts()
        }
        let target = monthly ? guidedMonthly : guidedYearly
        guard let target else {
            lastError = "Subscription product unavailable. Make sure Configuration.storekit is selected in Edit Scheme."
            return
        }
        await runPurchase(product: target, onVerifiedTransaction: { transaction in
            await transaction.finish()
            await self.refreshEntitlements()
        })
    }

    private func runPurchase(product: Product, onVerifiedTransaction: @escaping (Transaction) async -> Void) async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await onVerifiedTransaction(transaction)
                } else if case .unverified(_, let error) = verification {
                    lastError = "Verification failed: \(error.localizedDescription)"
                }
            case .userCancelled:
                break
            case .pending:
                lastError = "Purchase pending (Ask to Buy / parental approval)."
            @unknown default:
                break
            }
        } catch {
            lastError = error.localizedDescription
            print("[StoreManager] purchase threw: \(error)")
        }
    }

    func restore() async {
        isRestoring = true
        defer { isRestoring = false }
        let wasUnlocked = settings?.isUnlocked ?? false
        let wasGuided = isGuidedActive
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            await checkLegacyPurchase()

            let nowUnlocked = settings?.isUnlocked ?? false
            let nowGuided = isGuidedActive

            if (nowUnlocked && !wasUnlocked) || (nowGuided && !wasGuided) {
                restoreMessage = loc("Purchase restored.")
            } else if nowUnlocked || nowGuided {
                restoreMessage = loc("Full version already unlocked.")
            } else {
                restoreMessage = loc("No previous purchase to restore.")
            }
        } catch {
            lastError = error.localizedDescription
            restoreMessage = loc("Could not restore purchases.") + " " + error.localizedDescription
        }
    }

    private func refreshEntitlements() async {
        var hasFullUnlock = false
        var hasMonthly = false
        var hasYearly = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            switch transaction.productID {
            case Self.productID:
                hasFullUnlock = true
            case Self.guidedMonthlyID:
                hasMonthly = transaction.revocationDate == nil
            case Self.guidedYearlyID:
                hasYearly = transaction.revocationDate == nil
            default:
                break
            }
        }

        entitledGuidedMonthly = hasMonthly
        entitledGuidedYearly = hasYearly
        guidedInGracePeriod = await checkGuidedGracePeriod()

        if hasFullUnlock {
            unlock()
        }
    }

    /// True if there is a guided subscription whose state is `.inGracePeriod`,
    /// even if the kid currently has no verified active entitlement.
    private func checkGuidedGracePeriod() async -> Bool {
        do {
            let statuses = try await Product.SubscriptionInfo.status(for: Self.guidedSubscriptionGroupID)
            for status in statuses {
                if status.state == .inGracePeriod {
                    return true
                }
            }
        } catch {
            print("[StoreManager] grace period check failed: \(error.localizedDescription)")
        }
        return false
    }

    private func checkLegacyPurchase() async {
        do {
            let shared = try await AppTransaction.shared
            switch shared {
            case .verified(let appTransaction):
                let original = appTransaction.originalAppVersion
                print("[StoreManager] legacy check: originalAppVersion=\(original) threshold=\(Self.firstFreeMajorVersion)")
                guard let major = Int(original.split(separator: ".").first ?? "") else {
                    print("[StoreManager] legacy check: could not parse major version from '\(original)'")
                    return
                }
                if major < Self.firstFreeMajorVersion {
                    print("[StoreManager] legacy check: unlocking (pre-freemium purchase)")
                    unlock()
                } else {
                    print("[StoreManager] legacy check: no unlock (originalAppVersion >= \(Self.firstFreeMajorVersion))")
                }
            case .unverified(_, let error):
                print("[StoreManager] legacy check: AppTransaction unverified: \(error.localizedDescription)")
            }
        } catch {
            // Non-fatal: legacy check unavailable (e.g., sandbox/TestFlight quirks).
            print("[StoreManager] legacy check failed: \(error.localizedDescription)")
        }
    }

    private func handle(transactionResult: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = transactionResult else { return }
        switch transaction.productID {
        case Self.productID:
            unlock()
            await transaction.finish()
        case Self.guidedMonthlyID, Self.guidedYearlyID:
            // Renewal, refund, expiry, or revocation. Re-derive entitlements.
            await transaction.finish()
            await refreshEntitlements()
        default:
            break
        }
    }

    private func unlock() {
        guard let settings else {
            print("[StoreManager] unlock: settings nil — StoreManager.start() may not have been called")
            return
        }
        if settings.isUnlocked {
            print("[StoreManager] unlock: already unlocked")
            return
        }
        settings.isUnlocked = true
        print("[StoreManager] unlock: isUnlocked -> true")
    }
}
