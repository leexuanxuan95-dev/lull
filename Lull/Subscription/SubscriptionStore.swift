import Foundation
import StoreKit
import Combine

/// Real product IDs configured in App Store Connect. Held outside the
/// `@MainActor` class so non-isolated enums (PaywallView.PlanID) can read
/// them without a Swift 6 isolation warning.
enum LullProductIDs {
    static let monthlyPro      = "lull.pro.monthly"
    static let annualPro       = "lull.pro.annual"
    static let lifetime        = "lull.lifetime"
    static let proPlusMonthly  = "lull.proplus.monthly"
}

/// StoreKit 2 wrapper. Keeps `isPro`/`isProPlus` in sync with active entitlements.
///
/// In Simulator without a configured StoreKit configuration, all `Product`
/// loads will return empty arrays — the rest of the app must therefore handle
/// `products.isEmpty` gracefully (the paywall does).
@MainActor
final class SubscriptionStore: ObservableObject {

    enum Tier: String, Codable {
        case free, pro, proPlus, lifetime
    }

    // Convenience re-exports so call sites that already use
    // `SubscriptionStore.monthlyProID` keep working.
    static let monthlyProID     = LullProductIDs.monthlyPro
    static let annualProID      = LullProductIDs.annualPro
    static let lifetimeID       = LullProductIDs.lifetime
    static let proPlusMonthlyID = LullProductIDs.proPlusMonthly

    @Published private(set) var products: [Product] = []
    @Published private(set) var tier: Tier = .free
    @Published private(set) var isLoading: Bool = false
    @Published var lastError: String?

    private var transactionListener: Task<Void, Never>?

    init() {
        transactionListener = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if case .verified(let tx) = result {
                    await self.refreshEntitlements()
                    await tx.finish()
                }
            }
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Loading products

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let ids: Set<String> = [
                LullProductIDs.monthlyPro, LullProductIDs.annualPro,
                LullProductIDs.lifetime,   LullProductIDs.proPlusMonthly
            ]
            let loaded = try await Product.products(for: ids)
            self.products = loaded.sorted(by: { $0.displayName < $1.displayName })
        } catch {
            self.lastError = error.localizedDescription
        }
        await refreshEntitlements()
    }

    func product(for id: String) -> Product? {
        products.first(where: { $0.id == id })
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let tx) = verification {
                    await tx.finish()
                    await refreshEntitlements()
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            self.lastError = error.localizedDescription
        }
    }

    func restore() async {
        do {
            try await StoreKit.AppStore.sync()
            await refreshEntitlements()
        } catch {
            self.lastError = error.localizedDescription
        }
    }

    // MARK: - Entitlements

    func refreshEntitlements() async {
        var newTier: Tier = .free
        for await result in Transaction.currentEntitlements {
            guard case .verified(let tx) = result else { continue }
            switch tx.productID {
            case LullProductIDs.lifetime:
                newTier = .lifetime
            case LullProductIDs.proPlusMonthly:
                newTier = .proPlus
            case LullProductIDs.monthlyPro, LullProductIDs.annualPro:
                if newTier != .lifetime && newTier != .proPlus { newTier = .pro }
            default:
                break
            }
        }
        self.tier = newTier
    }

    // MARK: - Helpers

    var isPro: Bool {
        switch tier {
        case .free: return false
        case .pro, .proPlus, .lifetime: return true
        }
    }

    /// In v1 we only sell the lifetime non-consumable, so lifetime buyers
    /// get every feature including voice-clone (which is otherwise gated
    /// behind the Pro+ subscription that ships in v1.1).
    var isProPlus: Bool { tier == .proPlus || tier == .lifetime }
}
