import Foundation
import CoreLocation
import MapKit

struct AirSigmet: Identifiable, Codable {
    let id: UUID
    let airSigmetType: String?
    let hazard: String?
    let severity: String?
    let validTimeFrom: String?
    let validTimeTo: String?
    let altitudeLow: Int?
    let altitudeHigh: Int?
    let rawText: String?
    let coordinates: [[Double]]?

    var turbulenceSeverity: TurbulenceSeverity {
        TurbulenceSeverity(from: severity)
    }

    var polygonCoordinates: [CLLocationCoordinate2D] {
        guard let coords = coordinates else { return [] }
        return coords.compactMap { pair in
            guard pair.count >= 2 else { return nil }
            return CLLocationCoordinate2D(latitude: pair[0], longitude: pair[1])
        }
    }

    var isTurbulence: Bool {
        guard let hazard = hazard?.uppercased() else { return false }
        return hazard.contains("TURB")
    }

    var validFromDate: Date? {
        validTimeFrom?.iso8601Date
    }

    var validToDate: Date? {
        validTimeTo?.iso8601Date
    }

    var typeDisplay: String {
        airSigmetType ?? "Unknown"
    }

    enum CodingKeys: String, CodingKey {
        case airSigmetType = "airsigmet_type"
        case hazard
        case severity
        case validTimeFrom = "valid_time_from"
        case validTimeTo = "valid_time_to"
        case altitudeLow = "alt_low"
        case altitudeHigh = "alt_hi"
        case rawText = "raw"
        case coordinates = "coords"
    }

    init(from decoder: Decoder) throws {
        self.id = UUID()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        airSigmetType = try container.decodeIfPresent(String.self, forKey: .airSigmetType)
        hazard = try container.decodeIfPresent(String.self, forKey: .hazard)
        severity = try container.decodeIfPresent(String.self, forKey: .severity)
        validTimeFrom = try container.decodeIfPresent(String.self, forKey: .validTimeFrom)
        validTimeTo = try container.decodeIfPresent(String.self, forKey: .validTimeTo)
        rawText = try container.decodeIfPresent(String.self, forKey: .rawText)

        if let altLow = try? container.decodeIfPresent(Int.self, forKey: .altitudeLow) {
            altitudeLow = altLow
        } else if let altStr = try? container.decodeIfPresent(String.self, forKey: .altitudeLow),
                  let altVal = Int(altStr) {
            altitudeLow = altVal
        } else {
            altitudeLow = nil
        }

        if let altHi = try? container.decodeIfPresent(Int.self, forKey: .altitudeHigh) {
            altitudeHigh = altHi
        } else if let altStr = try? container.decodeIfPresent(String.self, forKey: .altitudeHigh),
                  let altVal = Int(altStr) {
            altitudeHigh = altVal
        } else {
            altitudeHigh = nil
        }

        // Coordinates can come in various formats
        if let coordArray = try? container.decodeIfPresent([[Double]].self, forKey: .coordinates) {
            coordinates = coordArray
        } else {
            coordinates = nil
        }
    }

    init(
        id: UUID = UUID(),
        airSigmetType: String? = nil,
        hazard: String? = nil,
        severity: String? = nil,
        validTimeFrom: String? = nil,
        validTimeTo: String? = nil,
        altitudeLow: Int? = nil,
        altitudeHigh: Int? = nil,
        rawText: String? = nil,
        coordinates: [[Double]]? = nil
    ) {
        self.id = id
        self.airSigmetType = airSigmetType
        self.hazard = hazard
        self.severity = severity
        self.validTimeFrom = validTimeFrom
        self.validTimeTo = validTimeTo
        self.altitudeLow = altitudeLow
        self.altitudeHigh = altitudeHigh
        self.rawText = rawText
        self.coordinates = coordinates
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(airSigmetType, forKey: .airSigmetType)
        try container.encodeIfPresent(hazard, forKey: .hazard)
        try container.encodeIfPresent(severity, forKey: .severity)
        try container.encodeIfPresent(validTimeFrom, forKey: .validTimeFrom)
        try container.encodeIfPresent(validTimeTo, forKey: .validTimeTo)
        try container.encodeIfPresent(altitudeLow, forKey: .altitudeLow)
        try container.encodeIfPresent(altitudeHigh, forKey: .altitudeHigh)
        try container.encodeIfPresent(rawText, forKey: .rawText)
        try container.encodeIfPresent(coordinates, forKey: .coordinates)
    }

    static let sample = AirSigmet(
        airSigmetType: "SIGMET",
        hazard: "TURB",
        severity: "SEV",
        validTimeFrom: "2024-01-15T12:00:00Z",
        validTimeTo: "2024-01-15T18:00:00Z",
        altitudeLow: 25000,
        altitudeHigh: 40000,
        rawText: "SIGMET TANGO 1 VALID UNTIL 151800"
    )
}
