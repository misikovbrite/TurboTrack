import SwiftUI
import StoreKit
import FirebaseAnalytics

struct UpsellPaywallScreen: View {
    let onClose: () -> Void
    let onSubscribe: () -> Void

    @EnvironmentObject var subscriptionService: SubscriptionService

    @State private var slideOffset: CGFloat = 400
    @State private var showCloseButton: Bool = false
    @State private var isPurchasing: Bool = false
    @State private var glowAlpha: Double = 0.2

    private var superProProduct: Product? {
        subscriptionService.superProProduct
    }

    private var priceString: String {
        superProProduct?.displayPrice ?? "$19.99"
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // Background
                Color(red: 0.04, green: 0.04, blue: 0.05)
                    .ignoresSafeArea()

                // Pulsing blue glow at top
                RadialGradient(
                    colors: [
                        Color.blue.opacity(0.5),
                        Color.blue.opacity(0.2),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 175
                )
                .frame(width: 350, height: 350)
                .offset(y: -50)
                .opacity(glowAlpha)
                .blur(radius: 60)
                .frame(maxWidth: .infinity, alignment: .center)
                .allowsHitTesting(false)

                // Main content — scrollable
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer().frame(height: 80 + geometry.safeAreaInsets.top)

                        // Icon
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 80, height: 80)
                            Image(systemName: "shield.checkered")
                                .font(.system(size: 36))
                                .foregroundColor(.blue)
                        }

                        Spacer().frame(height: 24)

                        // Title
                        Text("Your forecast is ready.")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Spacer().frame(height: 4)

                        Text("Now get Maximum Accuracy")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.blue)
                            .multilineTextAlignment(.center)

                        Spacer().frame(height: 12)

                        Text("Upgrade to our most advanced prediction engine")
                            .font(.system(size: 15))
                            .foregroundColor(Color.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        Spacer().frame(height: 40)

                        // Features
                        VStack(spacing: 24) {
                            upsellFeatureRow(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "10x more accurate turbulence prediction"
                            )
                            upsellFeatureRow(
                                icon: "calendar.badge.clock",
                                title: "Extended 14-day route forecasts"
                            )
                            upsellFeatureRow(
                                icon: "bolt.fill",
                                title: "Priority real-time PIREP alerts"
                            )
                        }
                        .padding(.horizontal, 24)

                        Spacer().frame(height: 32)

                        // Reviews carousel
                        reviewsSection

                        Spacer().frame(height: 32)

                        // CTA
                        Button(action: handlePurchase) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 28)
                                    .fill(Color.white)
                                    .frame(height: 56)

                                if isPurchasing {
                                    ProgressView()
                                        .tint(.black)
                                } else {
                                    Text("Get 3 days free")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.black)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .disabled(isPurchasing)

                        Spacer().frame(height: 12)

                        // Price
                        priceText
                            .font(.system(size: 14))
                            .multilineTextAlignment(.center)

                        Spacer().frame(height: 8)

                        Text("Cancel anytime during trial")
                            .font(.system(size: 12))
                            .foregroundColor(Color.gray.opacity(0.6))

                        HStack(spacing: 4) {
                            Link("Privacy Policy", destination: URL(string: "https://britetodo.com/legal/PrivacyPolicyBrite.pdf")!)
                            Text("\u{00B7}").foregroundColor(.gray.opacity(0.5))
                            Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                        }
                        .font(.system(size: 10))
                        .foregroundColor(.gray.opacity(0.5))
                        .padding(.top, 4)

                        Spacer().frame(height: 32 + geometry.safeAreaInsets.bottom)
                    }
                }

                // Close button — top left, very faint
                Button(action: {
                    guard showCloseButton else { return }
                    Analytics.logEvent("upsell_paywall_closed", parameters: nil)
                    onClose()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                }
                .padding(.leading, 8)
                .padding(.top, 8 + geometry.safeAreaInsets.top)
                .opacity(showCloseButton ? 0.15 : 0)
                .disabled(!showCloseButton)
            }
            .offset(x: slideOffset)
            .onAppear {
                withAnimation(.timingCurve(0.25, 0.46, 0.45, 0.94, duration: 0.35)) {
                    slideOffset = 0
                }
                Analytics.logEvent("upsell_paywall_viewed", parameters: nil)
                startGlowAnimation()
                showCloseButton = true
            }
        }
    }

    // MARK: - Reviews

    private var reviewsSection: some View {
        VStack(spacing: 16) {
            Text("Trusted by Pilots & Travelers")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color.white.opacity(0.9))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    upsellReviewCard(
                        text: "Super Pro predictions saved my nervous flyer wife. The 14-day forecast let us plan around bad weather.",
                        author: "Mike T., Pilot"
                    )
                    upsellReviewCard(
                        text: "Night and day difference from basic. The accuracy on transatlantic routes is incredible.",
                        author: "Capt. Sarah W."
                    )
                    upsellReviewCard(
                        text: "Worth every penny. I check the extended forecast before booking any flight now.",
                        author: "James R."
                    )
                    upsellReviewCard(
                        text: "Priority PIREP alerts are a game changer. I get real-time updates during my flights.",
                        author: "Anna K."
                    )
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private func upsellReviewCard(text: String, author: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.yellow)
                }
            }

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(Color.white.opacity(0.85))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            Text("— \(author)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.cyan.opacity(0.7))
        }
        .padding(16)
        .frame(width: 260)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    // MARK: - Price text

    private var priceText: Text {
        Text("Then ")
            .foregroundColor(.gray)
        + Text("$39.99")
            .foregroundColor(.gray)
            .strikethrough(true, color: .gray)
        + Text(" ")
        + Text(priceString)
            .foregroundColor(.white)
            .fontWeight(.semibold)
        + Text("/month")
            .foregroundColor(.gray)
    }

    // MARK: - Purchase

    private func handlePurchase() {
        guard !isPurchasing else { return }
        Analytics.logEvent("upsell_cta_clicked", parameters: nil)
        isPurchasing = true

        if let product = superProProduct {
            Analytics.logEvent("upsell_purchase_started", parameters: ["product_id": product.id])
            Task {
                do {
                    try await subscriptionService.purchase(product)
                    await MainActor.run {
                        isPurchasing = false
                        onSubscribe()
                    }
                } catch {
                    await MainActor.run { isPurchasing = false }
                }
            }
        } else {
            isPurchasing = false
            onSubscribe()
        }
    }

    // MARK: - Feature Row

    private func upsellFeatureRow(icon: String, title: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 26))
                .foregroundColor(.blue)
                .frame(width: 26)

            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)

            Spacer()
        }
    }

    // MARK: - Glow animation

    private func startGlowAnimation() {
        Task {
            while true {
                withAnimation(.easeInOut(duration: 2.5)) { glowAlpha = 0.5 }
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                withAnimation(.easeInOut(duration: 2.5)) { glowAlpha = 0.2 }
                try? await Task.sleep(nanoseconds: 2_500_000_000)
            }
        }
    }
}

#Preview {
    UpsellPaywallScreen(onClose: {}, onSubscribe: {})
        .environmentObject(SubscriptionService())
}
