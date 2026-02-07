import SwiftUI

struct ContentView: View {
    @AppStorage("onboarding_completed") private var onboardingCompleted = false

    var body: some View {
        if onboardingCompleted {
            TabView {
                TurbulenceMapView()
                    .tabItem {
                        Label("Map", systemImage: "map.fill")
                    }

                ReportsListView()
                    .tabItem {
                        Label("Reports", systemImage: "list.bullet.rectangle")
                    }

                RouteInputView()
                    .tabItem {
                        Label("Forecast", systemImage: "airplane")
                    }

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
            .tint(.blue)
        } else {
            OnboardingView {
                withAnimation {
                    onboardingCompleted = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
