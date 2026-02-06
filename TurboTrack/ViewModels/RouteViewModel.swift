import SwiftUI
import MapKit

@MainActor
class RouteViewModel: ObservableObject {
    @Published var departureText = ""
    @Published var arrivalText = ""
    @Published var departureAirport: Airport?
    @Published var arrivalAirport: Airport?
    @Published var routePireps: [PIREPReport] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showRoute = false

    // Suggestions
    @Published var departureSuggestions: [Airport] = []
    @Published var arrivalSuggestions: [Airport] = []

    @Published var cameraPosition: MapCameraPosition = .userLocation(fallback: .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 41.3851, longitude: 2.1734),
            span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 30)
        )
    ))

    private let weatherService = AviationWeatherService.shared

    var routePolyline: [CLLocationCoordinate2D] {
        guard let dep = departureAirport, let arr = arrivalAirport else { return [] }
        return [dep.coordinate, arr.coordinate]
    }

    var turbulenceSummary: String {
        guard !routePireps.isEmpty else { return "No turbulence reports along route" }

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
        // Resolve airports from text
        if departureAirport == nil {
            departureAirport = Airport.findByQuery(departureText)
        }
        if arrivalAirport == nil {
            arrivalAirport = Airport.findByQuery(arrivalText)
        }

        guard let dep = departureAirport else {
            errorMessage = "Can't find departure airport for '\(departureText)'"
            return
        }
        guard let arr = arrivalAirport else {
            errorMessage = "Can't find arrival airport for '\(arrivalText)'"
            return
        }

        departureText = dep.displayName
        arrivalText = arr.displayName
        departureSuggestions = []
        arrivalSuggestions = []

        isLoading = true
        errorMessage = nil

        do {
            let allPireps = try await weatherService.fetchPIREPs(hoursBack: 6)
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

            showRoute = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

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

    func clearRoute() {
        departureText = ""
        arrivalText = ""
        departureAirport = nil
        arrivalAirport = nil
        routePireps = []
        showRoute = false
        errorMessage = nil
        departureSuggestions = []
        arrivalSuggestions = []

        cameraPosition = .userLocation(fallback: .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 41.3851, longitude: 2.1734),
                span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 30)
            )
        ))
    }
}
