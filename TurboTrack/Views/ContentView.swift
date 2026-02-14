import SwiftUI

struct ContentView: View {
    @AppStorage("onboarding_completed") private var onboardingCompleted = false
    @EnvironmentObject var subscriptionService: SubscriptionService
    @State private var showPaywall = false
    @State private var paywallDismissedThisSession = false

    private var shouldShowPaywall: Bool {
        if subscriptionService.isPro { return false }
        if paywallDismissedThisSession { return false }
        return showPaywall || !subscriptionService.isPro
    }

    var body: some View {
        if !onboardingCompleted {
            OnboardingView {
                withAnimation {
                    onboardingCompleted = true
                    showPaywall = true
                }
            }
        } else if shouldShowPaywall {
            PaywallView(source: showPaywall ? "onboarding" : "app_launch") {
                withAnimation {
                    showPaywall = false
                    paywallDismissedThisSession = true
                }
            }
            .environmentObject(subscriptionService)
        } else {
            TabView {
                TurbulenceMapView()
                    .tabItem {
                        Label("Map", systemImage: "map.fill")
                    }

                RouteInputView()
                    .tabItem {
                        Label("Forecast", systemImage: "airplane")
                    }

                ReportsListView()
                    .tabItem {
                        Label("Reports", systemImage: "list.bullet.rectangle")
                    }
            }
            .tint(.blue)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SubscriptionService())
}
