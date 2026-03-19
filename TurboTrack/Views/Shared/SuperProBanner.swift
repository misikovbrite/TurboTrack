import SwiftUI

/// Horizontal Super Pro upsell banner — shown when isPro && !hasSuperPro.
struct SuperProBanner: View {
    let source: String

    @EnvironmentObject var subscriptionService: SubscriptionService
    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        Button(action: {
            subscriptionService.showUpsellFlow(source: source)
        }) {
            ZStack {
                // Dark background with subtle blue gradient
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.06, green: 0.08, blue: 0.16),
                                Color(red: 0.04, green: 0.06, blue: 0.14)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 76)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.blue.opacity(0.4),
                                        Color.cyan.opacity(0.6),
                                        Color.blue.opacity(0.4)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .overlay(
                        // Shimmer effect
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .clear,
                                        Color.white.opacity(0.05),
                                        Color.white.opacity(0.1),
                                        Color.white.opacity(0.05),
                                        .clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .offset(x: shimmerOffset)
                            .mask(RoundedRectangle(cornerRadius: 16))
                    )

                HStack(spacing: 14) {
                    // Icon with glow
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Circle()
                            .fill(Color.blue.opacity(0.05))
                            .frame(width: 52, height: 52)

                        Image(systemName: "shield.checkered")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Unlock Super Pro")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, Color(red: 0.7, green: 0.85, blue: 1.0)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Text("10× accuracy · 14-day forecasts")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.cyan.opacity(0.7))
                    }

                    Spacer()

                    // Arrow with pill background
                    ZStack {
                        Capsule()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 32, height: 28)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.cyan)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                shimmerOffset = 400
            }
        }
    }
}

#Preview {
    SuperProBanner(source: "preview")
        .environmentObject(SubscriptionService())
        .padding()
        .background(Color(.systemGroupedBackground))
}
