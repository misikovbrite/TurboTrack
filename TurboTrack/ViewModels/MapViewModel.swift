import SwiftUI
import MapKit
import Combine

@MainActor
class MapViewModel: ObservableObject {
    @Published var pireps: [PIREPReport] = []
    @Published var airSigmets: [AirSigmet] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedReport: PIREPReport?
    @Published var showDetail = false

    // Altitude filter (in feet)
    @Published var altitudeFilterLow: Double = 10000
    @Published var altitudeFilterHigh: Double = 45000
    @Published var altitudeFilterEnabled = false

    // Camera — start with userLocation, fallback handled in init
    @Published var cameraPosition: MapCameraPosition = .userLocation(fallback: .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 41.3851, longitude: 2.1734), // Barcelona
            span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 30)
        )
    ))

    let locationService = LocationService()
    private let weatherService = AviationWeatherService.shared
    private var refreshTimer: Timer?

    init() {
        locationService.requestPermission()
    }

    var filteredPireps: [PIREPReport] {
        guard altitudeFilterEnabled else { return pireps }
        return pireps.filter { report in
            guard let alt = report.altitudeFeet else { return true }
            return Double(alt) >= altitudeFilterLow && Double(alt) <= altitudeFilterHigh
        }
    }

    var filteredSigmets: [AirSigmet] {
        guard altitudeFilterEnabled else { return airSigmets }
        return airSigmets.filter { sigmet in
            guard let low = sigmet.base, let high = sigmet.top else { return true }
            return Double(high) >= altitudeFilterLow && Double(low) <= altitudeFilterHigh
        }
    }

    func loadData() async {
        isLoading = true
        errorMessage = nil

        async let pirepsTask = weatherService.fetchPIREPs()
        async let sigmetsTask = weatherService.fetchAirSigmets()

        do {
            let (fetchedPireps, fetchedSigmets) = try await (pirepsTask, sigmetsTask)
            pireps = fetchedPireps
            airSigmets = fetchedSigmets
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func selectReport(_ report: PIREPReport) {
        selectedReport = report
        showDetail = true
    }

    func startAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.loadData()
            }
        }
    }

    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}
