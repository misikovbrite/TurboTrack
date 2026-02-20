import SwiftUI
import MapKit

@MainActor
class RouteViewModel: ObservableObject {

    // MARK: - Input

    @Published var departureText = ""
    @Published var arrivalText = ""
    @Published var departureAirport: Airport?
    @Published var arrivalAirport: Airport?
    @Published var departureSuggestions: [Airport] = []
    @Published var arrivalSuggestions: [Airport] = []

    // MARK: - State

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showRoute = false
    @Published var showNotificationPrompt = false
    @Published var flightDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @Published var notificationScheduled = false
    @Published var forecastDays: Int = 3

    // MARK: - Analysis State

    @Published var isAnalyzing = false
    @Published var analysisPhase: Int = 0
    @Published var analysisStartTime: Date?
    @Published var dataReady = false
    @Published var showStory = false

    static let availableForecastDays = [3, 7, 14]

    // MARK: - Results

    @Published var routePireps: [PIREPReport] = []
    @Published var forecast: TurbulenceForecast?
    @Published var cameraPosition: MapCameraPosition = .userLocation(fallback: .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 41.3851, longitude: 2.1734),
            span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 30)
        )
    ))

    private let weatherService = AviationWeatherService.shared
    private let forecastService = TurbulenceForecastService.shared

    // MARK: - Computed: Route

    var routePolyline: [CLLocationCoordinate2D] {
        guard let dep = departureAirport, let arr = arrivalAirport else { return [] }
        return [dep.coordinate, arr.coordinate]
    }

    var routeTitle: String {
        let dep = departureAirport?.icao ?? "???"
        let arr = arrivalAirport?.icao ?? "???"
        return "\(dep) → \(arr)"
    }

    // MARK: - Computed: Forecast

    var forecastSeverity: TurbulenceSeverity {
        forecast?.worstSeverity ?? .none
    }

    var forecastHorizonText: String {
        return "\(forecastDays)-day forecast"
    }

    var forecastAdvice: (title: String, detail: String, icon: String, color: Color) {
        switch forecastSeverity {
        case .none:
            return (
                "Smooth Flight Expected",
                "No significant turbulence is forecasted along your route. Enjoy your flight! Keep your seatbelt loosely fastened as a precaution.",
                "checkmark.seal.fill",
                .green
            )
        case .light:
            return (
                "Light Turbulence Possible",
                "Minor bumps may occur on parts of your route. This is very common and not dangerous. Keep your seatbelt fastened when seated.",
                "cloud.fill",
                .yellow
            )
        case .moderate:
            return (
                "Moderate Turbulence Expected",
                "Expect noticeable bumps along your route. Walking may be difficult at times. Keep your seatbelt fastened, secure loose items, and follow crew instructions.",
                "cloud.bolt.fill",
                .orange
            )
        case .severe, .extreme:
            return (
                "Significant Turbulence Forecasted",
                "Strong turbulence is predicted on your route. Keep your seatbelt tightly fastened at all times, secure all loose items, and follow crew instructions carefully.",
                "exclamationmark.triangle.fill",
                .red
            )
        }
    }

    var dailyForecast: [(date: Date, worst: TurbulenceSeverity, count: Int)] {
        forecast?.dailySummary() ?? []
    }

    var flightLevelBreakdown: [(level: Int, severity: TurbulenceSeverity, avgShear: Double, maxJet: Double)] {
        guard let forecast else { return [] }
        let allPoints = forecast.layers.flatMap(\.points)
        let grouped = Dictionary(grouping: allPoints, by: \.flightLevel)
        return grouped.map { level, points in
            let worst = points.map(\.severity).max { $0.sortOrder < $1.sortOrder } ?? .none
            let avgShear = points.map(\.windShear).reduce(0, +) / Double(max(points.count, 1))
            let maxJet = points.map(\.jetStreamSpeed).max() ?? 0
            return (level, worst, avgShear, maxJet)
        }.sorted { $0.level > $1.level }
    }

    /// Aggregated forecast points for map — one per location, worst severity.
    var forecastMapPoints: [TurbulenceForecastPoint] {
        guard let forecast else { return [] }
        let allPoints = forecast.layers.flatMap(\.points)
        let grouped = Dictionary(grouping: allPoints) {
            "\(Int($0.latitude * 10))_\(Int($0.longitude * 10))"
        }
        return grouped.compactMap { _, points in
            points.max { $0.severity.sortOrder < $1.severity.sortOrder }
        }
    }

    var pirepSummary: String {
        guard !routePireps.isEmpty else { return "No recent pilot reports along this route" }
        let severe = routePireps.filter { $0.severity == .severe || $0.severity == .extreme }.count
        let moderate = routePireps.filter { $0.severity == .moderate }.count
        let light = routePireps.filter { $0.severity == .light }.count
        var parts: [String] = []
        if severe > 0 { parts.append("\(severe) severe") }
        if moderate > 0 { parts.append("\(moderate) moderate") }
        if light > 0 { parts.append("\(light) light") }
        return "\(routePireps.count) reports: \(parts.joined(separator: ", "))"
    }

    // MARK: - Suggestions

    func updateDepartureSuggestions() {
        if departureAirport != nil && departureText == departureAirport?.displayName {
            departureSuggestions = []
            return
        }
        departureSuggestions = Airport.search(departureText)
    }

    func updateArrivalSuggestions() {
        if arrivalAirport != nil && arrivalText == arrivalAirport?.displayName {
            arrivalSuggestions = []
            return
        }
        arrivalSuggestions = Airport.search(arrivalText)
    }

    func selectDeparture(_ airport: Airport) {
        departureAirport = airport
        departureText = airport.displayName
        departureSuggestions = []
    }

    func selectArrival(_ airport: Airport) {
        arrivalAirport = airport
        arrivalText = airport.displayName
        arrivalSuggestions = []
    }

    // MARK: - Search

    func searchRoute() async {
        // Resolve airports from text if needed
        if departureAirport == nil {
            print("[Route] Resolving departure from text: '\(departureText)'")
            departureAirport = Airport.findByQuery(departureText)
            print("[Route] Departure resolved: \(departureAirport?.displayName ?? "nil")")
        }
        if arrivalAirport == nil {
            print("[Route] Resolving arrival from text: '\(arrivalText)'")
            arrivalAirport = Airport.findByQuery(arrivalText)
            print("[Route] Arrival resolved: \(arrivalAirport?.displayName ?? "nil")")
        }

        guard let dep = departureAirport else {
            errorMessage = "Can't find departure airport for '\(departureText)'"
            print("[Route] ERROR: departure not found for '\(departureText)'")
            return
        }
        guard let arr = arrivalAirport else {
            errorMessage = "Can't find arrival airport for '\(arrivalText)'"
            print("[Route] ERROR: arrival not found for '\(arrivalText)'")
            return
        }

        departureText = dep.displayName
        arrivalText = arr.displayName
        departureSuggestions = []
        arrivalSuggestions = []

        // Clear previous results
        forecast = nil
        routePireps = []
        isLoading = true
        errorMessage = nil
        dataReady = false
        analysisPhase = 0
        analysisStartTime = Date()
        isAnalyzing = true

        // Fetch forecast and PIREPs concurrently
        print("[Route] Fetching forecast: \(dep.icao) → \(arr.icao)")
        let forecastTask = Task {
            do {
                let result = try await forecastService.fetchRouteForecast(
                    from: dep.coordinate, to: arr.coordinate, days: self.forecastDays
                )
                print("[Route] Forecast OK: \(result.layers.count) layers")
                return result as TurbulenceForecast?
            } catch {
                print("[Route] Forecast ERROR: \(error)")
                return nil as TurbulenceForecast?
            }
        }
        let pirepsTask = Task {
            do {
                let pireps = try await weatherService.fetchPIREPs(hoursBack: 6)
                print("[Route] PIREPs OK: \(pireps.count) reports")
                return pireps
            } catch {
                print("[Route] PIREPs ERROR: \(error)")
                return [] as [PIREPReport]
            }
        }

        forecast = await forecastTask.value
        let allPireps = await pirepsTask.value
        routePireps = filterPirepsAlongRoute(pireps: allPireps, from: dep.coordinate, to: arr.coordinate)

        // Zoom to route
        let midLat = (dep.coordinate.latitude + arr.coordinate.latitude) / 2
        let midLon = (dep.coordinate.longitude + arr.coordinate.longitude) / 2
        let latDelta = abs(dep.coordinate.latitude - arr.coordinate.latitude) * 1.4
        let lonDelta = abs(dep.coordinate.longitude - arr.coordinate.longitude) * 1.4

        cameraPosition = .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: midLat, longitude: midLon),
                span: MKCoordinateSpan(
                    latitudeDelta: max(latDelta, 2),
                    longitudeDelta: max(lonDelta, 2)
                )
            )
        )

        if forecast == nil && routePireps.isEmpty {
            errorMessage = "Unable to load forecast data. Check your connection and try again."
            isAnalyzing = false
        } else {
            // Save to history
            ForecastHistory.shared.addEntry(
                departureICAO: dep.icao,
                arrivalICAO: arr.icao,
                forecastDays: forecastDays,
                severity: forecastSeverity.displayName
            )
            if !notificationScheduled {
                showNotificationPrompt = true
            }
        }

        // Data is ready — analysis view will handle timing
        dataReady = true
        isLoading = false
    }

    // MARK: - Notifications

    func scheduleFlightNotification() {
        guard let dep = departureAirport, let arr = arrivalAirport else { return }
        let severity = forecastSeverity.displayName

        Task {
            let service = NotificationService.shared
            if !service.isAuthorized {
                let granted = await service.requestPermission()
                guard granted else {
                    showNotificationPrompt = false
                    return
                }
                UserDefaults.standard.set(true, forKey: "notificationsEnabled")
            }

            service.scheduleFlightReminder(
                departureICAO: dep.icao,
                arrivalICAO: arr.icao,
                flightDate: flightDate,
                severity: severity
            )
            notificationScheduled = true
            showNotificationPrompt = false
        }
    }

    func dismissNotificationPrompt() {
        showNotificationPrompt = false
    }

    // MARK: - Analysis

    func completeAnalysis() {
        isAnalyzing = false
        showStory = true
    }

    func showFullReport() {
        showStory = false
        showRoute = true
    }

    // MARK: - Clear

    func clearRoute() {
        departureText = ""
        arrivalText = ""
        departureAirport = nil
        arrivalAirport = nil
        routePireps = []
        forecast = nil
        showRoute = false
        errorMessage = nil
        departureSuggestions = []
        arrivalSuggestions = []
        showNotificationPrompt = false
        notificationScheduled = false
        forecastDays = 3
        flightDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        isAnalyzing = false
        analysisPhase = 0
        analysisStartTime = nil
        dataReady = false
        showStory = false

        cameraPosition = .userLocation(fallback: .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 41.3851, longitude: 2.1734),
                span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 30)
            )
        ))
    }

    // MARK: - Private

    private func filterPirepsAlongRoute(
        pireps: [PIREPReport],
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D
    ) -> [PIREPReport] {
        let corridorWidth: CLLocationDistance = 185_200 // ~100 nautical miles

        return pireps.filter { report in
            guard let coord = report.coordinate else { return false }
            let distance = distanceFromPointToLine(
                point: coord,
                lineStart: from,
                lineEnd: to
            )
            return distance <= corridorWidth
        }
    }

    private func distanceFromPointToLine(
        point: CLLocationCoordinate2D,
        lineStart: CLLocationCoordinate2D,
        lineEnd: CLLocationCoordinate2D
    ) -> CLLocationDistance {
        let p = CLLocation(latitude: point.latitude, longitude: point.longitude)
        let a = CLLocation(latitude: lineStart.latitude, longitude: lineStart.longitude)
        let b = CLLocation(latitude: lineEnd.latitude, longitude: lineEnd.longitude)

        let ab = b.distance(from: a)
        guard ab > 0 else { return p.distance(from: a) }

        let ap_lat = point.latitude - lineStart.latitude
        let ap_lon = point.longitude - lineStart.longitude
        let ab_lat = lineEnd.latitude - lineStart.latitude
        let ab_lon = lineEnd.longitude - lineStart.longitude

        let t = max(0, min(1, (ap_lat * ab_lat + ap_lon * ab_lon) / (ab_lat * ab_lat + ab_lon * ab_lon)))

        let closestLat = lineStart.latitude + t * ab_lat
        let closestLon = lineStart.longitude + t * ab_lon
        let closest = CLLocation(latitude: closestLat, longitude: closestLon)

        return p.distance(from: closest)
    }
}
