import SwiftUI

struct ReportRow: View {
    let report: PIREPReport

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top row: severity + aircraft + time
            HStack(alignment: .center) {
                // Severity badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(report.severity.color)
                        .frame(width: 10, height: 10)
                    Text(report.severity.displayName.uppercased())
                        .font(.caption.bold())
                        .foregroundColor(report.severity.color)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(report.severity.color.opacity(0.12))
                .clipShape(Capsule())

                if let aircraft = report.aircraftType, !aircraft.isEmpty {
                    Text(aircraft)
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Capsule())
                }

                Spacer()

                if let time = report.observationDate {
                    Text(time.relativeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Info row: altitude + coordinates
            HStack(spacing: 16) {
                if let fl = report.flightLevel {
                    Label {
                        Text("FL\(String(format: "%03d", fl))")
                            .font(.caption)
                    } icon: {
                        Image(systemName: "airplane")
                            .font(.caption2)
                    }
                    .foregroundColor(.primary)
                }

                if let lat = report.latitude, let lon = report.longitude {
                    Label {
                        Text(String(format: "%.2f, %.2f", lat, lon))
                            .font(.caption)
                    } icon: {
                        Image(systemName: "location")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Raw text
            if let raw = report.rawText, !raw.isEmpty {
                Text(raw)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    List {
        ReportRow(report: .sample)
    }
}
