import SwiftUI

struct ReportRow: View {
    let report: PIREPReport

    var body: some View {
        HStack(spacing: 12) {
            // Severity indicator
            Circle()
                .fill(report.severity.color)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(report.severity.displayName)
                        .font(.subheadline.bold())
                        .foregroundColor(report.severity.color)

                    if let aircraft = report.aircraftType, !aircraft.isEmpty {
                        Text(aircraft)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray6))
                            .clipShape(Capsule())
                    }

                    Spacer()

                    if let time = report.observationDate {
                        Text(time.relativeString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                HStack {
                    if let fl = report.flightLevel {
                        Label("FL\(String(format: "%03d", fl))", systemImage: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let lat = report.latitude, let lon = report.longitude {
                        Text(String(format: "%.1f, %.1f", lat, lon))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if let raw = report.rawText {
                    Text(raw)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        ReportRow(report: .sample)
    }
}
