import SwiftUI

enum TurbulenceSeverity: String, CaseIterable, Identifiable, Codable {
    case light = "LGT"
    case moderate = "MOD"
    case severe = "SEV"
    case extreme = "EXTM"
    case none = "NEG"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light: return "Light"
        case .moderate: return "Moderate"
        case .severe: return "Severe"
        case .extreme: return "Extreme"
        case .none: return "None"
        }
    }

    var color: Color {
        switch self {
        case .light: return .green
        case .moderate: return .yellow
        case .severe: return .orange
        case .extreme: return .red
        case .none: return .gray
        }
    }

    var sortOrder: Int {
        switch self {
        case .none: return 0
        case .light: return 1
        case .moderate: return 2
        case .severe: return 3
        case .extreme: return 4
        }
    }

    init(from intensity: String?) {
        guard let intensity = intensity?.uppercased() else {
            self = .none
            return
        }
        if intensity.contains("EXTM") || intensity.contains("EXTREME") {
            self = .extreme
        } else if intensity.contains("SEV") || intensity.contains("SEVERE") {
            self = .severe
        } else if intensity.contains("MOD") || intensity.contains("MODERATE") {
            self = .moderate
        } else if intensity.contains("LGT") || intensity.contains("LIGHT") {
            self = .light
        } else if intensity.contains("NEG") || intensity.contains("SMOOTH") || intensity.contains("NONE") {
            self = .none
        } else {
            self = .none
        }
    }
}
