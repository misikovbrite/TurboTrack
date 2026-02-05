import Foundation

actor AviationWeatherService {
    static let shared = AviationWeatherService()

    private let baseURL = "https://aviationweather.gov/api/data"
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.requestCachePolicy = .reloadRevalidatingCacheData
        self.session = URLSession(configuration: config)
    }

    // MARK: - PIREPs
    // Requires either bbox or id+dist parameter
    // Uses multiple station queries to cover continental US

    func fetchPIREPs(hoursBack: Int = 6) async throws -> [PIREPReport] {
        // Query multiple major stations to cover the US
        let stations = ["KJFK", "KLAX", "KORD", "KATL", "KDEN", "KDFW", "KSFO", "KSEA", "KMIA", "KBOS"]
        var allReports: [PIREPReport] = []

        await withTaskGroup(of: [PIREPReport].self) { group in
            for station in stations {
                group.addTask {
                    do {
                        return try await self.fetchPIREPsForStation(station: station, hoursBack: hoursBack, distance: 500)
                    } catch {
                        print("Failed to fetch PIREPs for \(station): \(error)")
                        return []
                    }
                }
            }

            for await reports in group {
                allReports.append(contentsOf: reports)
            }
        }

        // Deduplicate by rawText
        var seen = Set<String>()
        return allReports.filter { report in
            guard let raw = report.rawText else { return true }
            if seen.contains(raw) { return false }
            seen.insert(raw)
            return report.coordinate != nil
        }
    }

    private func fetchPIREPsForStation(station: String, hoursBack: Int, distance: Int) async throws -> [PIREPReport] {
        let urlString = "\(baseURL)/pirep?format=json&age=\(hoursBack)&id=\(station)&dist=\(distance)"
        guard let url = URL(string: urlString) else {
            throw WeatherServiceError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WeatherServiceError.serverError
        }

        // 204 = no data available
        if httpResponse.statusCode == 204 || data.isEmpty {
            return []
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw WeatherServiceError.serverError
        }

        do {
            return try JSONDecoder().decode([PIREPReport].self, from: data)
        } catch {
            print("PIREP decode error for \(station): \(error)")
            return []
        }
    }

    // MARK: - International SIGMETs (includes turbulence SIGMETs)

    func fetchAirSigmets() async throws -> [AirSigmet] {
        let urlString = "\(baseURL)/isigmet?format=json"
        guard let url = URL(string: urlString) else {
            throw WeatherServiceError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WeatherServiceError.serverError
        }

        if httpResponse.statusCode == 204 || data.isEmpty {
            return []
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw WeatherServiceError.serverError
        }

        do {
            let allSigmets = try JSONDecoder().decode([AirSigmet].self, from: data)
            return allSigmets.filter { $0.isTurbulence }
        } catch {
            print("SIGMET decode error: \(error)")
            return []
        }
    }
}

// MARK: - Errors

enum WeatherServiceError: LocalizedError {
    case invalidURL
    case serverError
    case decodingError
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL"
        case .serverError: return "Server returned an error"
        case .decodingError: return "Failed to parse weather data"
        case .noData: return "No data available"
        }
    }
}
