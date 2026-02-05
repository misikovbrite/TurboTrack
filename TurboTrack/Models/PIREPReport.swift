import Foundation
import CoreLocation

struct PIREPReport: Identifiable, Codable, Equatable {
    let id: UUID
    let receiptTime: String?
    let observationTime: String?
    let latitude: Double?
    let longitude: Double?
    let altitudeFeet: Int?
    let aircraftType: String?
    let turbulenceIntensity: String?
    let turbulenceBaseAlt: Int?
    let turbulenceTopAlt: Int?
    let icingIntensity: String?
    let rawText: String?
    let reportType: String?

    var severity: TurbulenceSeverity {
        TurbulenceSeverity(from: turbulenceIntensity)
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    var observationDate: Date? {
        observationTime?.iso8601Date
    }

    var altitudeDisplay: String {
        guard let alt = altitudeFeet else { return "N/A" }
        return "\(alt.flightLevel) (\(alt) ft)"
    }

    // Custom coding to handle API JSON
    enum CodingKeys: String, CodingKey {
        case receiptTime = "receipt_time"
        case observationTime = "obs_time"
        case latitude = "lat"
        case longitude = "lon"
        case altitudeFeet = "alt_ft"
        case aircraftType = "acft"
        case turbulenceIntensity = "turb_type"
        case turbulenceBaseAlt = "turb_base"
        case turbulenceTopAlt = "turb_top"
        case icingIntensity = "ice_type"
        case rawText = "raw"
        case reportType = "rpt_type"
    }

    init(from decoder: Decoder) throws {
        self.id = UUID()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        receiptTime = try container.decodeIfPresent(String.self, forKey: .receiptTime)
        observationTime = try container.decodeIfPresent(String.self, forKey: .observationTime)
        rawText = try container.decodeIfPresent(String.self, forKey: .rawText)
        aircraftType = try container.decodeIfPresent(String.self, forKey: .aircraftType)
        reportType = try container.decodeIfPresent(String.self, forKey: .reportType)

        // Handle latitude - could be Double or String
        if let latDouble = try? container.decodeIfPresent(Double.self, forKey: .latitude) {
            latitude = latDouble
        } else if let latStr = try? container.decodeIfPresent(String.self, forKey: .latitude),
                  let latVal = Double(latStr) {
            latitude = latVal
        } else {
            latitude = nil
        }

        // Handle longitude
        if let lonDouble = try? container.decodeIfPresent(Double.self, forKey: .longitude) {
            longitude = lonDouble
        } else if let lonStr = try? container.decodeIfPresent(String.self, forKey: .longitude),
                  let lonVal = Double(lonStr) {
            longitude = lonVal
        } else {
            longitude = nil
        }

        // Handle altitude
        if let altInt = try? container.decodeIfPresent(Int.self, forKey: .altitudeFeet) {
            altitudeFeet = altInt
        } else if let altStr = try? container.decodeIfPresent(String.self, forKey: .altitudeFeet),
                  let altVal = Int(altStr) {
            altitudeFeet = altVal
        } else {
            altitudeFeet = nil
        }

        // Turbulence intensity - try multiple fields
        if let turb = try? container.decodeIfPresent(String.self, forKey: .turbulenceIntensity) {
            turbulenceIntensity = turb
        } else {
            turbulenceIntensity = nil
        }

        // Turbulence base/top
        if let base = try? container.decodeIfPresent(Int.self, forKey: .turbulenceBaseAlt) {
            turbulenceBaseAlt = base
        } else if let baseStr = try? container.decodeIfPresent(String.self, forKey: .turbulenceBaseAlt),
                  let baseVal = Int(baseStr) {
            turbulenceBaseAlt = baseVal
        } else {
            turbulenceBaseAlt = nil
        }

        if let top = try? container.decodeIfPresent(Int.self, forKey: .turbulenceTopAlt) {
            turbulenceTopAlt = top
        } else if let topStr = try? container.decodeIfPresent(String.self, forKey: .turbulenceTopAlt),
                  let topVal = Int(topStr) {
            turbulenceTopAlt = topVal
        } else {
            turbulenceTopAlt = nil
        }

        icingIntensity = try container.decodeIfPresent(String.self, forKey: .icingIntensity)
    }

    // Manual initializer for previews/testing
    init(
        id: UUID = UUID(),
        receiptTime: String? = nil,
        observationTime: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        altitudeFeet: Int? = nil,
        aircraftType: String? = nil,
        turbulenceIntensity: String? = nil,
        turbulenceBaseAlt: Int? = nil,
        turbulenceTopAlt: Int? = nil,
        icingIntensity: String? = nil,
        rawText: String? = nil,
        reportType: String? = nil
    ) {
        self.id = id
        self.receiptTime = receiptTime
        self.observationTime = observationTime
        self.latitude = latitude
        self.longitude = longitude
        self.altitudeFeet = altitudeFeet
        self.aircraftType = aircraftType
        self.turbulenceIntensity = turbulenceIntensity
        self.turbulenceBaseAlt = turbulenceBaseAlt
        self.turbulenceTopAlt = turbulenceTopAlt
        self.icingIntensity = icingIntensity
        self.rawText = rawText
        self.reportType = reportType
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(receiptTime, forKey: .receiptTime)
        try container.encodeIfPresent(observationTime, forKey: .observationTime)
        try container.encodeIfPresent(latitude, forKey: .latitude)
        try container.encodeIfPresent(longitude, forKey: .longitude)
        try container.encodeIfPresent(altitudeFeet, forKey: .altitudeFeet)
        try container.encodeIfPresent(aircraftType, forKey: .aircraftType)
        try container.encodeIfPresent(turbulenceIntensity, forKey: .turbulenceIntensity)
        try container.encodeIfPresent(turbulenceBaseAlt, forKey: .turbulenceBaseAlt)
        try container.encodeIfPresent(turbulenceTopAlt, forKey: .turbulenceTopAlt)
        try container.encodeIfPresent(icingIntensity, forKey: .icingIntensity)
        try container.encodeIfPresent(rawText, forKey: .rawText)
        try container.encodeIfPresent(reportType, forKey: .reportType)
    }

    static func == (lhs: PIREPReport, rhs: PIREPReport) -> Bool {
        lhs.id == rhs.id
    }

    static let sample = PIREPReport(
        receiptTime: "2024-01-15T12:00:00Z",
        observationTime: "2024-01-15T11:45:00Z",
        latitude: 40.6413,
        longitude: -73.7781,
        altitudeFeet: 35000,
        aircraftType: "B738",
        turbulenceIntensity: "MOD",
        turbulenceBaseAlt: 33000,
        turbulenceTopAlt: 37000,
        rawText: "UA /OV JFK/TM 1145/FL350/TP B738/TB MOD"
    )
}
