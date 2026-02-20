import SwiftUI
import StoreKit
import FirebaseAnalytics
import FirebaseRemoteConfig

struct PaywallView: View {
    @EnvironmentObject var subscriptionService: SubscriptionService

    @State private var showCloseButton = false
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showRestoreAlert = false
    @State private var restoreSuccess = false

    let source: String
    let onComplete: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isIPad: Bool { horizontalSizeClass == .regular }

    // Theme
    private let accent = Color(red: 0.20, green: 0.50, blue: 0.95)
    private let accentLight = Color(red: 0.40, green: 0.65, blue: 1.0)
    private let primaryText = Color(red: 0.11, green: 0.11, blue: 0.12)
    private let secondaryText = Color(red: 0.53, green: 0.53, blue: 0.55)
    private let cardBg = Color.white
    private let background = Color(red: 0.96, green: 0.96, blue: 0.97)

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 16)

                    // Title centered + close button overlaid top-right
                    ZStack(alignment: .trailing) {
                        Text("Fly Calm, Every Time")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(primaryText)
                            .frame(maxWidth: .infinity)

                        if showCloseButton {
                            Button {
                                Analytics.logEvent("paywall_dismissed", parameters: ["source": source])
                                onComplete()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(secondaryText.opacity(0.5))
                                    .frame(width: 36, height: 36)
                                    .background(Color(.systemGray6))
                                    .clipShape(Circle())
                            }
                            .transition(.opacity)
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 12)

                    beforeAfterSection
                        .padding(.horizontal, 24)

                    Spacer().frame(height: 20)

                    Text("How Your Trial Works")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(primaryText)

                    Spacer().frame(height: 14)

                    timelineSection
                        .padding(.horizontal, 40)

                    Spacer().frame(height: 20)

                    weeklyPlanCard
                        .padding(.horizontal, 24)

                    Spacer().frame(height: 12)

                    moneyBackBadge

                    Spacer().frame(height: 12)

                    subscribeButton

                    Spacer().frame(height: 10)

                    restoreButton

                    Spacer().frame(height: 50)

                    featuresSection

                    Spacer().frame(height: 50)

                    reviewsSection

                    Spacer().frame(height: 40)

                    featuresCarouselSection

                    Spacer().frame(height: 40)

                    termsSection

                    Spacer().frame(height: 40)
                }
                .frame(maxWidth: isIPad ? 700 : .infinity)
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            Analytics.logEvent("paywall_shown", parameters: ["source": source])

            let remoteConfig = RemoteConfig.remoteConfig()
            let delay = remoteConfig.configValue(forKey: "turbulence_close_button_delay").numberValue.doubleValue

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeIn(duration: 0.3)) {
                    showCloseButton = true
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert(restoreSuccess ? "Success" : "Not Found", isPresented: $showRestoreAlert) {
            Button("OK", role: .cancel) {
                if restoreSuccess { onComplete() }
            }
        } message: {
            Text(restoreSuccess
                 ? "Your subscription has been restored!"
                 : "No active subscription found. Please subscribe or contact support.")
        }
    }

    // MARK: - Timeline

    private var timelineSection: some View {
        VStack(spacing: 0) {
            timelineStep(
                icon: "checkmark.circle.fill",
                title: "Today",
                description: "Subscribe and unlock all forecasts",
                isFirst: true,
                isLast: false
            )
            timelineStep(
                icon: "airplane.circle.fill",
                title: "Full Access",
                description: "Check any route, any time",
                isFirst: false,
                isLast: false
            )
            timelineStep(
                icon: "shield.checkmark.fill",
                title: "14-Day Guarantee",
                description: "Not satisfied? Get a full refund",
                isFirst: false,
                isLast: false
            )
            timelineStep(
                icon: "arrow.triangle.2.circlepath",
                title: "After 7 Days",
                description: "Renews weekly. Cancel anytime",
                isFirst: false,
                isLast: true
            )
        }
    }

    private func timelineStep(icon: String, title: String, description: String, isFirst: Bool, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                if !isFirst {
                    Rectangle()
                        .fill(accent.opacity(0.3))
                        .frame(width: 2, height: 12)
                }

                ZStack {
                    Circle()
                        .fill(accent.opacity(0.15))
                        .frame(width: 30, height: 30)

                    Image(systemName: icon)
                        .font(.system(size: 13))
                        .foregroundColor(accent)
                }

                if !isLast {
                    Rectangle()
                        .fill(accent.opacity(0.3))
                        .frame(width: 2, height: 14)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                if !isFirst {
                    Spacer().frame(height: 12)
                }
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(primaryText)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(secondaryText)
                    .lineSpacing(1)
            }

            Spacer()
        }
    }

    // MARK: - Before / After

    private var beforeAfterSection: some View {
        Image("paywall_before_after")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(maxWidth: .infinity)
            .frame(height: 170)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
    }

    // MARK: - Weekly Plan Card

    private var weeklyPlanCard: some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                Text(subscriptionService.weeklyProduct?.displayPrice ?? "...")
                    .font(.system(size: 28, weight: .bold))
                Text("/week")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(primaryText)

            Text("Cancel anytime")
                .font(.system(size: 14))
                .foregroundColor(secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(accent.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accent, lineWidth: 2)
        )
    }

    // MARK: - Money Back Guarantee

    private var moneyBackBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "shield.checkmark.fill")
                .font(.system(size: 16))
                .foregroundColor(Color(red: 0.20, green: 0.78, blue: 0.35))

            Text("14-Day Money-Back Guarantee")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(primaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.20, green: 0.78, blue: 0.35).opacity(0.1))
        )
    }

    // MARK: - Subscribe Button

    private var subscribeButton: some View {
        Button {
            purchase()
        } label: {
            Group {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Subscribe")
                        .font(.system(size: 20, weight: .bold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: isIPad ? 440 : .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(colors: [accent, accentLight], startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(28)
            .shadow(color: accent.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(isPurchasing || subscriptionService.isLoading)
        .padding(.horizontal, 32)
    }

    // MARK: - Restore

    private var restoreButton: some View {
        Button {
            restorePurchases()
        } label: {
            Text("Restore Purchases")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(secondaryText)
        }
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(spacing: 24) {
            Text("Fly With Confidence")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(primaryText)

            VStack(spacing: 20) {
                featureRow(icon: "paperplane.fill", title: "Route Turbulence Forecast", description: "Check any route from departure to arrival", highlighted: true)
                featureRow(icon: "calendar.badge.clock", title: "Up to 14-Day Forecasts", description: "Choose 3, 7, or 14-day turbulence predictions")
                featureRow(icon: "airplane.circle.fill", title: "Live Pilot Reports", description: "Real-time PIREPs from pilots around the world")
                featureRow(icon: "chart.bar.fill", title: "Flight Level Breakdown", description: "Detailed analysis at every altitude from FL100 to FL390")
                featureRow(icon: "map.fill", title: "Interactive Turbulence Map", description: "See turbulence hotspots and SIGMETs on a live map")
                featureRow(icon: "bell.fill", title: "Pre-flight Notifications", description: "Get reminded before your flight with the latest forecast")
                featureRow(icon: "cloud.sun.bolt.fill", title: "Real-time Weather Data", description: "Powered by NOAA, FAA, and Open-Meteo")
            }
            .padding(.horizontal, 24)
        }
    }

    private func featureRow(icon: String, title: String, description: String, highlighted: Bool = false) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(highlighted ? accent.opacity(0.15) : Color(.systemGray6))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(primaryText)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(secondaryText)
                    .lineLimit(2)
            }

            Spacer()
        }
    }

    // MARK: - Reviews

    private var reviewsSection: some View {
        VStack(spacing: 24) {
            Text("What Travelers Say")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(primaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    reviewCard(
                        text: "Finally I can check turbulence before I fly. Really helps with my anxiety about flying.",
                        author: "Sarah M."
                    )
                    reviewCard(
                        text: "I use this before every flight. The forecast has been surprisingly accurate!",
                        author: "David K."
                    )
                    reviewCard(
                        text: "The flight level breakdown is very useful for pre-flight planning. Great app!",
                        author: "Capt. James R."
                    )
                    reviewCard(
                        text: "So simple — enter your route and get instant results. Love it!",
                        author: "Emma L."
                    )
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private func reviewCard(text: String, author: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(primaryText)
                .lineSpacing(2)

            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                }
            }

            Text("— \(author)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(secondaryText)
        }
        .padding(20)
        .frame(width: 280)
        .background(cardBg)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    // MARK: - Features Carousel

    private var featuresCarouselSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                featureCarouselCard(emoji: "✈️", title: "Route Forecast", subtitle: "Any departure & arrival")
                featureCarouselCard(emoji: "📊", title: "Flight Levels", subtitle: "FL100 to FL390")
                featureCarouselCard(emoji: "🗺️", title: "Live Map", subtitle: "Real-time turbulence")
                featureCarouselCard(emoji: "👨‍✈️", title: "Pilot Reports", subtitle: "Fresh PIREPs")
                featureCarouselCard(emoji: "🔔", title: "Alerts", subtitle: "Pre-flight reminders")
                featureCarouselCard(emoji: "📅", title: "14-Day Forecast", subtitle: "Plan ahead")
            }
            .padding(.horizontal, 24)
        }
    }

    private func featureCarouselCard(emoji: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Text(emoji)
                .font(.system(size: 40))

            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(primaryText)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.system(size: 13))
                .foregroundColor(secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(width: 200)
        .background(accent.opacity(0.08))
        .cornerRadius(16)
    }

    // MARK: - Terms

    private var termsSection: some View {
        VStack(spacing: 8) {
            Text("Payment will be charged to your Apple ID account at the confirmation of purchase. Subscription automatically renews unless it is cancelled at least 24 hours before the end of the current period. Your account will be charged for renewal within 24 hours prior to the end of the current period.")
                .font(.system(size: 11))
                .foregroundColor(secondaryText.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            HStack(spacing: 16) {
                Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                Link("Privacy Policy", destination: URL(string: "https://britetodo.com/legal/PrivacyPolicyBrite.pdf")!)
            }
            .font(.system(size: 12))
            .foregroundColor(secondaryText)
        }
    }

    // MARK: - Actions

    private func purchase() {
        let product = subscriptionService.weeklyProduct

        guard let product = product else {
            errorMessage = "Product not available. Please try again."
            showError = true
            return
        }

        isPurchasing = true

        Task {
            do {
                try await subscriptionService.purchase(product)
                isPurchasing = false
                onComplete()
            } catch PurchaseError.userCancelled {
                isPurchasing = false
            } catch {
                isPurchasing = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func restorePurchases() {
        Task {
            do {
                try await subscriptionService.restore()
                restoreSuccess = subscriptionService.isPro
                showRestoreAlert = true
            } catch {
                restoreSuccess = false
                showRestoreAlert = true
            }
        }
    }
}

#Preview {
    PaywallView(source: "preview", onComplete: {})
        .environmentObject(SubscriptionService())
}
