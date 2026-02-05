import SwiftUI
import MapKit

@MainActor
class RouteViewModel: ObservableObject {
    @Published var departureCode = ""
    @Published var arrivalCode = ""
    @Published var departureAirport: Airport?
    @Published var arrivalAirport: Airport?
    @Published var routePireps: [PIREPReport] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showRoute = false

    @Published var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
            span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 40)
        )
    )

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

    func searchRoute() async {
        let depCode = departureCode.uppercased().trimmingCharacters(in: .whitespaces)
        let arrCode = arrivalCode.uppercased().trimmingCharacters(in: .whitespaces)

        guard !depCode.isEmpty, !arrCode.isEmpty else {
            errorMessage = "Please enter both departure and arrival ICAO codes"
            return
        }

        guard let dep = Airport.find(icao: depCode) else {
            errorMessage = "Departure airport '\(depCode)' not found"
            return
        }

        guard let arr = Airport.find(icao: arrCode) else {
            errorMessage = "Arrival airport '\(arrCode)' not found"
            return
        }

        departureAirport = dep
        arrivalAirport = arr
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

        // Project point onto line segment
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
        departureCode = ""
        arrivalCode = ""
        departureAirport = nil
        arrivalAirport = nil
        routePireps = []
        showRoute = false
        errorMessage = nil

        cameraPosition = .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
                span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 40)
            )
        )
    }
}
