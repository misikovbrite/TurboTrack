import SwiftUI

struct SettingsView: View {
    @AppStorage("useMetricAltitude") private var useMetricAltitude = false
    @AppStorage("autoRefreshEnabled") private var autoRefreshEnabled = true
    @AppStorage("refreshIntervalMinutes") private var refreshIntervalMinutes = 5
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("notifyHoursBefore") private var notifyHoursBefore = 24

    @EnvironmentObject var subscriptionService: SubscriptionService
    @StateObject private var notificationService = NotificationService.shared
    @State private var pendingCount = 0
    @State private var showPaywall = false
    @State private var showFAQ = false

    var body: some View {
        NavigationStack {
            List {
                // Subscription section
                Section {
                    if subscriptionService.isPro {
                        HStack {
                            Label("Premium Active", systemImage: "checkmark.seal.fill")
                                .foregroundColor(.green)
                            Spacer()
                        }
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack {
                                Label("Upgrade to Premium", systemImage: "star.fill")
                                    .foregroundColor(.blue)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Subscription")
                }

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

                Section("Learn") {
                    Button {
                        showFAQ = true
                    } label: {
                        HStack {
                            Label("Turbulence Guide", systemImage: "book.fill")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
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

                Section("Support") {
                    Button {
                        openMail()
                    } label: {
                        HStack {
                            Label("Contact Developers", systemImage: "envelope.fill")
                            Spacer()
                            Text("hello@britetodo.com")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                #if DEBUG
                Section("Debug") {
                    Button {
                        subscriptionService.debugSetPro(true)
                    } label: {
                        Label("Enable Premium (Debug)", systemImage: "crown.fill")
                            .foregroundColor(.orange)
                    }

                    Button {
                        subscriptionService.debugSetPro(false)
                    } label: {
                        Label("Disable Premium (Debug)", systemImage: "crown")
                    }

                    Button(role: .destructive) {
                        UserDefaults.standard.set(false, forKey: "onboarding_completed")
                    } label: {
                        Label("Restart Onboarding", systemImage: "arrow.counterclockwise")
                    }
                }
                #endif

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
                        Text("Turbulence Forecast")
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
            .sheet(isPresented: $showPaywall) {
                PaywallView(source: "settings") {
                    showPaywall = false
                }
                .environmentObject(subscriptionService)
            }
            .sheet(isPresented: $showFAQ) {
                TurbulenceFAQView()
                    .presentationDetents([.large])
            }
        }
    }
    private func openMail() {
        let subject = "Turbulence Forecast — Feedback"
        let email = "hello@britetodo.com"
        let urlString = "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SubscriptionService())
}
