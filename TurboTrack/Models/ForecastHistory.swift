import SwiftUI

struct ForecastHistoryEntry: Identifiable, Codable {
    let id: UUID
    let departureICAO: String
    let arrivalICAO: String
    let forecastDays: Int
    let severity: String
    let date: Date

    var dateFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    var severityColor: Color {
        switch severity.lowercased() {
        case "smooth", "none": return .green
        case "light": return .yellow
        case "moderate": return .orange
        case "severe", "extreme": return .red
        default: return .gray
        }
    }
}

@MainActor
class ForecastHistory: ObservableObject {
    static let shared = ForecastHistory()

    @Published var entries: [ForecastHistoryEntry] = []

    private let key = "forecast_history"
    private let maxEntries = 10

    private init() {
        load()
    }

    func addEntry(departureICAO: String, arrivalICAO: String, forecastDays: Int, severity: String) {
        // Remove duplicate routes
        entries.removeAll { $0.departureICAO == departureICAO && $0.arrivalICAO == arrivalICAO }

        let entry = ForecastHistoryEntry(
            id: UUID(),
            departureICAO: departureICAO,
            arrivalICAO: arrivalICAO,
            forecastDays: forecastDays,
            severity: severity,
            date: Date()
        )

        entries.insert(entry, at: 0)

        // Keep only recent entries
        if entries.count > maxEntries {
            entries = Array(entries.prefix(maxEntries))
        }

        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([ForecastHistoryEntry].self, from: data) else { return }
        entries = decoded
    }
}
