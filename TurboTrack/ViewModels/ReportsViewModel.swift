import Foundation

@MainActor
class ReportsViewModel: ObservableObject {
    @Published var reports: [PIREPReport] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedSeverityFilter: TurbulenceSeverity?

    private let weatherService = AviationWeatherService.shared

    var filteredReports: [PIREPReport] {
        var result = reports

        // Filter by severity
        if let severity = selectedSeverityFilter {
            result = result.filter { $0.severity == severity }
        }

        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { report in
                let text = searchText.uppercased()
                if let raw = report.rawText?.uppercased(), raw.contains(text) { return true }
                if let aircraft = report.aircraftType?.uppercased(), aircraft.contains(text) { return true }
                return false
            }
        }

        // Sort by time (most recent first)
        return result.sorted { r1, r2 in
            let d1 = r1.observationDate ?? Date.distantPast
            let d2 = r2.observationDate ?? Date.distantPast
            return d1 > d2
        }
    }

    func loadReports() async {
        isLoading = true
        errorMessage = nil

        do {
            reports = try await weatherService.fetchPIREPs(hoursBack: 12)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func clearFilters() {
        searchText = ""
        selectedSeverityFilter = nil
    }
}
