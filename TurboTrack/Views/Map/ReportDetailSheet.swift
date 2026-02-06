import SwiftUI

struct ReportDetailSheet: View {
    let report: PIREPReport
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
                .fill(Color(.tertiaryLabel))
                .frame(width: 36, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 14)

            ScrollView {
                VStack(spacing: 20) {
                    // Header — big severity indicator
                    headerSection

                    // Details grid
                    detailsCard

                    // Turbulence layer
                    if report.turbulenceBase1 != nil || report.turbulenceTop1 != nil {
                        turbulenceLayerCard
                    }

                    // Raw report
                    if let raw = report.rawText, !raw.isEmpty {
                        rawReportCard(raw)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 14) {
            // Severity circle
            ZStack {
                Circle()
                    .fill(report.severity.color.opacity(0.15))
                    .frame(width: 56, height: 56)
                Circle()
                    .fill(report.severity.color)
                    .frame(width: 32, height: 32)
                Circle()
                    .strokeBorder(.white.opacity(0.6), lineWidth: 2)
                    .frame(width: 32, height: 32)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(report.severity.displayName)
                    .font(.title2.bold())
                    .foregroundColor(report.severity.color)

                if let time = report.observationDate {
                    Text(time.relativeString)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Type badge
            Text(report.pirepType ?? "PIREP")
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.blue.opacity(0.12))
                .foregroundColor(.blue)
                .clipShape(Capsule())
        }
    }

    // MARK: - Details Card

    private var detailsCard: some View {
        VStack(spacing: 0) {
            if let fl = report.flightLevel {
                detailRow(
                    icon: "airplane",
                    iconColor: .blue,
                    title: "Altitude",
                    value: "FL\(String(format: "%03d", fl))",
                    subtitle: "\(fl * 100) ft"
                )
                Divider().padding(.leading, 44)
            }

            if let aircraft = report.aircraftType, !aircraft.isEmpty {
                detailRow(
                    icon: "airplane.circle",
                    iconColor: .purple,
                    title: "Aircraft",
                    value: aircraft,
                    subtitle: nil
                )
                Divider().padding(.leading, 44)
            }

            if let time = report.observationDate {
                detailRow(
                    icon: "clock",
                    iconColor: .orange,
                    title: "Observed",
                    value: time.shortString,
                    subtitle: nil
                )
                Divider().padding(.leading, 44)
            }

            if let lat = report.latitude, let lon = report.longitude {
                detailRow(
                    icon: "location",
                    iconColor: .green,
                    title: "Position",
                    value: String(format: "%.3f, %.3f", lat, lon),
                    subtitle: nil
                )
            }
        }
        .padding(4)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func detailRow(icon: String, iconColor: Color, title: String, value: String, subtitle: String?) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(iconColor)
                .frame(width: 28, height: 28)
                .background(iconColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 7))

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: 6) {
                    Text(value)
                        .font(.subheadline.bold())
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Turbulence Layer Card

    private var turbulenceLayerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Turbulence Layer", systemImage: "waveform.path")
                .font(.caption.bold())
                .foregroundColor(.secondary)

            HStack(spacing: 0) {
                // Base
                VStack(spacing: 4) {
                    Text("BASE")
                        .font(.caption2.bold())
                        .foregroundColor(.secondary)
                    if let base = report.turbulenceBase1 {
                        Text("FL\(String(format: "%03d", base))")
                            .font(.title3.bold().monospacedDigit())
                    } else {
                        Text("SFC")
                            .font(.title3.bold())
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)

                // Visual bar
                VStack(spacing: 4) {
                    Rectangle()
                        .fill(report.severity.color.gradient)
                        .frame(height: 6)
                        .clipShape(Capsule())
                    Image(systemName: "arrow.left.and.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                // Top
                VStack(spacing: 4) {
                    Text("TOP")
                        .font(.caption2.bold())
                        .foregroundColor(.secondary)
                    if let top = report.turbulenceTop1 {
                        Text("FL\(String(format: "%03d", top))")
                            .font(.title3.bold().monospacedDigit())
                    } else {
                        Text("—")
                            .font(.title3.bold())
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Raw Report

    private func rawReportCard(_ raw: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Raw Report", systemImage: "text.alignleft")
                .font(.caption.bold())
                .foregroundColor(.secondary)

            Text(raw)
                .font(.system(.caption, design: .monospaced))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.tertiarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    ReportDetailSheet(report: .sample)
        .presentationDetents([.medium, .large])
}
