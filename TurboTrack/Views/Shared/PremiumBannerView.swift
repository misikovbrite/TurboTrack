import SwiftUI

struct PremiumBannerView: View {
    let context: BannerContext
    var onUpgrade: () -> Void

    enum BannerContext {
        case map
        case forecast
        case reports

        var title: String {
            switch self {
            case .map: return "Unlock Live Turbulence Map"
            case .forecast: return "Unlock Route Forecasts"
            case .reports: return "Unlock Full PIREP Access"
            }
        }

        var subtitle: String {
            switch self {
            case .map: return "See real-time SIGMETs, AIRMETs, and turbulence hotspots worldwide"
            case .forecast: return "Get 3, 7, or 14-day turbulence forecasts for any route"
            case .reports: return "Access all pilot reports with severity filters and search"
            }
        }

        var icon: String {
            switch self {
            case .map: return "map.fill"
            case .forecast: return "airplane"
            case .reports: return "bubble.left.and.bubble.right.fill"
            }
        }

        var features: [(icon: String, text: String)] {
            switch self {
            case .map:
                return [
                    ("globe.americas.fill", "Global turbulence coverage"),
                    ("exclamationmark.triangle.fill", "Live SIGMET/AIRMET alerts"),
                    ("arrow.clockwise", "Auto-refresh every few minutes"),
                ]
            case .forecast:
                return [
                    ("calendar.badge.clock", "Up to 14-day forecasts"),
                    ("chart.bar.fill", "Flight level breakdown"),
                    ("bell.fill", "Pre-flight reminders"),
                ]
            case .reports:
                return [
                    ("airplane.circle.fill", "Real-time pilot reports"),
                    ("magnifyingglass", "Search by airport or aircraft"),
                    ("slider.horizontal.3", "Filter by severity level"),
                ]
            }
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 44, height: 44)

                    Image(systemName: context.icon)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(context.title)
                        .font(.system(size: 16, weight: .bold))

                    Text(context.subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }

            VStack(spacing: 8) {
                ForEach(context.features, id: \.text) { feature in
                    HStack(spacing: 10) {
                        Image(systemName: feature.icon)
                            .font(.system(size: 13))
                            .foregroundColor(.blue)
                            .frame(width: 18)
                        Text(feature.text)
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                }
            }

            Button(action: onUpgrade) {
                HStack(spacing: 6) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 14))
                    Text("Upgrade to Premium")
                        .font(.system(size: 15, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color(red: 0.3, green: 0.5, blue: 1.0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(16)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
    }
}

#Preview {
    VStack(spacing: 20) {
        PremiumBannerView(context: .forecast, onUpgrade: {})
        PremiumBannerView(context: .map, onUpgrade: {})
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
