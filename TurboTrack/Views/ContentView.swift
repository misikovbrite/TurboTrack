import SwiftUI

struct ContentView: View {
    var body: some View {
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
                    Label("Route", systemImage: "airplane")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .tint(.blue)
    }
}

#Preview {
    ContentView()
}
