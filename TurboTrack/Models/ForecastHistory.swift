import SwiftUI

struct ForecastHistoryEntry: Identifiable, Codable {
    let id: UUID
    let departureICAO: String
    let arrivalICAO: String
    let forecastDays: Int
    let severity: String
    let date: Date
    let viaICAO: String?

    init(id: UUID = UUID(), departureICAO: String, arrivalICAO: String, forecastDays: Int, severity: String, date: Date, viaICAO: String? = nil) {
        self.id = id
        self.departureICAO = departureICAO
        self.arrivalICAO = arrivalICAO
        self.forecastDays = forecastDays
        self.severity = severity
        self.date = date
        self.viaICAO = viaICAO
    }

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

    var routeDisplay: String {
        if let via = viaICAO {
            return "\(departureICAO) → \(via) → \(arrivalICAO)"
        }
        return "\(departureICAO) → \(arrivalICAO)"
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

    func addEntry(departureICAO: String, arrivalICAO: String, forecastDays: Int, severity: String, viaICAO: String? = nil) {
        // Remove duplicate routes (same dep, arr, and via)
        entries.removeAll {
            $0.departureICAO == departureICAO && $0.arrivalICAO == arrivalICAO && $0.viaICAO == viaICAO
        }

        let entry = ForecastHistoryEntry(
            departureICAO: departureICAO,
            arrivalICAO: arrivalICAO,
            forecastDays: forecastDays,
            severity: severity,
            date: Date(),
            viaICAO: viaICAO
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
