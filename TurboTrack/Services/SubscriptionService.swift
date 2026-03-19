import Foundation
import StoreKit
import UIKit
import FirebaseAnalytics

// MARK: - Notifications

extension Notification.Name {
    static let premiumStateDidChange = Notification.Name("premiumStateDidChange")
    static let superProStateDidChange = Notification.Name("superProStateDidChange")
}

// MARK: - Pro State

enum ProState: String, Codable {
    case notPurchased
    case active
    case inGrace
    case billingRetry
    case expired

    var hasAccess: Bool {
        switch self {
        case .active, .inGrace, .billingRetry:
            return true
        case .notPurchased, .expired:
            return false
        }
    }
}

// MARK: - Purchase Errors

enum PurchaseError: LocalizedError {
    case pending
    case unknown
    case noActiveSubscription
    case verificationFailed
    case userCancelled

    var errorDescription: String? {
        switch self {
        case .pending:
            return "Purchase is pending approval"
        case .unknown:
            return "An unknown error occurred"
        case .noActiveSubscription:
            return "No active subscription found"
        case .verificationFailed:
            return "Purchase verification failed"
        case .userCancelled:
            return "Purchase was cancelled"
        }
    }
}

// MARK: - Subscription Service

@MainActor
final class SubscriptionService: ObservableObject {

    // MARK: Product IDs

    static let weeklySubscription = "turbulence_forecast_weekly"
    static let yearlySubscription = "turbulence_forecast_yearly"
    static let superProSubscription = "turbulence_forecast_super_pro_monthly"

    // MARK: Published State

    @Published private(set) var proState: ProState = .notPurchased
    @Published private(set) var hasSuperPro: Bool = false
    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isPurchasing = false
    @Published private(set) var error: Error?
    @Published private(set) var expirationDate: Date?

    // MARK: Convenience

    var isPro: Bool { proState.hasAccess }

    var weeklyProduct: Product? {
        products.first { $0.id == Self.weeklySubscription }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == Self.yearlySubscription }
    }

    var superProProduct: Product? {
        products.first { $0.id == Self.superProSubscription }
    }

    // MARK: Private

    private let productIds: Set<String> = [
        weeklySubscription,
        yearlySubscription,
        superProSubscription
    ]

    private var updateListenerTask: Task<Void, Never>?
    private let cacheKey = "cached_pro_state"
    private let expirationKey = "cached_expiration_date"
    private let superProKey = "cached_super_pro"

    // MARK: Init

    init() {
        loadCachedState()
        startTransactionListener()

        Task {
            await initialize()
        }
    }

    // MARK: - Upsell State

    @Published var showUpsellPaywall: Bool = false

    func showUpsellFlow(source: String = "banner") {
        Analytics.logEvent("upsell_banner_clicked", parameters: ["source": source])
        showUpsellPaywall = true
    }

    func hideUpsellPaywall() {
        showUpsellPaywall = false
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Public Methods

    func initialize() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await loadProducts()
            await refreshSubscriptionStatus()
        } catch {
            self.error = error
            print("Failed to initialize subscription service: \(error)")
        }
    }

    func loadProducts() async throws {
        let storeProducts = try await Product.products(for: productIds)

        self.products = storeProducts.sorted { first, second in
            guard let firstSub = first.subscription,
                  let secondSub = second.subscription else {
                return first.price < second.price
            }
            return periodInMonths(firstSub.subscriptionPeriod) < periodInMonths(secondSub.subscriptionPeriod)
        }
    }

    func purchase(_ product: Product) async throws {
        isPurchasing = true
        error = nil
        defer { isPurchasing = false }

        Analytics.logEvent("purchase_started", parameters: [
            "plan": product.id
        ])

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshSubscriptionStatus()

                if product.id == Self.superProSubscription {
                    Analytics.logEvent("upsell_purchase_completed", parameters: [
                        AnalyticsParameterItemID: product.id,
                        AnalyticsParameterPrice: NSDecimalNumber(decimal: product.price).doubleValue,
                        AnalyticsParameterCurrency: product.priceFormatStyle.currencyCode ?? "USD"
                    ])
                } else {
                    Analytics.logEvent("purchase_completed", parameters: [
                        "plan": product.id,
                        "price": product.displayPrice
                    ])
                }

            case .userCancelled:
                Analytics.logEvent("purchase_cancelled", parameters: [
                    "plan": product.id
                ])
                throw PurchaseError.userCancelled

            case .pending:
                throw PurchaseError.pending

            @unknown default:
                throw PurchaseError.unknown
            }
        } catch {
            if !(error is PurchaseError) || (error as? PurchaseError) != .userCancelled {
                Analytics.logEvent("purchase_failed", parameters: [
                    "error": error.localizedDescription
                ])
            }
            self.error = error
            throw error
        }
    }

    func restore() async throws {
        isPurchasing = true
        error = nil
        defer { isPurchasing = false }

        do {
            try await AppStore.sync()

            var hasActiveSubscription = false

            for await result in Transaction.currentEntitlements {
                let transaction = try checkVerified(result)

                if transaction.productType == .autoRenewable,
                   let expDate = transaction.expirationDate,
                   expDate > Date() {
                    hasActiveSubscription = true
                }
            }

            if !hasActiveSubscription {
                Analytics.logEvent("restore_purchases", parameters: ["success": false])
                throw PurchaseError.noActiveSubscription
            }

            Analytics.logEvent("restore_purchases", parameters: ["success": true])
            await refreshSubscriptionStatus()
        } catch {
            self.error = error
            throw error
        }
    }

    func refreshSubscriptionStatus() async {
        var newState = ProState.notPurchased
        var newExpirationDate: Date?
        var newHasSuperPro = false

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                guard transaction.productType == .autoRenewable else { continue }

                if transaction.revocationDate != nil { continue }

                if let expDate = transaction.expirationDate, expDate > Date() {
                    newState = .active
                    newExpirationDate = expDate

                    if transaction.productID == Self.superProSubscription {
                        newHasSuperPro = true
                    }
                } else if let expDate = transaction.expirationDate {
                    if newState != .active {
                        newState = .expired
                        newExpirationDate = expDate
                    }
                }
            } catch {
                print("Failed to verify transaction: \(error)")
            }
        }

        if newState != proState {
            proState = newState
            expirationDate = newExpirationDate
            cacheState()
            NotificationCenter.default.post(name: .premiumStateDidChange, object: nil)
        }

        if newHasSuperPro != hasSuperPro {
            hasSuperPro = newHasSuperPro
            UserDefaults.standard.set(newHasSuperPro, forKey: superProKey)
            NotificationCenter.default.post(name: .superProStateDidChange, object: nil)
        }

        // Auto-show upsell 1.5s after first premium activation
        if isPro && !hasSuperPro && !UserDefaults.standard.bool(forKey: "upsell_shown") {
            UserDefaults.standard.set(true, forKey: "upsell_shown")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.showUpsellPaywall = true
            }
        }
    }

    func manageSubscriptions() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            Task {
                do {
                    try await AppStore.showManageSubscriptions(in: windowScene)
                } catch {
                    if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                        await UIApplication.shared.open(url)
                    }
                }
            }
        }
    }

    // MARK: - Debug

    #if DEBUG
    func debugSetPro(_ active: Bool) {
        let wasNotPro = !isPro
        proState = active ? .active : .notPurchased
        cacheState()

        // Auto-trigger upsell when activating premium (same as real purchase)
        if active && wasNotPro && !hasSuperPro && !UserDefaults.standard.bool(forKey: "upsell_shown") {
            UserDefaults.standard.set(true, forKey: "upsell_shown")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.showUpsellPaywall = true
            }
        }
    }

    func debugSetSuperPro(_ active: Bool) {
        hasSuperPro = active
        UserDefaults.standard.set(active, forKey: superProKey)
    }
    #endif

    // MARK: - Private Helpers

    private func startTransactionListener() {
        updateListenerTask = Task {
            for await result in Transaction.updates {
                do {
                    let transaction = try checkVerified(result)
                    await refreshSubscriptionStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }

    private func periodInMonths(_ period: Product.SubscriptionPeriod) -> Int {
        switch period.unit {
        case .day: return 0
        case .week: return 0
        case .month: return period.value
        case .year: return period.value * 12
        @unknown default: return 0
        }
    }

    // MARK: - Caching

    private func loadCachedState() {
        if let raw = UserDefaults.standard.string(forKey: cacheKey),
           let cached = ProState(rawValue: raw) {
            proState = cached
        }

        if let cached = UserDefaults.standard.object(forKey: expirationKey) as? Date {
            expirationDate = cached
        }

        hasSuperPro = UserDefaults.standard.bool(forKey: superProKey)
    }

    private func cacheState() {
        UserDefaults.standard.set(proState.rawValue, forKey: cacheKey)
        UserDefaults.standard.set(expirationDate, forKey: expirationKey)
    }
}
