import Foundation
import CoreLocation

struct Airport: Identifiable, Codable {
    let id: String // ICAO code
    let name: String
    let city: String
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var icao: String { id }

    var displayName: String {
        "\(city) (\(id))"
    }

    /// Search by city name, airport name, or ICAO code
    static func search(_ query: String) -> [Airport] {
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return [] }

        return commonAirports.filter { airport in
            airport.id.lowercased().contains(q) ||
            airport.city.lowercased().contains(q) ||
            airport.name.lowercased().contains(q)
        }
    }

    static func find(icao: String) -> Airport? {
        commonAirports.first { $0.id.uppercased() == icao.uppercased() }
    }

    /// Find by city name or ICAO
    static func findByQuery(_ query: String) -> Airport? {
        let q = query.trimmingCharacters(in: .whitespaces)
        // Try exact ICAO first
        if let exact = find(icao: q) { return exact }
        // Try city match
        let results = search(q)
        return results.first
    }

    static let commonAirports: [Airport] = [
        // US
        Airport(id: "KJFK", name: "John F. Kennedy Intl", city: "New York", latitude: 40.6413, longitude: -73.7781),
        Airport(id: "KLAX", name: "Los Angeles Intl", city: "Los Angeles", latitude: 33.9425, longitude: -118.4081),
        Airport(id: "KORD", name: "O'Hare Intl", city: "Chicago", latitude: 41.9742, longitude: -87.9073),
        Airport(id: "KATL", name: "Hartsfield-Jackson Intl", city: "Atlanta", latitude: 33.6407, longitude: -84.4277),
        Airport(id: "KDFW", name: "Dallas/Fort Worth Intl", city: "Dallas", latitude: 32.8998, longitude: -97.0403),
        Airport(id: "KDEN", name: "Denver Intl", city: "Denver", latitude: 39.8561, longitude: -104.6737),
        Airport(id: "KSFO", name: "San Francisco Intl", city: "San Francisco", latitude: 37.6213, longitude: -122.3790),
        Airport(id: "KSEA", name: "Seattle-Tacoma Intl", city: "Seattle", latitude: 47.4502, longitude: -122.3088),
        Airport(id: "KMIA", name: "Miami Intl", city: "Miami", latitude: 25.7959, longitude: -80.2870),
        Airport(id: "KBOS", name: "Boston Logan Intl", city: "Boston", latitude: 42.3656, longitude: -71.0096),
        Airport(id: "KLAS", name: "Las Vegas Harry Reid Intl", city: "Las Vegas", latitude: 36.0840, longitude: -115.1537),
        Airport(id: "KMSP", name: "Minneapolis-St Paul Intl", city: "Minneapolis", latitude: 44.8848, longitude: -93.2223),
        Airport(id: "KDTW", name: "Detroit Metro Wayne County", city: "Detroit", latitude: 42.2124, longitude: -83.3534),
        Airport(id: "KPHL", name: "Philadelphia Intl", city: "Philadelphia", latitude: 39.8721, longitude: -75.2411),
        Airport(id: "KIAH", name: "George Bush Intercontinental", city: "Houston", latitude: 29.9902, longitude: -95.3368),
        Airport(id: "KPHX", name: "Phoenix Sky Harbor Intl", city: "Phoenix", latitude: 33.4373, longitude: -112.0078),
        Airport(id: "KEWR", name: "Newark Liberty Intl", city: "Newark", latitude: 40.6895, longitude: -74.1745),
        Airport(id: "KMCO", name: "Orlando Intl", city: "Orlando", latitude: 28.4312, longitude: -81.3081),
        Airport(id: "KCLT", name: "Charlotte Douglas Intl", city: "Charlotte", latitude: 35.2140, longitude: -80.9431),
        Airport(id: "KDCA", name: "Ronald Reagan Washington Natl", city: "Washington", latitude: 38.8512, longitude: -77.0402),
        // Europe
        Airport(id: "LEBL", name: "Barcelona El Prat", city: "Barcelona", latitude: 41.2971, longitude: 2.0785),
        Airport(id: "LEMD", name: "Madrid Barajas", city: "Madrid", latitude: 40.4936, longitude: -3.5668),
        Airport(id: "EGLL", name: "London Heathrow", city: "London", latitude: 51.4700, longitude: -0.4543),
        Airport(id: "LFPG", name: "Paris Charles de Gaulle", city: "Paris", latitude: 49.0097, longitude: 2.5479),
        Airport(id: "EDDF", name: "Frankfurt Main", city: "Frankfurt", latitude: 50.0379, longitude: 8.5622),
        Airport(id: "EHAM", name: "Amsterdam Schiphol", city: "Amsterdam", latitude: 52.3086, longitude: 4.7639),
        Airport(id: "LIRF", name: "Rome Fiumicino", city: "Rome", latitude: 41.8003, longitude: 12.2389),
        Airport(id: "EDDM", name: "Munich", city: "Munich", latitude: 48.3538, longitude: 11.7861),
        Airport(id: "LSZH", name: "Zurich", city: "Zurich", latitude: 47.4647, longitude: 8.5492),
        Airport(id: "EKCH", name: "Copenhagen Kastrup", city: "Copenhagen", latitude: 55.6181, longitude: 12.6561),
        Airport(id: "ENGM", name: "Oslo Gardermoen", city: "Oslo", latitude: 60.1939, longitude: 11.1004),
        Airport(id: "ESSA", name: "Stockholm Arlanda", city: "Stockholm", latitude: 59.6519, longitude: 17.9186),
        Airport(id: "EFHK", name: "Helsinki Vantaa", city: "Helsinki", latitude: 60.3172, longitude: 24.9633),
        Airport(id: "LPPT", name: "Lisbon Portela", city: "Lisbon", latitude: 38.7742, longitude: -9.1342),
        Airport(id: "EPWA", name: "Warsaw Chopin", city: "Warsaw", latitude: 52.1657, longitude: 20.9671),
        Airport(id: "LOWW", name: "Vienna Schwechat", city: "Vienna", latitude: 48.1103, longitude: 16.5697),
        Airport(id: "LKPR", name: "Prague Vaclav Havel", city: "Prague", latitude: 50.1008, longitude: 14.2600),
        Airport(id: "EIDW", name: "Dublin", city: "Dublin", latitude: 53.4213, longitude: -6.2701),
        Airport(id: "LGAV", name: "Athens Eleftherios Venizelos", city: "Athens", latitude: 37.9364, longitude: 23.9445),
        Airport(id: "LTFM", name: "Istanbul", city: "Istanbul", latitude: 41.2753, longitude: 28.7519),
        Airport(id: "UUEE", name: "Moscow Sheremetyevo", city: "Moscow", latitude: 55.9726, longitude: 37.4146),
        Airport(id: "EGKK", name: "London Gatwick", city: "London", latitude: 51.1537, longitude: -0.1821),
        Airport(id: "LFPO", name: "Paris Orly", city: "Paris", latitude: 48.7233, longitude: 2.3794),
        Airport(id: "LEPA", name: "Palma de Mallorca", city: "Palma", latitude: 39.5517, longitude: 2.7388),
        Airport(id: "EDDL", name: "Dusseldorf", city: "Dusseldorf", latitude: 51.2895, longitude: 6.7668),
        Airport(id: "EDDB", name: "Berlin Brandenburg", city: "Berlin", latitude: 52.3667, longitude: 13.5033),
        Airport(id: "LIMC", name: "Milan Malpensa", city: "Milan", latitude: 45.6306, longitude: 8.7281),
        Airport(id: "LEAL", name: "Alicante", city: "Alicante", latitude: 38.2822, longitude: -0.5582),
        // Asia / Middle East
        Airport(id: "RJTT", name: "Tokyo Haneda", city: "Tokyo", latitude: 35.5494, longitude: 139.7798),
        Airport(id: "VHHH", name: "Hong Kong Intl", city: "Hong Kong", latitude: 22.3080, longitude: 113.9185),
        Airport(id: "WSSS", name: "Singapore Changi", city: "Singapore", latitude: 1.3502, longitude: 103.9940),
        Airport(id: "OMDB", name: "Dubai Intl", city: "Dubai", latitude: 25.2528, longitude: 55.3644),
        Airport(id: "RKSI", name: "Incheon Intl", city: "Seoul", latitude: 37.4602, longitude: 126.4407),
        Airport(id: "ZBAD", name: "Beijing Daxing", city: "Beijing", latitude: 39.5098, longitude: 116.4105),
        Airport(id: "VTBS", name: "Suvarnabhumi", city: "Bangkok", latitude: 13.6900, longitude: 100.7501),
        // Americas
        Airport(id: "CYYZ", name: "Toronto Pearson", city: "Toronto", latitude: 43.6777, longitude: -79.6248),
        Airport(id: "MMMX", name: "Mexico City Intl", city: "Mexico City", latitude: 19.4363, longitude: -99.0721),
        Airport(id: "SBGR", name: "Sao Paulo Guarulhos", city: "Sao Paulo", latitude: -23.4356, longitude: -46.4731),
    ]
}
