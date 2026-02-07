import SwiftUI

struct SettingsView: View {
    @AppStorage("useMetricAltitude") private var useMetricAltitude = false
    @AppStorage("autoRefreshEnabled") private var autoRefreshEnabled = true
    @AppStorage("refreshIntervalMinutes") private var refreshIntervalMinutes = 5
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("notifyHoursBefore") private var notifyHoursBefore = 24

    @StateObject private var notificationService = NotificationService.shared
    @State private var pendingCount = 0

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Flight Reminders", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { enabled in
                            if enabled {
                                Task {
                                    let granted = await notificationService.requestPermission()
                                    if !granted { notificationsEnabled = false }
                                }
                            } else {
                                notificationService.removeAllReminders()
                            }
                        }

                    if notificationsEnabled {
                        Picker("Remind me", selection: $notifyHoursBefore) {
                            Text("12 hours before").tag(12)
                            Text("24 hours before").tag(24)
                            Text("48 hours before").tag(48)
                        }

                        HStack {
                            Text("Scheduled reminders")
                            Spacer()
                            Text("\(pendingCount)")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Get a turbulence update before your flight with the latest forecast for your route.")
                }

                Section("Units") {
                    Picker("Altitude Units", selection: $useMetricAltitude) {
                        Text("Feet (ft)").tag(false)
                        Text("Meters (m)").tag(true)
                    }
                }

                Section("Data Refresh") {
                    Toggle("Auto Refresh", isOn: $autoRefreshEnabled)

                    if autoRefreshEnabled {
                        Picker("Refresh Interval", selection: $refreshIntervalMinutes) {
                            Text("2 minutes").tag(2)
                            Text("5 minutes").tag(5)
                            Text("10 minutes").tag(10)
                            Text("15 minutes").tag(15)
                        }
                    }
                }

                Section("Data Sources") {
                    Link(destination: URL(string: "https://aviationweather.gov")!) {
                        HStack {
                            Label("Aviation Weather Center", systemImage: "cloud.sun.fill")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Label("PIREPs", systemImage: "airplane.circle")
                        Text("Pilot reports of turbulence encounters")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)

                    VStack(alignment: .leading, spacing: 8) {
                        Label("SIGMETs", systemImage: "exclamationmark.triangle")
                        Text("Significant meteorological information for aviation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)

                    VStack(alignment: .leading, spacing: 8) {
                        Label("G-AIRMETs", systemImage: "map")
                        Text("Graphical Airmens Meteorological Information")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("App")
                        Spacer()
                        Text("TurboTrack")
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Disclaimer")
                            .font(.subheadline.bold())
                        Text("This app is for informational purposes only. Not for flight planning or navigation. Always consult official aviation weather services for flight operations.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Settings")
            .task {
                pendingCount = await notificationService.pendingCount()
            }
        }
    }
}

#Preview {
    SettingsView()
}
