import Foundation
import StoreKit
import SwiftData

@Observable
@MainActor
final class StoreManager {
    static let productID = "com.countwithkids.fullunlock"

    /// Major version at which the app transitioned from paid to free.
    /// Users whose original purchase version is strictly less than this
    /// paid for the old $1 app and keep full access automatically.
    static let firstFreeMajorVersion = 2

    private(set) var product: Product?
    private(set) var isPurchasing = false
    private(set) var isRestoring = false
    private(set) var lastError: String?
    var restoreMessage: String?

    private var updatesTask: Task<Void, Never>?
    private var settings: AppSettings?

    func start(settings: AppSettings) {
        self.settings = settings
        updatesTask?.cancel()
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(transactionResult: result)
            }
        }
        Task {
            await loadProduct()
            await refreshEntitlements()
            await checkLegacyPurchase()
        }
    }

    var displayPrice: String {
        product?.displayPrice ?? "$3.99"
    }

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [Self.productID])
            product = products.first
            if product == nil {
                print("[StoreManager] loadProduct: no product returned for id \(Self.productID)")
            } else {
                print("[StoreManager] loadProduct: loaded \(product!.displayName) @ \(product!.displayPrice)")
            }
        } catch {
            lastError = error.localizedDescription
            print("[StoreManager] loadProduct failed: \(error)")
        }
    }

    func purchase() async {
        if product == nil {
            await loadProduct()
        }
        guard let product else {
            lastError = "Product not available. Check that the StoreKit configuration file is selected in Edit Scheme → Run → Options → StoreKit Configuration."
            print("[StoreManager] Purchase failed: product nil after loadProduct")
            return
        }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    unlock()
                    await transaction.finish()
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
            print("[StoreManager] purchase() threw: \(error)")
        }
    }

    func restore() async {
        isRestoring = true
        defer { isRestoring = false }
        let wasUnlocked = settings?.isUnlocked ?? false
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            await checkLegacyPurchase()
            if settings?.isUnlocked == true && !wasUnlocked {
                restoreMessage = loc("Purchase restored.")
            } else if settings?.isUnlocked == true {
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
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.productID {
                unlock()
                return
            }
        }
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
        if case .verified(let transaction) = transactionResult,
           transaction.productID == Self.productID {
            unlock()
            await transaction.finish()
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
