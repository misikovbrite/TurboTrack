import Foundation
import UserNotifications

@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var isAuthorized = false

    private let center = UNUserNotificationCenter.current()

    private init() {
        Task { await checkAuthorization() }
    }

    func checkAuthorization() async {
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            return granted
        } catch {
            return false
        }
    }

    /// Schedule a turbulence update notification for the day before the flight.
    func scheduleFlightReminder(
        departureICAO: String,
        arrivalICAO: String,
        flightDate: Date,
        severity: String
    ) {
        // Notify 24h before flight
        let triggerDate = Calendar.current.date(byAdding: .hour, value: -24, to: flightDate) ?? flightDate
        guard triggerDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Turbulence Update: \(departureICAO) → \(arrivalICAO)"
        content.body = "Your flight tomorrow has a \(severity) turbulence forecast. Open the app for the latest update."
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let id = "flight_\(departureICAO)_\(arrivalICAO)_\(Int(flightDate.timeIntervalSince1970))"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        center.add(request)
    }

    /// Remove all scheduled flight reminders.
    func removeAllReminders() {
        center.removeAllPendingNotificationRequests()
    }

    /// Get count of pending notifications.
    func pendingCount() async -> Int {
        let requests = await center.pendingNotificationRequests()
        return requests.count
    }
}
