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

    // Common US airports for quick lookup
    static let commonAirports: [Airport] = [
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
    ]

    static func find(icao: String) -> Airport? {
        commonAirports.first { $0.id.uppercased() == icao.uppercased() }
    }
}
