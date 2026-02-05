import Foundation
import CoreLocation

struct SigmetCoord: Codable {
    let lat: Double
    let lon: Double
}

struct AirSigmet: Identifiable, Equatable {
    let id: UUID
    let icaoId: String?
    let firId: String?
    let firName: String?
    let receiptTime: String?
    let validTimeFrom: Int?      // Unix timestamp
    let validTimeTo: Int?        // Unix timestamp
    let hazard: String?
    let qualifier: String?
    let base: Int?               // altitude in feet
    let top: Int?                // altitude in feet
    let coords: [SigmetCoord]?
    let rawSigmet: String?

    var turbulenceSeverity: TurbulenceSeverity {
        // qualifier often contains severity info (e.g. "SEV")
        let qualSev = TurbulenceSeverity(from: qualifier)
        if qualSev != .none { return qualSev }
        return TurbulenceSeverity(from: hazard)
    }

    var polygonCoordinates: [CLLocationCoordinate2D] {
        guard let coords = coords else { return [] }
        return coords.map { CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lon) }
    }

    var isTurbulence: Bool {
        guard let hazard = hazard?.uppercased() else { return false }
        return hazard.contains("TURB")
    }

    var validFromDate: Date? {
        guard let t = validTimeFrom else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(t))
    }

    var validToDate: Date? {
        guard let t = validTimeTo else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(t))
    }

    var typeDisplay: String {
        if let qualifier = qualifier, !qualifier.isEmpty {
            return "\(qualifier) \(hazard ?? "")"
        }
        return hazard ?? "Unknown"
    }

    static func == (lhs: AirSigmet, rhs: AirSigmet) -> Bool {
        lhs.id == rhs.id
    }

    static let sample = AirSigmet(
        id: UUID(),
        icaoId: "YMRF",
        firId: "YMMM",
        firName: "YMMM MELBOURNE",
        receiptTime: "2026-02-05T16:15:06Z",
        validTimeFrom: 1770318000,
        validTimeTo: 1770332400,
        hazard: "TURB",
        qualifier: "SEV",
        base: 0,
        top: 5000,
        coords: [SigmetCoord(lat: -43, lon: 147.167), SigmetCoord(lat: -43.667, lon: 147), SigmetCoord(lat: -43.667, lon: 146.5), SigmetCoord(lat: -43, lon: 146.5)],
        rawSigmet: "SIGMET S01 VALID 051900/052300 YMRF- SEV TURB"
    )
}

// MARK: - Codable

extension AirSigmet: Codable {
    enum CodingKeys: String, CodingKey {
        case icaoId, firId, firName, receiptTime
        case validTimeFrom, validTimeTo
        case hazard, qualifier
        case base, top
        case coords
        case rawSigmet
    }

    init(from decoder: Decoder) throws {
        self.id = UUID()
        let c = try decoder.container(keyedBy: CodingKeys.self)

        icaoId = try c.decodeIfPresent(String.self, forKey: .icaoId)
        firId = try c.decodeIfPresent(String.self, forKey: .firId)
        firName = try c.decodeIfPresent(String.self, forKey: .firName)
        receiptTime = try c.decodeIfPresent(String.self, forKey: .receiptTime)
        validTimeFrom = try c.decodeIfPresent(Int.self, forKey: .validTimeFrom)
        validTimeTo = try c.decodeIfPresent(Int.self, forKey: .validTimeTo)
        hazard = try c.decodeIfPresent(String.self, forKey: .hazard)
        qualifier = try c.decodeIfPresent(String.self, forKey: .qualifier)
        base = try c.decodeIfPresent(Int.self, forKey: .base)
        top = try c.decodeIfPresent(Int.self, forKey: .top)
        coords = try c.decodeIfPresent([SigmetCoord].self, forKey: .coords)
        rawSigmet = try c.decodeIfPresent(String.self, forKey: .rawSigmet)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(icaoId, forKey: .icaoId)
        try c.encodeIfPresent(firId, forKey: .firId)
        try c.encodeIfPresent(firName, forKey: .firName)
        try c.encodeIfPresent(receiptTime, forKey: .receiptTime)
        try c.encodeIfPresent(validTimeFrom, forKey: .validTimeFrom)
        try c.encodeIfPresent(validTimeTo, forKey: .validTimeTo)
        try c.encodeIfPresent(hazard, forKey: .hazard)
        try c.encodeIfPresent(qualifier, forKey: .qualifier)
        try c.encodeIfPresent(base, forKey: .base)
        try c.encodeIfPresent(top, forKey: .top)
        try c.encodeIfPresent(coords, forKey: .coords)
        try c.encodeIfPresent(rawSigmet, forKey: .rawSigmet)
    }
}
