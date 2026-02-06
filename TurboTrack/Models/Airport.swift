import Foundation
import CoreLocation

struct Airport: Identifiable, Codable {
    let id: String // ICAO code
    let name: String
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var icao: String { id }

    static let commonAirports: [Airport] = [
        // US
        Airport(id: "KJFK", name: "John F. Kennedy Intl", latitude: 40.6413, longitude: -73.7781),
        Airport(id: "KLAX", name: "Los Angeles Intl", latitude: 33.9425, longitude: -118.4081),
        Airport(id: "KORD", name: "O'Hare Intl", latitude: 41.9742, longitude: -87.9073),
        Airport(id: "KATL", name: "Hartsfield-Jackson Intl", latitude: 33.6407, longitude: -84.4277),
        Airport(id: "KDFW", name: "Dallas/Fort Worth Intl", latitude: 32.8998, longitude: -97.0403),
        Airport(id: "KDEN", name: "Denver Intl", latitude: 39.8561, longitude: -104.6737),
        Airport(id: "KSFO", name: "San Francisco Intl", latitude: 37.6213, longitude: -122.3790),
        Airport(id: "KSEA", name: "Seattle-Tacoma Intl", latitude: 47.4502, longitude: -122.3088),
        Airport(id: "KMIA", name: "Miami Intl", latitude: 25.7959, longitude: -80.2870),
        Airport(id: "KBOS", name: "Boston Logan Intl", latitude: 42.3656, longitude: -71.0096),
        Airport(id: "KLAS", name: "Las Vegas Harry Reid Intl", latitude: 36.0840, longitude: -115.1537),
        Airport(id: "KMSP", name: "Minneapolis-St Paul Intl", latitude: 44.8848, longitude: -93.2223),
        Airport(id: "KDTW", name: "Detroit Metro Wayne County", latitude: 42.2124, longitude: -83.3534),
        Airport(id: "KPHL", name: "Philadelphia Intl", latitude: 39.8721, longitude: -75.2411),
        Airport(id: "KIAH", name: "George Bush Intercontinental", latitude: 29.9902, longitude: -95.3368),
        Airport(id: "KPHX", name: "Phoenix Sky Harbor Intl", latitude: 33.4373, longitude: -112.0078),
        Airport(id: "KEWR", name: "Newark Liberty Intl", latitude: 40.6895, longitude: -74.1745),
        Airport(id: "KMCO", name: "Orlando Intl", latitude: 28.4312, longitude: -81.3081),
        Airport(id: "KCLT", name: "Charlotte Douglas Intl", latitude: 35.2140, longitude: -80.9431),
        Airport(id: "KDCA", name: "Ronald Reagan Washington Natl", latitude: 38.8512, longitude: -77.0402),
        // Europe
        Airport(id: "LEBL", name: "Barcelona El Prat", latitude: 41.2971, longitude: 2.0785),
        Airport(id: "LEMD", name: "Madrid Barajas", latitude: 40.4936, longitude: -3.5668),
        Airport(id: "EGLL", name: "London Heathrow", latitude: 51.4700, longitude: -0.4543),
        Airport(id: "LFPG", name: "Paris Charles de Gaulle", latitude: 49.0097, longitude: 2.5479),
        Airport(id: "EDDF", name: "Frankfurt Main", latitude: 50.0379, longitude: 8.5622),
        Airport(id: "EHAM", name: "Amsterdam Schiphol", latitude: 52.3086, longitude: 4.7639),
        Airport(id: "LIRF", name: "Rome Fiumicino", latitude: 41.8003, longitude: 12.2389),
        Airport(id: "EDDM", name: "Munich", latitude: 48.3538, longitude: 11.7861),
        Airport(id: "LSZH", name: "Zurich", latitude: 47.4647, longitude: 8.5492),
        Airport(id: "EKCH", name: "Copenhagen Kastrup", latitude: 55.6181, longitude: 12.6561),
        Airport(id: "ENGM", name: "Oslo Gardermoen", latitude: 60.1939, longitude: 11.1004),
        Airport(id: "ESSA", name: "Stockholm Arlanda", latitude: 59.6519, longitude: 17.9186),
        Airport(id: "EFHK", name: "Helsinki Vantaa", latitude: 60.3172, longitude: 24.9633),
        Airport(id: "LPPT", name: "Lisbon Portela", latitude: 38.7742, longitude: -9.1342),
        Airport(id: "EPWA", name: "Warsaw Chopin", latitude: 52.1657, longitude: 20.9671),
        Airport(id: "LOWW", name: "Vienna Schwechat", latitude: 48.1103, longitude: 16.5697),
        Airport(id: "LKPR", name: "Prague Vaclav Havel", latitude: 50.1008, longitude: 14.2600),
        Airport(id: "EIDW", name: "Dublin", latitude: 53.4213, longitude: -6.2701),
        Airport(id: "LGAV", name: "Athens Eleftherios Venizelos", latitude: 37.9364, longitude: 23.9445),
        Airport(id: "LTFM", name: "Istanbul", latitude: 41.2753, longitude: 28.7519),
        Airport(id: "UUEE", name: "Moscow Sheremetyevo", latitude: 55.9726, longitude: 37.4146),
        // Asia / Middle East
        Airport(id: "RJTT", name: "Tokyo Haneda", latitude: 35.5494, longitude: 139.7798),
        Airport(id: "VHHH", name: "Hong Kong", latitude: 22.3080, longitude: 113.9185),
        Airport(id: "WSSS", name: "Singapore Changi", latitude: 1.3502, longitude: 103.9940),
        Airport(id: "OMDB", name: "Dubai", latitude: 25.2528, longitude: 55.3644),
        // Americas
        Airport(id: "CYYZ", name: "Toronto Pearson", latitude: 43.6777, longitude: -79.6248),
        Airport(id: "MMMX", name: "Mexico City", latitude: 19.4363, longitude: -99.0721),
        Airport(id: "SBGR", name: "Sao Paulo Guarulhos", latitude: -23.4356, longitude: -46.4731),
    ]

    static func find(icao: String) -> Airport? {
        commonAirports.first { $0.id.uppercased() == icao.uppercased() }
    }
}
