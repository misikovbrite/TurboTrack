import SwiftUI
import FirebaseCore
import FirebaseRemoteConfig

@main
struct TurboTrackApp: App {
    @StateObject private var subscriptionService = SubscriptionService()

    init() {
        FirebaseApp.configure()
        setupRemoteConfig()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(subscriptionService)
                .preferredColorScheme(.light)
        }
    }

    private func setupRemoteConfig() {
        let remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 3600 // 1 hour
        remoteConfig.configSettings = settings

        remoteConfig.setDefaults([
            "turbulence_close_button_delay": NSNumber(value: 3.0)
        ])

        remoteConfig.fetchAndActivate { _, _ in }
    }
}
