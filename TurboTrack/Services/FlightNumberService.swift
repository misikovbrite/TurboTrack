import Foundation

/// Resolves flight numbers to departure/arrival airports using AeroDataBox API.
/// Caches results on-device for 24 hours to minimize API calls.
@MainActor
final class FlightNumberService: ObservableObject {

    static let shared = FlightNumberService()

    @Published var isLoading = false
    @Published var errorMessage: String?

    // AeroDataBox via RapidAPI — free tier: 600 req/month
    private let rapidAPIKey = "1f130de935msh1ef2c824de03bdap1f4263jsn079555a14636"
    private let rapidAPIHost = "aerodatabox.p.rapidapi.com"

    private let cacheKey = "flight_number_cache"
    private let cacheTTL: TimeInterval = 86400 // 24 hours

    struct FlightRoute: Codable {
        let departureICAO: String
        let arrivalICAO: String
        let departureCity: String
        let arrivalCity: String
        let airline: String
        let cachedAt: Date
    }

    // MARK: - Public

    /// Looks up a flight number (e.g. "UA123") and returns departure/arrival ICAO codes.
    func lookupFlight(_ flightNumber: String) async -> FlightRoute? {
        let normalized = flightNumber.uppercased().trimmingCharacters(in: .whitespaces)
        guard !normalized.isEmpty else {
            errorMessage = "Enter a flight number"
            return nil
        }

        // Check cache first
        if let cached = getCachedRoute(for: normalized) {
            return cached
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        // Format date for API: today or tomorrow
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())

        // AeroDataBox flight status endpoint
        let urlString = "https://aerodatabox.p.rapidapi.com/flights/number/\(normalized)/\(today)"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid flight number format"
            return nil
        }

        var request = URLRequest(url: url)
        request.setValue(rapidAPIKey, forHTTPHeaderField: "x-rapidapi-key")
        request.setValue(rapidAPIHost, forHTTPHeaderField: "x-rapidapi-host")
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                errorMessage = "Network error"
                return nil
            }

            if httpResponse.statusCode == 402 || httpResponse.statusCode == 429 {
                errorMessage = "API limit reached. Try again later."
                return nil
            }

            guard httpResponse.statusCode == 200 else {
                errorMessage = "Flight not found"
                return nil
            }

            // Parse AeroDataBox response
            guard let flights = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                  let flight = flights.first else {
                errorMessage = "Flight not found for today"
                return nil
            }

            // Extract departure and arrival
            guard let departure = flight["departure"] as? [String: Any],
                  let arrival = flight["arrival"] as? [String: Any],
                  let depAirport = departure["airport"] as? [String: Any],
                  let arrAirport = arrival["airport"] as? [String: Any] else {
                errorMessage = "Could not parse flight data"
                return nil
            }

            let depICAO = depAirport["icao"] as? String ?? ""
            let arrICAO = arrAirport["icao"] as? String ?? ""
            let depCity = depAirport["municipalityName"] as? String ?? depAirport["name"] as? String ?? ""
            let arrCity = arrAirport["municipalityName"] as? String ?? arrAirport["name"] as? String ?? ""
            let airline = (flight["airline"] as? [String: Any])?["name"] as? String ?? ""

            guard !depICAO.isEmpty, !arrICAO.isEmpty else {
                errorMessage = "Flight route data incomplete"
                return nil
            }

            let route = FlightRoute(
                departureICAO: depICAO,
                arrivalICAO: arrICAO,
                departureCity: depCity,
                arrivalCity: arrCity,
                airline: airline,
                cachedAt: Date()
            )

            // Cache it
            cacheRoute(route, for: normalized)
            return route

        } catch {
            errorMessage = "Network error. Check your connection."
            return nil
        }
    }

    // MARK: - Cache

    private func getCachedRoute(for flightNumber: String) -> FlightRoute? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let cache = try? JSONDecoder().decode([String: FlightRoute].self, from: data),
              let route = cache[flightNumber],
              Date().timeIntervalSince(route.cachedAt) < cacheTTL else {
            return nil
        }
        return route
    }

    private func cacheRoute(_ route: FlightRoute, for flightNumber: String) {
        var cache: [String: FlightRoute] = [:]
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let existing = try? JSONDecoder().decode([String: FlightRoute].self, from: data) {
            cache = existing
        }

        // Remove expired entries
        cache = cache.filter { Date().timeIntervalSince($0.value.cachedAt) < cacheTTL }

        cache[flightNumber] = route

        if let data = try? JSONEncoder().encode(cache) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }
}
