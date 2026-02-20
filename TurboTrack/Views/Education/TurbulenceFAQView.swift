import SwiftUI

struct TurbulenceFAQView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var expandedItem: String?

    private let faqItems: [(id: String, question: String, answer: String, icon: String)] = [
        (
            "what",
            "What is turbulence?",
            "Turbulence is irregular air movement that causes bumpy or rough flights. It happens when air masses move at different speeds or directions, creating eddies and currents — similar to rapids in a river. It's extremely common and rarely dangerous to modern aircraft, which are designed to handle even severe turbulence.",
            "wind"
        ),
        (
            "causes",
            "What causes turbulence?",
            "The main causes are:\n\n• Clear Air Turbulence (CAT) — caused by jet streams and wind shear at high altitudes, invisible to radar\n• Convective — from thunderstorms and thermal activity\n• Mountain Wave — wind flowing over mountain ranges\n• Wake — from the engines of other aircraft\n\nMost turbulence you experience on flights is Clear Air Turbulence.",
            "cloud.bolt.fill"
        ),
        (
            "severity",
            "What do severity levels mean?",
            "Turbulence is classified into levels:\n\n🟢 None/Smooth — No bumps, calm flight\n🟡 Light — Slight, brief bumps. Very common. Drinks may ripple.\n🟠 Moderate — Noticeable bumps. Walking is difficult. Unsecured items may move.\n🔴 Severe — Strong, abrupt changes. Occupants pushed against seatbelts. Very rare.\n⚫ Extreme — Aircraft thrown violently. Extremely rare, almost never encountered on commercial routes.",
            "gauge.with.dots.needle.33percent"
        ),
        (
            "danger",
            "Is turbulence dangerous?",
            "Modern aircraft are built to withstand far more turbulence than they ever encounter. Wings can flex dramatically without any structural risk. The main danger is to unbuckled passengers — which is why it's important to keep your seatbelt fastened when seated.\n\nIn the last 40 years, no modern commercial aircraft has crashed due to turbulence.",
            "shield.checkered"
        ),
        (
            "pireps",
            "What are PIREPs?",
            "PIREPs (Pilot Reports) are real-time reports filed by pilots during flight. When a pilot encounters turbulence, they report its location, altitude, and severity. These reports are collected by the FAA and shared with other pilots and aviation services.\n\nOur app shows recent PIREPs along your route so you can see what pilots actually experienced.",
            "bubble.left.fill"
        ),
        (
            "sigmets",
            "What are SIGMETs and AIRMETs?",
            "SIGMETs (Significant Meteorological Information) are urgent weather warnings for aviation. They cover severe turbulence, icing, volcanic ash, and other hazards.\n\nAIRMETs (Airmen's Meteorological Information) are less severe but still important advisories for moderate turbulence, low-level wind shear, and visibility.\n\nBoth appear as colored polygons on our turbulence map.",
            "exclamationmark.triangle.fill"
        ),
        (
            "flightlevels",
            "What are flight levels?",
            "Flight levels (FL) are standard altitudes used in aviation, measured in hundreds of feet. For example:\n\n• FL100 = 10,000 ft\n• FL300 = 30,000 ft (typical cruising)\n• FL390 = 39,000 ft (high cruise)\n\nTurbulence varies by altitude. Checking the flight level breakdown in your forecast helps you understand where bumps are expected.",
            "arrow.up.and.down"
        ),
        (
            "forecast",
            "How does the forecast work?",
            "Our forecast uses upper-atmosphere wind data from weather models (Open-Meteo, powered by NOAA/ECMWF). We analyze wind speed, direction, and temperature at multiple pressure levels along your route.\n\nWhen there's a big difference in wind between adjacent altitudes (wind shear), turbulence is likely. We also factor in jet stream proximity, which amplifies Clear Air Turbulence.\n\nYou can choose 3, 7, or 14-day forecasts.",
            "chart.line.uptrend.xyaxis"
        ),
        (
            "tips",
            "Tips for nervous flyers",
            "• Keep your seatbelt loosely fastened at all times when seated\n• Choose a seat over the wing — it's the smoothest part of the plane\n• Look out the window — it helps your brain understand the motion\n• Turbulence feels worse than it is — the plane moves less than you think\n• Remember: pilots fly through turbulence daily, it's routine\n• Use this app to know what to expect — knowledge reduces anxiety",
            "heart.fill"
        ),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.blue)
                        Text("Turbulence Guide")
                            .font(.title2.bold())
                        Text("Everything you need to know")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 16)

                    ForEach(faqItems, id: \.id) { item in
                        faqCard(item: item)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func faqCard(item: (id: String, question: String, answer: String, icon: String)) -> some View {
        let isExpanded = expandedItem == item.id

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    expandedItem = isExpanded ? nil : item.id
                }
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: item.icon)
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                        .frame(width: 28)

                    Text(item.question)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(16)
            }

            if isExpanded {
                Text(item.answer)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .padding(.leading, 42)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    TurbulenceFAQView()
}
