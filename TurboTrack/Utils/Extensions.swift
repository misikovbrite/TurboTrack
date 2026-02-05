import Foundation
import CoreLocation

extension Double {
    /// Convert feet to meters
    var feetToMeters: Double { self * 0.3048 }
    /// Convert meters to feet
    var metersToFeet: Double { self / 0.3048 }
    /// Format as flight level (e.g. FL350)
    var flightLevel: String {
        let fl = Int(self / 100)
        return "FL\(String(format: "%03d", fl))"
    }
}

extension Int {
    var flightLevel: String {
        let fl = self / 100
        return "FL\(String(format: "%03d", fl))"
    }
}

extension Date {
    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    var shortString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm 'Z' dd MMM"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: self)
    }
}

extension CLLocationCoordinate2D {
    func distance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: latitude, longitude: longitude)
        let to = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return from.distance(from: to)
    }
}

extension String {
    /// Parse ISO8601 date string
    var iso8601Date: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: self) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: self)
    }
}
