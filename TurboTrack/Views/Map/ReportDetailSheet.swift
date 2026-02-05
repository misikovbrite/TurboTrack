import SwiftUI

struct ReportDetailSheet: View {
    let report: PIREPReport
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Severity badge
                    HStack {
                        Text(report.severity.displayName)
                            .font(.title2.bold())
                            .foregroundColor(report.severity.color)

                        Spacer()

                        Text(report.pirepType ?? "PIREP")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.blue.opacity(0.15))
                            .clipShape(Capsule())
                    }

                    Divider()

                    // Details
                    detailRow(title: "Altitude", value: report.altitudeDisplay)

                    if let base = report.turbulenceBase1, let top = report.turbulenceTop1 {
                        detailRow(title: "Turb. Layer", value: "FL\(String(format: "%03d", base)) – FL\(String(format: "%03d", top))")
                    }

                    if let aircraft = report.aircraftType, !aircraft.isEmpty {
                        detailRow(title: "Aircraft", value: aircraft)
                    }

                    if let time = report.observationDate {
                        detailRow(title: "Time", value: time.shortString)
                        detailRow(title: "Age", value: time.relativeString)
                    }

                    if let lat = report.latitude, let lon = report.longitude {
                        detailRow(title: "Position", value: String(format: "%.3f, %.3f", lat, lon))
                    }

                    // Raw text
                    if let raw = report.rawText, !raw.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Raw Report")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(raw)
                                .font(.system(.caption, design: .monospaced))
                                .padding(8)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Report Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .font(.subheadline)
        }
    }
}

#Preview {
    ReportDetailSheet(report: .sample)
}
