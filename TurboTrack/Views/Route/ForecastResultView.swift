import SwiftUI
import MapKit

struct ForecastResultView: View {
    @ObservedObject var viewModel: RouteViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                statusBanner
                adviceCard
                mapSection

                if !viewModel.dailyForecast.isEmpty {
                    dailyForecastSection
                }

                if !viewModel.flightLevelBreakdown.isEmpty {
                    flightLevelSection
                }

                pirepSection

                if viewModel.showNotificationPrompt {
                    notificationPromptCard
                } else if viewModel.notificationScheduled {
                    notificationConfirmCard
                }

                disclaimerText
            }
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(viewModel.routeTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("New Search") { viewModel.clearRoute() }
                    .font(.subheadline)
            }
        }
    }

    // MARK: - Status Banner

    private var statusBanner: some View {
        let advice = viewModel.forecastAdvice
        return HStack(spacing: 14) {
            Image(systemName: advice.icon)
                .font(.system(size: 30))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 3) {
                Text(advice.title)
                    .font(.headline)
                    .foregroundColor(.white)

                if !viewModel.forecastHorizonText.isEmpty {
                    Text(viewModel.forecastHorizonText)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }

            Spacer()
        }
        .padding(16)
        .background(advice.color.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Advice

    private var adviceCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Passenger Advisory", systemImage: "person.fill")
                .font(.subheadline.bold())
                .foregroundColor(.secondary)

            Text(viewModel.forecastAdvice.detail)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Map

    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Route Overview", systemImage: "map")
                .font(.subheadline.bold())
                .foregroundColor(.secondary)

            RouteMapView(viewModel: viewModel)
                .frame(height: horizontalSizeClass == .regular ? 400 : 260)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(16)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Daily Forecast

    private var dailyForecastSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Daily Forecast", systemImage: "calendar")
                .font(.subheadline.bold())
                .foregroundColor(.secondary)

            ForEach(Array(viewModel.dailyForecast.enumerated()), id: \.offset) { index, day in
                HStack {
                    Text(dayLabel(for: day.date))
                        .font(.subheadline)

                    Spacer()

                    HStack(spacing: 6) {
                        Circle()
                            .fill(day.worst.color)
                            .frame(width: 10, height: 10)
                        Text(day.worst.displayName)
                            .font(.subheadline.bold())
                            .foregroundColor(day.worst.color)
                    }
                }
                .padding(.vertical, 4)

                if index < viewModel.dailyForecast.count - 1 {
                    Divider()
                }
            }
        }
        .padding(16)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Flight Level Breakdown

    private var flightLevelSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("By Flight Level", systemImage: "arrow.up.and.down")
                .font(.subheadline.bold())
                .foregroundColor(.secondary)

            Text("Detailed altitude analysis for pilots")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(Array(viewModel.flightLevelBreakdown.enumerated()), id: \.offset) { index, level in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("FL\(level.level)")
                            .font(.subheadline.bold().monospaced())
                        Text("\((level.level * 100).formatted()) ft")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 80, alignment: .leading)

                    Text(level.severity.displayName)
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(level.severity.color.opacity(0.15))
                        .foregroundColor(level.severity.color)
                        .clipShape(Capsule())

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Shear \(level.avgShear, specifier: "%.1f") kt/kft")
                            .font(.caption2.monospaced())
                        if level.maxJet > 0 {
                            Text("Jet \(Int(level.maxJet)) kt")
                                .font(.caption2.monospaced())
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)

                if index < viewModel.flightLevelBreakdown.count - 1 {
                    Divider()
                }
            }
        }
        .padding(16)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - PIREPs

    private var pirepSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Pilot Reports (PIREPs)", systemImage: "bubble.left.fill")
                .font(.subheadline.bold())
                .foregroundColor(.secondary)

            Text(viewModel.pirepSummary)
                .font(.subheadline)

            if !viewModel.routePireps.isEmpty {
                Text("Real-time reports from the last 6 hours along your route")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Notification Prompt

    private var notificationPromptCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "bell.badge.fill")
                    .font(.title2)
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Get a reminder before your flight?")
                        .font(.subheadline.bold())
                    Text("We'll send you an updated forecast")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            DatePicker(
                "Flight date",
                selection: $viewModel.flightDate,
                in: Date()...,
                displayedComponents: [.date, .hourAndMinute]
            )
            .font(.subheadline)

            HStack(spacing: 12) {
                Button {
                    viewModel.dismissNotificationPrompt()
                } label: {
                    Text("No Thanks")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    viewModel.scheduleFlightNotification()
                } label: {
                    Text("Remind Me")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(16)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var notificationConfirmCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundColor(.green)
            VStack(alignment: .leading, spacing: 2) {
                Text("Reminder set!")
                    .font(.subheadline.bold())
                Text("You'll get an updated forecast before your flight")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Disclaimer

    private var disclaimerText: some View {
        Text("This forecast is for informational purposes only. Turbulence predictions are based on atmospheric wind data and may not reflect actual conditions. Always follow crew instructions and official aviation weather briefings.")
            .font(.caption2)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            .padding(.top, 4)
    }

    // MARK: - Helpers

    private func dayLabel(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        ForecastResultView(viewModel: RouteViewModel())
    }
}
