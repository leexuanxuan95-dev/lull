import Foundation
import StoreKit
import Combine

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

    // Real product IDs would be configured in App Store Connect. These match
    // what the paywall surfaces.
    static let monthlyProID    = "lull.pro.monthly"
    static let annualProID     = "lull.pro.annual"
    static let lifetimeID      = "lull.lifetime"
    static let proPlusMonthlyID = "lull.proplus.monthly"

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
                Self.monthlyProID, Self.annualProID,
                Self.lifetimeID, Self.proPlusMonthlyID
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
            try await AppStore.sync()
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
            case Self.lifetimeID:
                newTier = .lifetime
            case Self.proPlusMonthlyID:
                newTier = .proPlus
            case Self.monthlyProID, Self.annualProID:
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

    var isProPlus: Bool { tier == .proPlus }
}
