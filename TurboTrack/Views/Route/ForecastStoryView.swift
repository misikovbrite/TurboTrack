import SwiftUI

struct ForecastStoryView: View {
    @ObservedObject var viewModel: RouteViewModel
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                // Page indicator
                HStack(spacing: 6) {
                    ForEach(0..<4, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: index == currentPage ? 24 : 8, height: 4)
                            .animation(.easeInOut(duration: 0.25), value: currentPage)
                    }
                }
                .padding(.top, 12)

                // Paged content
                TabView(selection: $currentPage) {
                    flightCard.tag(0)
                    turbulenceLevelCard.tag(1)
                    routeProfileCard.tag(2)
                    safetyTipsCard.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Bottom button
                Button {
                    viewModel.showFullReport()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text.magnifyingglass")
                        Text("View Full Report")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.showFullReport()
                } label: {
                    Text("Skip")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Card 1: Your Flight

    private var flightCard: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "airplane.departure")
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            VStack(spacing: 6) {
                Text("Your Flight")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .tracking(1.5)
                    .textCase(.uppercase)

                Text(routeDisplayName)
                    .font(.title.bold())

                Text("\(viewModel.departureAirport?.icao ?? "???") → \(viewModel.arrivalAirport?.icao ?? "???")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Forecast horizon
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                Text(viewModel.forecastHorizonText)
                    .font(.subheadline.bold())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.blue.opacity(0.1))
            .clipShape(Capsule())

            Spacer()
            Spacer()
        }
        .padding(24)
    }

    // MARK: - Card 2: Turbulence Level

    private var turbulenceLevelCard: some View {
        let severity = viewModel.forecastSeverity
        let advice = viewModel.forecastAdvice

        return VStack(spacing: 20) {
            Spacer()

            // Severity circle
            ZStack {
                Circle()
                    .fill(advice.color.opacity(0.15))
                    .frame(width: 140, height: 140)

                Circle()
                    .fill(advice.color.opacity(0.3))
                    .frame(width: 100, height: 100)

                Image(systemName: advice.icon)
                    .font(.system(size: 44))
                    .foregroundColor(advice.color)
            }

            VStack(spacing: 8) {
                Text(advice.title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text(severity.displayName)
                    .font(.headline)
                    .foregroundColor(advice.color)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(advice.color.opacity(0.12))
                    .clipShape(Capsule())
            }

            Text(briefDescription(for: severity))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Spacer()
            Spacer()
        }
        .padding(24)
    }

    // MARK: - Card 3: Route Profile

    private var routeProfileCard: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(.blue)

            Text("Route Profile")
                .font(.title2.bold())

            // Visual turbulence bar along the route
            VStack(spacing: 12) {
                // Airport labels
                HStack {
                    Text(viewModel.departureAirport?.icao ?? "DEP")
                        .font(.caption.bold())
                    Spacer()
                    Text(viewModel.arrivalAirport?.icao ?? "ARR")
                        .font(.caption.bold())
                }

                // Turbulence bar
                GeometryReader { geo in
                    let segments = routeSegments
                    HStack(spacing: 1) {
                        ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(segment.color)
                                .frame(height: 28)
                        }
                    }
                }
                .frame(height: 28)
                .clipShape(RoundedRectangle(cornerRadius: 6))

                // Legend
                HStack(spacing: 16) {
                    legendItem(color: .green, text: "Smooth")
                    legendItem(color: .yellow, text: "Light")
                    legendItem(color: .orange, text: "Moderate")
                    legendItem(color: .red, text: "Severe")
                }
                .font(.caption2)
            }
            .padding(20)
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.06), radius: 10, y: 4)

            // Daily breakdown
            if !viewModel.dailyForecast.isEmpty {
                VStack(spacing: 8) {
                    ForEach(Array(viewModel.dailyForecast.prefix(3).enumerated()), id: \.offset) { _, day in
                        HStack {
                            Text(dayLabel(for: day.date))
                                .font(.subheadline)
                            Spacer()
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(day.worst.color)
                                    .frame(width: 8, height: 8)
                                Text(day.worst.displayName)
                                    .font(.subheadline.bold())
                                    .foregroundColor(day.worst.color)
                            }
                        }
                    }
                }
                .padding(16)
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Spacer()
            Spacer()
        }
        .padding(24)
    }

    // MARK: - Card 4: Safety Tips

    private var safetyTipsCard: some View {
        let tips = tipsForSeverity(viewModel.forecastSeverity)

        return VStack(spacing: 16) {
            Spacer()

            Image(systemName: "shield.checkmark.fill")
                .font(.system(size: 44))
                .foregroundColor(.blue)

            Text("Safety Tips")
                .font(.title2.bold())

            Text("Based on your forecast")
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(tips.enumerated()), id: \.offset) { _, tip in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: tip.icon)
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(tip.title)
                                .font(.subheadline.bold())
                            Text(tip.detail)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(20)
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.06), radius: 10, y: 4)

            Spacer()
            Spacer()
        }
        .padding(24)
    }

    // MARK: - Helpers

    private var routeDisplayName: String {
        let dep = viewModel.departureAirport?.city ?? viewModel.departureAirport?.name ?? "Departure"
        let arr = viewModel.arrivalAirport?.city ?? viewModel.arrivalAirport?.name ?? "Arrival"
        return "\(dep) → \(arr)"
    }

    private var routeSegments: [(color: Color, severity: TurbulenceSeverity)] {
        let points = viewModel.forecastMapPoints
        guard !points.isEmpty else {
            return [(color: .green, severity: .none)]
        }

        // Sort points by longitude (rough approximation of route progress)
        let depLon = viewModel.departureAirport?.coordinate.longitude ?? 0
        let sorted = points.sorted {
            abs($0.longitude - depLon) < abs($1.longitude - depLon)
        }

        // Group into ~10 segments
        let segmentCount = min(10, sorted.count)
        guard segmentCount > 0 else { return [(color: .green, severity: .none)] }
        let chunkSize = max(1, sorted.count / segmentCount)

        var segments: [(color: Color, severity: TurbulenceSeverity)] = []
        for i in stride(from: 0, to: sorted.count, by: chunkSize) {
            let chunk = sorted[i..<min(i + chunkSize, sorted.count)]
            let worst = chunk.map(\.severity).max { $0.sortOrder < $1.sortOrder } ?? .none
            segments.append((color: worst.color, severity: worst))
        }

        return segments.isEmpty ? [(color: .green, severity: .none)] : segments
    }

    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(text)
        }
    }

    private func dayLabel(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }

    private func briefDescription(for severity: TurbulenceSeverity) -> String {
        switch severity {
        case .none:
            return "No significant turbulence expected along your route. Smooth flying ahead!"
        case .light:
            return "Minor bumps may occur. Very common and nothing to worry about."
        case .moderate:
            return "Expect noticeable jolts. Walking may be difficult at times."
        case .severe, .extreme:
            return "Strong turbulence predicted. Stay seated with seatbelt fastened."
        }
    }

    private struct Tip {
        let icon: String
        let title: String
        let detail: String
    }

    private func tipsForSeverity(_ severity: TurbulenceSeverity) -> [Tip] {
        var tips: [Tip] = [
            Tip(icon: "lock.fill", title: "Keep Seatbelt Fastened",
                detail: "Always keep your seatbelt fastened when seated, even when the sign is off."),
            Tip(icon: "bag.fill", title: "Secure Loose Items",
                detail: "Store bags under the seat or in overhead bins. Keep personal items secured."),
        ]

        switch severity {
        case .none, .light:
            tips.append(Tip(icon: "cup.and.saucer", title: "Enjoy Your Flight",
                           detail: "Conditions look good! You can comfortably use your tray table and move around."))
        case .moderate:
            tips.append(Tip(icon: "hand.raised.fill", title: "Follow Crew Instructions",
                           detail: "The crew may ask you to return to your seat. Avoid hot beverages during bumpy sections."))
            tips.append(Tip(icon: "figure.walk", title: "Limit Movement",
                           detail: "Use the restroom before entering turbulent areas. Walk carefully if you must."))
        case .severe, .extreme:
            tips.append(Tip(icon: "exclamationmark.triangle.fill", title: "Stay Seated",
                           detail: "Remain in your seat with your seatbelt tightly fastened at all times."))
            tips.append(Tip(icon: "hand.raised.fill", title: "Follow All Instructions",
                           detail: "Listen carefully to the flight crew. Avoid any unnecessary movement."))
            tips.append(Tip(icon: "cross.case.fill", title: "Be Prepared",
                           detail: "Ensure overhead bins are securely closed. Check on children and elderly passengers."))
        }

        return tips
    }
}

#Preview {
    NavigationStack {
        ForecastStoryView(viewModel: RouteViewModel())
    }
}
