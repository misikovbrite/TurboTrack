import Foundation
import CoreLocation

struct PIREPReport: Identifiable, Equatable {
    let id: UUID
    let receiptTime: String?
    let obsTime: Int?           // Unix timestamp
    let latitude: Double?
    let longitude: Double?
    let flightLevel: Int?       // Flight level (e.g. 350 = FL350)
    let aircraftType: String?
    let turbulenceIntensity1: String?
    let turbulenceBase1: Int?
    let turbulenceTop1: Int?
    let turbulenceIntensity2: String?
    let turbulenceBase2: Int?
    let turbulenceTop2: Int?
    let icingIntensity: String?
    let rawText: String?
    let pirepType: String?

    var severity: TurbulenceSeverity {
        // Check both turbulence fields, take the worse one
        let sev1 = TurbulenceSeverity(from: turbulenceIntensity1)
        let sev2 = TurbulenceSeverity(from: turbulenceIntensity2)
        return sev1.sortOrder >= sev2.sortOrder ? sev1 : sev2
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        guard lat >= -90, lat <= 90, lon >= -180, lon <= 180 else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    var observationDate: Date? {
        guard let obsTime = obsTime else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(obsTime))
    }

    /// Altitude in feet (flightLevel is in hundreds of feet)
    var altitudeFeet: Int? {
        guard let fl = flightLevel else { return nil }
        return fl * 100
    }

    var altitudeDisplay: String {
        guard let fl = flightLevel else { return "N/A" }
        return "FL\(String(format: "%03d", fl)) (\(fl * 100) ft)"
    }

    static func == (lhs: PIREPReport, rhs: PIREPReport) -> Bool {
        lhs.id == rhs.id
    }

    static let sample = PIREPReport(
        id: UUID(),
        receiptTime: "2024-01-15T12:00:00Z",
        obsTime: 1770328260,
        latitude: 40.6413,
        longitude: -73.7781,
        flightLevel: 350,
        aircraftType: "B738",
        turbulenceIntensity1: "MOD",
        turbulenceBase1: 330,
        turbulenceTop1: 370,
        turbulenceIntensity2: nil,
        turbulenceBase2: nil,
        turbulenceTop2: nil,
        icingIntensity: nil,
        rawText: "JFK UA /OV JFK/TM 1145/FL350/TP B738/TB MOD",
        pirepType: "PIREP"
    )
}

// MARK: - Codable conformance matching aviationweather.gov API

extension PIREPReport: Codable {
    enum CodingKeys: String, CodingKey {
        case receiptTime
        case obsTime
        case lat
        case lon
        case fltLvl
        case acType
        case tbInt1
        case tbBas1
        case tbTop1
        case tbInt2
        case tbBas2
        case tbTop2
        case icgInt1
        case rawOb
        case pirepType
    }

    init(from decoder: Decoder) throws {
        self.id = UUID()
        let c = try decoder.container(keyedBy: CodingKeys.self)

        receiptTime = try c.decodeIfPresent(String.self, forKey: .receiptTime)
        obsTime = try c.decodeIfPresent(Int.self, forKey: .obsTime)
        rawText = try c.decodeIfPresent(String.self, forKey: .rawOb)
        aircraftType = try c.decodeIfPresent(String.self, forKey: .acType)
        pirepType = try c.decodeIfPresent(String.self, forKey: .pirepType)

        // Coordinates
        latitude = try c.decodeIfPresent(Double.self, forKey: .lat)
        longitude = try c.decodeIfPresent(Double.self, forKey: .lon)

        // Flight level
        flightLevel = try c.decodeIfPresent(Int.self, forKey: .fltLvl)

        // Turbulence fields
        turbulenceIntensity1 = try c.decodeIfPresent(String.self, forKey: .tbInt1)
        turbulenceIntensity2 = try c.decodeIfPresent(String.self, forKey: .tbInt2)

        // Base/top — can be Int or null
        turbulenceBase1 = try c.decodeIfPresent(Int.self, forKey: .tbBas1)
        turbulenceTop1 = try c.decodeIfPresent(Int.self, forKey: .tbTop1)
        turbulenceBase2 = try c.decodeIfPresent(Int.self, forKey: .tbBas2)
        turbulenceTop2 = try c.decodeIfPresent(Int.self, forKey: .tbTop2)

        icingIntensity = try c.decodeIfPresent(String.self, forKey: .icgInt1)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(receiptTime, forKey: .receiptTime)
        try c.encodeIfPresent(obsTime, forKey: .obsTime)
        try c.encodeIfPresent(latitude, forKey: .lat)
        try c.encodeIfPresent(longitude, forKey: .lon)
        try c.encodeIfPresent(flightLevel, forKey: .fltLvl)
        try c.encodeIfPresent(aircraftType, forKey: .acType)
        try c.encodeIfPresent(turbulenceIntensity1, forKey: .tbInt1)
        try c.encodeIfPresent(turbulenceBase1, forKey: .tbBas1)
        try c.encodeIfPresent(turbulenceTop1, forKey: .tbTop1)
        try c.encodeIfPresent(turbulenceIntensity2, forKey: .tbInt2)
        try c.encodeIfPresent(turbulenceBase2, forKey: .tbBas2)
        try c.encodeIfPresent(turbulenceTop2, forKey: .tbTop2)
        try c.encodeIfPresent(icingIntensity, forKey: .icgInt1)
        try c.encodeIfPresent(rawText, forKey: .rawOb)
        try c.encodeIfPresent(pirepType, forKey: .pirepType)
    }
}
