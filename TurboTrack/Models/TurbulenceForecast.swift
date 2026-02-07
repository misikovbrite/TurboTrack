import Foundation
import CoreLocation

// MARK: - Turbulence Type

enum TurbulenceType: String, Codable, CaseIterable, Identifiable {
    case cat = "CAT"
    case convective = "CONV"
    case mountainWave = "MWT"
    case combined = "ALL"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cat: return "Clear Air"
        case .convective: return "Convective"
        case .mountainWave: return "Mountain Wave"
        case .combined: return "Combined"
        }
    }
}

// MARK: - Forecast Point

struct TurbulenceForecastPoint: Identifiable, Codable, Equatable {
    let id: UUID
    let latitude: Double
    let longitude: Double
    let flightLevel: Int
    let forecastTime: Date
    let severity: TurbulenceSeverity
    let probability: Double
    let windShear: Double
    let jetStreamSpeed: Double
    let type: TurbulenceType

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var altitudeFeet: Int { flightLevel * 100 }

    var altitudeDisplay: String {
        "FL\(flightLevel) (\(altitudeFeet.formatted()) ft)"
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Forecast Layer (one time + altitude slice)

struct TurbulenceForecastLayer: Identifiable, Codable {
    let id: UUID
    let validTime: Date
    let flightLevel: Int
    let points: [TurbulenceForecastPoint]

    var severitySummary: [TurbulenceSeverity: Int] {
        Dictionary(grouping: points, by: \.severity).mapValues(\.count)
    }
}

// MARK: - Complete Forecast

struct TurbulenceForecast: Identifiable, Codable {
    let id: UUID
    let generatedAt: Date
    let layers: [TurbulenceForecastLayer]

    var forecastHorizonHours: Int {
        guard let last = layers.map(\.validTime).max() else { return 0 }
        return Int(last.timeIntervalSince(generatedAt) / 3600)
    }

    var worstSeverity: TurbulenceSeverity {
        layers.flatMap(\.points)
            .map(\.severity)
            .max { $0.sortOrder < $1.sortOrder } ?? .none
    }

    func layers(for flightLevel: Int) -> [TurbulenceForecastLayer] {
        layers.filter { $0.flightLevel == flightLevel }
    }

    func layers(at time: Date, tolerance: TimeInterval = 3600) -> [TurbulenceForecastLayer] {
        layers.filter { abs($0.validTime.timeIntervalSince(time)) <= tolerance }
    }

    func points(along route: [CLLocationCoordinate2D], corridorNM: Double = 100) -> [TurbulenceForecastPoint] {
        let corridorMeters = corridorNM * 1852
        return layers.flatMap(\.points).filter { point in
            route.contains { waypoint in
                CLLocation(latitude: point.latitude, longitude: point.longitude)
                    .distance(from: CLLocation(latitude: waypoint.latitude, longitude: waypoint.longitude)) <= corridorMeters
            }
        }
    }

    func dailySummary() -> [(date: Date, worst: TurbulenceSeverity, count: Int)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: layers.flatMap(\.points)) { point in
            calendar.startOfDay(for: point.forecastTime)
        }
        return grouped.map { date, points in
            let worst = points.map(\.severity).max { $0.sortOrder < $1.sortOrder } ?? .none
            return (date, worst, points.count)
        }.sorted { $0.date < $1.date }
    }

    static let empty = TurbulenceForecast(id: UUID(), generatedAt: Date(), layers: [])
}
