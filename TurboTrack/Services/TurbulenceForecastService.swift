import Foundation
import CoreLocation

// MARK: - Forecast Service

actor TurbulenceForecastService {

    static let shared = TurbulenceForecastService()

    private let baseURL = "https://api.open-meteo.com/v1/forecast"
    private let session: URLSession

    /// Pressure levels mapped to approximate flight levels (standard atmosphere).
    /// 200 hPa ≈ FL390, 250 hPa ≈ FL340, 300 hPa ≈ FL300,
    /// 400 hPa ≈ FL240, 500 hPa ≈ FL180, 700 hPa ≈ FL100.
    private static let pressureLevels: [(hPa: Int, fl: Int)] = [
        (200, 390),
        (250, 340),
        (300, 300),
        (400, 240),
        (500, 180),
        (700, 100)
    ]

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.requestCachePolicy = .reloadRevalidatingCacheData
        self.session = URLSession(configuration: config)
    }

    // MARK: - Public API

    /// Fetch turbulence forecast along a route between two airports.
    func fetchRouteForecast(
        from departure: CLLocationCoordinate2D,
        to arrival: CLLocationCoordinate2D,
        days: Int = 3
    ) async throws -> TurbulenceForecast {
        let routePoints = generateRoutePoints(from: departure, to: arrival, spacingDegrees: 2.0)
        let forecastPoints = try await fetchForPoints(routePoints, days: days)
        let layers = buildLayers(from: forecastPoints)

        return TurbulenceForecast(id: UUID(), generatedAt: Date(), layers: layers)
    }

    /// Fetch turbulence forecast for a rectangular map region.
    func fetchRegionForecast(
        center: CLLocationCoordinate2D,
        spanLat: Double = 30,
        spanLon: Double = 60,
        days: Int = 3
    ) async throws -> TurbulenceForecast {
        let gridPoints = generateGridPoints(
            center: center,
            spanLat: spanLat,
            spanLon: spanLon,
            step: 5.0
        )
        let forecastPoints = try await fetchForPoints(gridPoints, days: days)
        let layers = buildLayers(from: forecastPoints)

        return TurbulenceForecast(id: UUID(), generatedAt: Date(), layers: layers)
    }

    // MARK: - Fetch & Compute

    private func fetchForPoints(
        _ coordinates: [CLLocationCoordinate2D],
        days: Int
    ) async throws -> [TurbulenceForecastPoint] {
        try await withThrowingTaskGroup(of: [TurbulenceForecastPoint].self) { group in
            for coord in coordinates {
                group.addTask {
                    try await self.fetchUpperAirData(
                        latitude: coord.latitude,
                        longitude: coord.longitude,
                        days: days
                    )
                }
            }
            var all: [TurbulenceForecastPoint] = []
            for try await batch in group {
                all.append(contentsOf: batch)
            }
            return all
        }
    }

    private func fetchUpperAirData(
        latitude: Double,
        longitude: Double,
        days: Int
    ) async throws -> [TurbulenceForecastPoint] {
        // Build hourly parameter list for all pressure levels
        let params = Self.pressureLevels.flatMap { level in
            [
                "wind_speed_\(level.hPa)hPa",
                "wind_direction_\(level.hPa)hPa",
                "temperature_\(level.hPa)hPa",
                "geopotential_height_\(level.hPa)hPa"
            ]
        }

        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "hourly", value: params.joined(separator: ",")),
            URLQueryItem(name: "forecast_days", value: String(days)),
            URLQueryItem(name: "wind_speed_unit", value: "kn")
        ]

        guard let url = components.url else {
            throw ForecastError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw ForecastError.serverError
        }

        let decoded = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        return computeTurbulence(from: decoded, latitude: latitude, longitude: longitude)
    }

    // MARK: - Turbulence Computation

    private func computeTurbulence(
        from response: OpenMeteoResponse,
        latitude: Double,
        longitude: Double
    ) -> [TurbulenceForecastPoint] {
        guard let hourly = response.hourly else { return [] }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")

        var points: [TurbulenceForecastPoint] = []

        for i in 0..<hourly.time.count {
            guard let date = dateFormatter.date(from: hourly.time[i]) else { continue }

            // Gather per-level data for this time step
            let levelData: [(hPa: Int, fl: Int, speed: Double, dir: Double, temp: Double, geoH: Double)] =
                Self.pressureLevels.compactMap { level in
                    guard let speed = hourly.value(for: "wind_speed_\(level.hPa)hPa", at: i),
                          let dir   = hourly.value(for: "wind_direction_\(level.hPa)hPa", at: i),
                          let temp  = hourly.value(for: "temperature_\(level.hPa)hPa", at: i),
                          let geoH  = hourly.value(for: "geopotential_height_\(level.hPa)hPa", at: i)
                    else { return nil }
                    return (level.hPa, level.fl, speed, dir, temp, geoH)
                }

            // Compute vertical wind shear between each adjacent pair
            for j in 0..<(levelData.count - 1) {
                let upper = levelData[j]
                let lower = levelData[j + 1]

                let heightDiffMeters = abs(upper.geoH - lower.geoH)
                guard heightDiffMeters > 0 else { continue }

                let shear = vectorWindShear(
                    upperSpeed: upper.speed, upperDir: upper.dir,
                    lowerSpeed: lower.speed, lowerDir: lower.dir,
                    heightDiffMeters: heightDiffMeters
                )

                let severity = classifySeverity(shear: shear, jetSpeed: upper.speed)
                guard severity != .none else { continue }

                points.append(TurbulenceForecastPoint(
                    id: UUID(),
                    latitude: latitude,
                    longitude: longitude,
                    flightLevel: upper.fl,
                    forecastTime: date,
                    severity: severity,
                    probability: probabilityFromShear(shear, jetSpeed: upper.speed),
                    windShear: shear,
                    jetStreamSpeed: upper.speed,
                    type: .cat
                ))
            }
        }
        return points
    }

    // MARK: - Wind Shear Math

    /// Vector wind shear magnitude in knots per 1 000 ft.
    private func vectorWindShear(
        upperSpeed: Double, upperDir: Double,
        lowerSpeed: Double, lowerDir: Double,
        heightDiffMeters: Double
    ) -> Double {
        let toRad = Double.pi / 180
        // Decompose into u/v components (meteorological convention)
        let uU = -upperSpeed * sin(upperDir * toRad)
        let vU = -upperSpeed * cos(upperDir * toRad)
        let uL = -lowerSpeed * sin(lowerDir * toRad)
        let vL = -lowerSpeed * cos(lowerDir * toRad)

        let shearMag = sqrt(pow(uU - uL, 2) + pow(vU - vL, 2))
        let heightFt = heightDiffMeters * 3.28084
        guard heightFt > 0 else { return 0 }
        return shearMag / (heightFt / 1000)
    }

    /// Map effective wind shear to turbulence severity (FAA-aligned thresholds).
    private func classifySeverity(shear: Double, jetSpeed: Double) -> TurbulenceSeverity {
        let effective = shear * jetStreamFactor(jetSpeed)
        switch effective {
        case 8...:   return .severe
        case 6..<8:  return .moderate
        case 4..<6:  return .light
        default:     return .none
        }
    }

    private func probabilityFromShear(_ shear: Double, jetSpeed: Double) -> Double {
        let effective = shear * jetStreamFactor(jetSpeed)
        return min(1.0, max(0.0, (effective - 2) / 10))
    }

    /// Jet-stream proximity amplifier: stronger jet → higher CAT likelihood.
    private func jetStreamFactor(_ speed: Double) -> Double {
        speed > 80 ? 1.3 : (speed > 60 ? 1.15 : 1.0)
    }

    // MARK: - Grid Generation

    private func generateRoutePoints(
        from dep: CLLocationCoordinate2D,
        to arr: CLLocationCoordinate2D,
        spacingDegrees: Double
    ) -> [CLLocationCoordinate2D] {
        let dLat = arr.latitude - dep.latitude
        let dLon = arr.longitude - dep.longitude
        let dist = sqrt(dLat * dLat + dLon * dLon)
        let steps = max(2, Int(dist / spacingDegrees))

        return (0...steps).map { i in
            let f = Double(i) / Double(steps)
            return CLLocationCoordinate2D(
                latitude: dep.latitude + dLat * f,
                longitude: dep.longitude + dLon * f
            )
        }
    }

    private func generateGridPoints(
        center: CLLocationCoordinate2D,
        spanLat: Double,
        spanLon: Double,
        step: Double
    ) -> [CLLocationCoordinate2D] {
        let minLat = max(-90, center.latitude - spanLat / 2)
        let maxLat = min(90, center.latitude + spanLat / 2)
        let minLon = max(-180, center.longitude - spanLon / 2)
        let maxLon = min(180, center.longitude + spanLon / 2)

        var points: [CLLocationCoordinate2D] = []
        var lat = minLat
        while lat <= maxLat {
            var lon = minLon
            while lon <= maxLon {
                points.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
                lon += step
            }
            lat += step
        }
        return points
    }

    private func buildLayers(from points: [TurbulenceForecastPoint]) -> [TurbulenceForecastLayer] {
        Dictionary(grouping: points) { p in
            "\(Int(p.forecastTime.timeIntervalSince1970))_\(p.flightLevel)"
        }
        .map { _, pts in
            TurbulenceForecastLayer(
                id: UUID(),
                validTime: pts[0].forecastTime,
                flightLevel: pts[0].flightLevel,
                points: pts
            )
        }
        .sorted { $0.validTime < $1.validTime }
    }
}

// MARK: - Open-Meteo Response Models

struct OpenMeteoResponse: Codable {
    let latitude: Double?
    let longitude: Double?
    let hourly: OpenMeteoHourly?
}

/// Dynamic decoder: stores all pressure-level arrays in a dictionary
/// so we don't need a separate property per level.
struct OpenMeteoHourly: Codable {
    let time: [String]
    private let data: [String: [Double?]]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        time = try container.decode([String].self, forKey: DynamicCodingKey("time"))

        var dict: [String: [Double?]] = [:]
        for key in container.allKeys where key.stringValue != "time" {
            if let arr = try? container.decode([Double?].self, forKey: key) {
                dict[key.stringValue] = arr
            }
        }
        data = dict
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKey.self)
        try container.encode(time, forKey: DynamicCodingKey("time"))
        for (key, values) in data {
            try container.encode(values, forKey: DynamicCodingKey(key))
        }
    }

    func value(for key: String, at index: Int) -> Double? {
        guard let arr = data[key], index < arr.count else { return nil }
        return arr[index]
    }
}

private struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    init(_ value: String) { self.stringValue = value }
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { self.intValue = intValue; self.stringValue = "\(intValue)" }
}

// MARK: - Errors

enum ForecastError: LocalizedError {
    case invalidURL
    case serverError
    case decodingError
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid forecast URL"
        case .serverError: return "Forecast server unavailable"
        case .decodingError: return "Failed to decode forecast data"
        case .noData: return "No forecast data available"
        }
    }
}
