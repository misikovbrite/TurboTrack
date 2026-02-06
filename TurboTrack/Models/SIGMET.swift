import Foundation
import CoreLocation

struct SigmetCoord: Codable {
    let lat: Double
    let lon: Double

    init(lat: Double, lon: Double) {
        self.lat = lat
        self.lon = lon
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // Handle both Int and Double from JSON
        if let d = try? c.decode(Double.self, forKey: .lat) {
            lat = d
        } else {
            lat = Double(try c.decode(Int.self, forKey: .lat))
        }
        if let d = try? c.decode(Double.self, forKey: .lon) {
            lon = d
        } else {
            lon = Double(try c.decode(Int.self, forKey: .lon))
        }
    }

    enum CodingKeys: String, CodingKey {
        case lat, lon
    }
}

struct AirSigmet: Identifiable, Equatable {
    let id: UUID
    let icaoId: String?
    let firId: String?
    let firName: String?
    let receiptTime: String?
    let validTimeFrom: Int?
    let validTimeTo: Int?
    let hazard: String?
    let qualifier: String?
    let base: Int?
    let top: Int?
    let coords: [SigmetCoord]?
    let rawSigmet: String?

    var turbulenceSeverity: TurbulenceSeverity {
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
        icaoId: "LEMM",
        firId: "LECB",
        firName: "LECB BARCELONA",
        receiptTime: "2026-02-06T16:53:53Z",
        validTimeFrom: 1770400800,
        validTimeTo: 1770411600,
        hazard: "TURB",
        qualifier: "SEV",
        base: 20000,
        top: 32000,
        coords: [SigmetCoord(lat: 39.65, lon: -1.083), SigmetCoord(lat: 42.133, lon: 3.95), SigmetCoord(lat: 42.017, lon: 4.55), SigmetCoord(lat: 39.683, lon: 4.5)],
        rawSigmet: "LECB SIGMET 9 VALID 061800/062100 LEVA- SEV TURB FL200/320"
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

        // base/top can be Int or null
        if let b = try? c.decodeIfPresent(Int.self, forKey: .base) {
            base = b
        } else {
            base = nil
        }
        if let t = try? c.decodeIfPresent(Int.self, forKey: .top) {
            top = t
        } else {
            top = nil
        }

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
