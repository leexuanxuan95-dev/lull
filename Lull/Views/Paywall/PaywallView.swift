import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var app: AppStore
    @EnvironmentObject var subscription: SubscriptionStore
    @Environment(\.dismiss) private var dismiss

    @State private var selection: PlanID = .lifetime
    @State private var purchasing: Bool = false

    /// v1 ships only the lifetime non-consumable IAP. Subscriptions are
    /// scaffolded but hidden until v1.1 — per the App Store deploy runbook
    /// §13, "v1 只交 1 个 NON_CONSUMABLE IAP. paywall 上不显示任何未提交的 IAP."
    /// To re-enable subscriptions in a future version: flip this to false,
    /// finish ASC subscription group setup, and re-submit.
    private static let v1LifetimeOnly = true

    enum PlanID: String, Identifiable {
        case monthly, annual, lifetime, proPlus
        var id: String { rawValue }

        var productID: String {
            switch self {
            case .monthly:  return LullProductIDs.monthlyPro
            case .annual:   return LullProductIDs.annualPro
            case .lifetime: return LullProductIDs.lifetime
            case .proPlus:  return LullProductIDs.proPlusMonthly
            }
        }
    }

    var body: some View {
        ZStack {
            MidnightBackground()

            ScrollView {
                VStack(spacing: 22) {
                    hero

                    plans

                    perks

                    if let err = subscription.lastError {
                        Text(err)
                            .font(LullFonts.ui(12))
                            .foregroundStyle(.red.opacity(0.85))
                    }

                    LullPrimaryButton(title: ctaTitle, systemImage: "moon.stars") {
                        Task { await purchase() }
                    }
                    .disabled(purchasing)
                    .opacity(purchasing ? 0.5 : 1)

                    Button("restore purchases") {
                        Task { await subscription.restore() }
                    }
                    .font(LullFonts.ui(13))
                    .foregroundStyle(LullColors.textMuted)

                    Text(legalFooter)
                        .font(LullFonts.ui(11))
                        .foregroundStyle(LullColors.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)

                    Spacer(minLength: 24)
                }
                .padding(.top, 24)
                .padding(.horizontal, 22)
                .padding(.bottom, 30)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(LullColors.textSecondary)
                    .padding(10)
                    .background(Circle().fill(LullColors.nightSoft.opacity(0.5)))
            }
            .padding(.top, 12)
            .padding(.trailing, 16)
        }
        .preferredColorScheme(.dark)
    }

    private var hero: some View {
        VStack(spacing: 14) {
            LampGlow(size: 200, intensity: 0.95)
                .frame(height: 220)

            Text("your bedtime story,\nwritten tonight.")
                .font(LullFonts.display(28))
                .foregroundStyle(LullColors.textPrimary)
                .multilineTextAlignment(.center)

            Text("unlimited stories · premium voices · Apple Watch · smart wake")
                .font(LullFonts.prose(14))
                .foregroundStyle(LullColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var plans: some View {
        VStack(spacing: 10) {
            if Self.v1LifetimeOnly {
                planRow(.lifetime, title: "Lifetime",
                        subtitle: "$99 once · all features, forever")
            } else {
                planRow(.annual,   title: "Yearly",       subtitle: "$69/yr · most popular")
                planRow(.monthly,  title: "Monthly",      subtitle: "$9.99/mo")
                planRow(.lifetime, title: "Lifetime",     subtitle: "$99 once · keep it forever")
                planRow(.proPlus,  title: "Pro+ Monthly", subtitle: "$14.99/mo · adds voice clone")
            }
        }
    }

    private func planRow(_ plan: PlanID, title: String, subtitle: String) -> some View {
        let isSelected = selection == plan
        return Button { selection = plan } label: {
            HStack {
                Circle()
                    .stroke(LullColors.warmLamp, lineWidth: 2)
                    .frame(width: 18, height: 18)
                    .overlay {
                        Circle()
                            .fill(LullColors.warmLamp)
                            .frame(width: 10, height: 10)
                            .opacity(isSelected ? 1 : 0)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(LullFonts.ui(15, weight: .medium))
                        .foregroundStyle(LullColors.textPrimary)
                    Text(subtitle)
                        .font(LullFonts.prose(13))
                        .foregroundStyle(LullColors.textSecondary)
                }
                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(LullColors.nightSoft.opacity(isSelected ? 0.85 : 0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? LullColors.warmLamp : LullColors.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var perks: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(perkList, id: \.self) { line in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "moon.stars.fill")
                        .foregroundStyle(LullColors.warmLamp)
                        .font(.system(size: 14))
                    Text(line)
                        .font(LullFonts.prose(14))
                        .foregroundStyle(LullColors.textPrimary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(LullColors.nightSoft.opacity(0.4))
        )
    }

    private var perkList: [String] {
        if Self.v1LifetimeOnly {
            return [
                "unlimited stories per night",
                "all eight narrator voices",
                "sleep timer + smart-wake alarm",
                "Apple Watch complication",
                "no subscription, no renewal — pay once"
            ]
        }
        return [
            "unlimited stories per night",
            "all eight narrator voices",
            "sleep timer + smart-wake alarm",
            "Apple Watch complication",
            selection == .proPlus
                ? "voice clone — your own voice as narrator"
                : "Pro+ adds your voice as narrator"
        ]
    }

    private var ctaTitle: String {
        if Self.v1LifetimeOnly { return "unlock lifetime · $99" }
        switch selection {
        case .lifetime: return "buy lifetime"
        case .proPlus:  return "start Pro+"
        default:        return "start Pro"
        }
    }

    /// Footer disclosure shown under the CTA. Lifetime is a one-time non-
    /// consumable — no auto-renew language. Subscription wording will return
    /// in v1.1 once subs are submitted.
    private var legalFooter: String {
        if Self.v1LifetimeOnly || selection == .lifetime {
            return "one-time purchase. no auto-renewal. restored across devices on the same Apple ID."
        }
        return "auto-renews until canceled. cancel anytime in settings."
    }

    private func purchase() async {
        guard let product = subscription.product(for: selection.productID) else {
            // No StoreKit configuration loaded (Simulator without .storekit) —
            // gracefully no-op rather than crash.
            subscription.lastError = "Products unavailable. Configure a StoreKit file in Xcode → Edit Scheme."
            return
        }
        purchasing = true
        await subscription.purchase(product)
        purchasing = false
        if subscription.isPro { dismiss() }
    }
}
