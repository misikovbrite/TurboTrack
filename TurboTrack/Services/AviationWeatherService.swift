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

    func fetchPIREPs(hoursBack: Int = 6) async throws -> [PIREPReport] {
        let urlString = "\(baseURL)/pirep?format=json&age=\(hoursBack)&type=turb"
        guard let url = URL(string: urlString) else {
            throw WeatherServiceError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw WeatherServiceError.serverError
        }

        if data.isEmpty { return [] }

        let decoder = JSONDecoder()
        do {
            let reports = try decoder.decode([PIREPReport].self, from: data)
            return reports.filter { $0.coordinate != nil }
        } catch {
            // Try decoding as a wrapper object
            if let wrapper = try? decoder.decode(PIREPWrapper.self, from: data) {
                return wrapper.pireps?.filter { $0.coordinate != nil } ?? []
            }
            print("PIREP decode error: \(error)")
            return []
        }
    }

    // MARK: - SIGMETs / AIRMETs

    func fetchAirSigmets() async throws -> [AirSigmet] {
        let urlString = "\(baseURL)/airsigmet?format=json&hazard=turb"
        guard let url = URL(string: urlString) else {
            throw WeatherServiceError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw WeatherServiceError.serverError
        }

        if data.isEmpty { return [] }

        let decoder = JSONDecoder()
        do {
            let sigmets = try decoder.decode([AirSigmet].self, from: data)
            return sigmets.filter { $0.isTurbulence }
        } catch {
            if let wrapper = try? decoder.decode(AirSigmetWrapper.self, from: data) {
                return wrapper.airsigmets?.filter { $0.isTurbulence } ?? []
            }
            print("AirSigmet decode error: \(error)")
            return []
        }
    }

    // MARK: - G-AIRMETs

    func fetchGAirmets() async throws -> [AirSigmet] {
        let urlString = "\(baseURL)/gairmet?format=json&hazard=turb"
        guard let url = URL(string: urlString) else {
            throw WeatherServiceError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw WeatherServiceError.serverError
        }

        if data.isEmpty { return [] }

        let decoder = JSONDecoder()
        do {
            let airmets = try decoder.decode([AirSigmet].self, from: data)
            return airmets
        } catch {
            print("G-AIRMET decode error: \(error)")
            return []
        }
    }
}

// MARK: - Wrapper types for API response

private struct PIREPWrapper: Codable {
    let pireps: [PIREPReport]?
}

private struct AirSigmetWrapper: Codable {
    let airsigmets: [AirSigmet]?
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
