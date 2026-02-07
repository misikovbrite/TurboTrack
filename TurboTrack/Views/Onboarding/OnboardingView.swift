import SwiftUI
import StoreKit
import UIKit

struct OnboardingView: View {
    var onComplete: () -> Void

    @State private var currentStep = 0
    @State private var quizAnswer1: String?
    @State private var quizAnswer2: String?
    @State private var quizAnswer3: String?
    @State private var selectedInterests: Set<String> = []
    @State private var quizAnswer5: String?

    // Animation states
    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var cardsOpacity: Double = 0
    @State private var cardOffsets: [CGFloat] = [30, 30, 30, 30]

    // Floating animation
    @State private var floatingOffset1: CGFloat = 0
    @State private var floatingOffset2: CGFloat = 0
    @State private var floatingOffset3: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0

    // Feature-specific states
    @State private var fanCardsVisible: [Bool] = [false, false, false, false, false]
    @State private var levelCardsRow1Offset: CGFloat = 0
    @State private var levelCardsRow2Offset: CGFloat = 0
    @State private var reportCardsVisible: [Bool] = [false, false, false]
    @State private var quadrantVisible: [Bool] = [false, false, false, false]

    // Setup screen states
    @State private var setupProgress: CGFloat = 0
    @State private var setupStepsCompleted: [Bool] = [false, false, false, false]
    @State private var currentSetupStepIndex: Int = -1
    @State private var showSetupStats = false

    private let totalSteps = 13 // 0-12

    // Theme
    private let accent = Color(red: 0.20, green: 0.50, blue: 0.95)
    private let accentLight = Color(red: 0.40, green: 0.65, blue: 1.0)

    var body: some View {
        ZStack {
            if currentStep != 11 {
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(red: 0.93, green: 0.96, blue: 1.0),
                            Color(red: 0.90, green: 0.94, blue: 0.99),
                            Color(red: 0.88, green: 0.92, blue: 0.98)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    floatingOrbs
                }
                .ignoresSafeArea()
            }

            Group {
                switch currentStep {
                case 0: welcomeScreen
                case 1: feature1Screen
                case 2: forecastFanScreen
                case 3: feature3Screen
                case 4: feature4Screen
                case 5: dataQuadrantsScreen
                case 6: quiz1Screen
                case 7: quiz2Screen
                case 8: quiz3Screen
                case 9: quiz4Screen
                case 10: quiz5Screen
                case 11: darkSetupScreen
                case 12: completionScreen
                default: EmptyView()
                }
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: currentStep)
        }
        .onChange(of: currentStep) { _ in
            resetAnimations()
            triggerAnimations()
            if currentStep == 2 { startFanAnimation(); requestAppRating() }
            if currentStep == 3 { startLevelCarouselAnimation() }
            if currentStep == 4 { startReportCardsAnimation() }
            if currentStep == 5 { startQuadrantAnimations() }
            if currentStep == 11 { startSetupAnimation() }
        }
        .onAppear {
            triggerAnimations()
            startFloatingAnimations()
        }
    }

    // MARK: - Animation Helpers

    private func resetAnimations() {
        iconScale = 0.5
        iconOpacity = 0
        titleOpacity = 0
        subtitleOpacity = 0
        cardsOpacity = 0
        cardOffsets = [30, 30, 30, 30]
        fanCardsVisible = [false, false, false, false, false]
        levelCardsRow1Offset = 0
        levelCardsRow2Offset = 0
        reportCardsVisible = [false, false, false]
        quadrantVisible = [false, false, false, false]
        currentSetupStepIndex = -1
    }

    private func triggerAnimations() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
            iconScale = 1.0
            iconOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
            titleOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.6).delay(0.7)) {
            subtitleOpacity = 1.0
        }
        for i in 0..<4 {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4 + Double(i) * 0.1)) {
                cardOffsets[i] = 0
            }
        }
        withAnimation(.easeOut(duration: 0.6).delay(0.9)) {
            cardsOpacity = 1.0
        }
    }

    // MARK: - Floating Orbs

    private var floatingOrbs: some View {
        GeometryReader { geo in
            Circle()
                .fill(accent.opacity(0.08))
                .frame(width: 200, height: 200)
                .blur(radius: 40)
                .offset(x: geo.size.width * 0.6, y: geo.size.height * 0.15 + floatingOffset1)
            Circle()
                .fill(Color.cyan.opacity(0.06))
                .frame(width: 160, height: 160)
                .blur(radius: 35)
                .offset(x: geo.size.width * 0.1, y: geo.size.height * 0.55 + floatingOffset2)
            Circle()
                .fill(Color.indigo.opacity(0.06))
                .frame(width: 120, height: 120)
                .blur(radius: 30)
                .offset(x: geo.size.width * 0.7, y: geo.size.height * 0.75 + floatingOffset3)
        }
    }

    private func startFloatingAnimations() {
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            floatingOffset1 = 20
        }
        withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true).delay(0.5)) {
            floatingOffset2 = -15
        }
        withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true).delay(1)) {
            floatingOffset3 = 18
        }
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            pulseScale = 1.08
        }
    }

    // MARK: - Step 0: Welcome

    private var welcomeScreen: some View {
        onboardingPage {
            VStack(spacing: 0) {
                Spacer(minLength: 20)

                ZStack {
                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .fill(accent.opacity(0.2))
                        .frame(width: 140, height: 140)
                        .blur(radius: 20)
                        .scaleEffect(pulseScale)

                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(LinearGradient(colors: [accent, accentLight], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 120, height: 120)
                        .shadow(color: accent.opacity(0.4), radius: 24, x: 0, y: 12)

                    Image(systemName: "airplane")
                        .font(.system(size: 52, weight: .medium))
                        .foregroundColor(.white)
                }
                .scaleEffect(iconScale)
                .opacity(iconOpacity)

                Spacer().frame(height: 32)

                VStack(spacing: 4) {
                    Text("Turbulence")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.2))
                    Text("Forecast")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundColor(accent)
                }
                .opacity(titleOpacity)

                Spacer().frame(height: 12)

                Text("Know what to expect\nbefore you fly")
                    .font(.system(size: 17))
                    .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.5))
                    .multilineTextAlignment(.center)
                    .opacity(subtitleOpacity)

                Spacer(minLength: 24)

                continueButton { withAnimation { currentStep = 1 } }
                    .padding(.bottom, 50)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Step 1: Feature — Check Any Route

    private var feature1Screen: some View {
        onboardingPage {
            VStack(spacing: 0) {
                Spacer(minLength: 20)

                // Route demo card
                VStack(spacing: 16) {
                    HStack(spacing: 10) {
                        VStack(spacing: 6) {
                            Circle().fill(.green).frame(width: 10, height: 10)
                            Rectangle().fill(.secondary.opacity(0.3)).frame(width: 2, height: 24)
                            Circle().fill(.red).frame(width: 10, height: 10)
                        }
                        VStack(spacing: 8) {
                            routeDemoField("New York (KJFK)")
                            routeDemoField("London (EGLL)")
                        }
                    }
                    RoundedRectangle(cornerRadius: 12)
                        .fill(accent)
                        .frame(height: 48)
                        .overlay(
                            HStack(spacing: 8) {
                                Image(systemName: "paperplane.fill")
                                Text("Check Turbulence")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                        )
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                .padding(.horizontal, 32)
                .scaleEffect(iconScale)
                .opacity(iconOpacity)

                Spacer().frame(height: 32)

                VStack(spacing: 4) {
                    Text("Check")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundColor(accent)
                    Text("Any Route")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.2))
                }
                .opacity(titleOpacity)

                Spacer().frame(height: 12)

                Text("Enter departure and arrival to get\na detailed turbulence forecast")
                    .font(.system(size: 17))
                    .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(subtitleOpacity)

                Spacer(minLength: 24)

                continueButton { withAnimation { currentStep = 2 } }
                    .padding(.bottom, 50)
            }
            .padding(.horizontal, 24)
        }
    }

    private func routeDemoField(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.tertiarySystemFill))
        .cornerRadius(10)
    }

    // MARK: - Step 2: Forecast Fan (3-day cards)

    private let fanSeverities: [(label: String, severity: String, color: Color)] = [
        ("Mon", "Smooth", Color.green),
        ("Tue", "Light", Color.yellow),
        ("Wed", "Moderate", Color.orange),
        ("Thu", "Smooth", Color.green),
        ("Fri", "Severe", Color.red),
    ]

    private var forecastFanScreen: some View {
        onboardingPage {
            VStack(spacing: 0) {
                Spacer(minLength: 20)

                ZStack {
                    ForEach(0..<5, id: \.self) { i in
                        let angles: [Double] = [-20, -10, 0, 10, 20]
                        let xOffsets: [CGFloat] = [-60, -30, 0, 30, 60]

                        forecastFanCard(index: i)
                            .rotationEffect(.degrees(fanCardsVisible[i] ? angles[i] : 0))
                            .offset(x: fanCardsVisible[i] ? xOffsets[i] : 0)
                            .opacity(fanCardsVisible[i] ? 1.0 : 0)
                            .zIndex(Double(i))
                    }
                }
                .frame(height: 280)

                Spacer().frame(height: 32)

                VStack(spacing: 4) {
                    Text("3-Day")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundColor(accent)
                    Text("Turbulence Forecast")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.2))
                        .minimumScaleFactor(0.7)
                }
                .opacity(titleOpacity)

                Spacer().frame(height: 12)

                Text("Plan ahead with predictions based\non upper-atmosphere wind data")
                    .font(.system(size: 17))
                    .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(subtitleOpacity)

                Spacer(minLength: 24)

                continueButton { withAnimation { currentStep = 3 } }
                    .padding(.bottom, 50)
            }
            .padding(.horizontal, 24)
        }
    }

    private func forecastFanCard(index: Int) -> some View {
        let item = fanSeverities[index]
        return VStack(spacing: 14) {
            Text(item.label)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white.opacity(0.8))

            Circle()
                .fill(.white.opacity(0.3))
                .frame(width: 48, height: 48)
                .overlay(
                    Circle()
                        .fill(.white)
                        .frame(width: 28, height: 28)
                )

            Text(item.severity)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            // Mini bar chart
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { j in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.white.opacity(j <= index ? 0.8 : 0.2))
                        .frame(width: 12, height: CGFloat(8 + j * 6))
                }
            }
        }
        .padding(.vertical, 20)
        .frame(width: 150, height: 220)
        .background(item.color.gradient)
        .cornerRadius(16)
    }

    private func startFanAnimation() {
        for i in 0..<5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 + Double(i) * 0.08) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    fanCardsVisible[i] = true
                }
            }
        }
    }

    // MARK: - Step 3: Flight Levels Carousel

    private let levelRow1: [(level: String, feet: String, icon: String, color: Color)] = [
        ("FL390", "39,000 ft", "airplane", .red),
        ("FL340", "34,000 ft", "airplane", .orange),
        ("FL300", "30,000 ft", "airplane", .yellow),
        ("FL240", "24,000 ft", "airplane", .green),
        ("FL180", "18,000 ft", "airplane", .blue),
        ("FL100", "10,000 ft", "airplane", .cyan),
    ]

    private let levelRow2: [(label: String, icon: String, color: Color)] = [
        ("Wind Shear", "wind", .orange),
        ("Jet Stream", "arrow.right", .purple),
        ("CAT", "cloud.bolt", .red),
        ("Mountain Wave", "mountain.2", .green),
        ("Convective", "cloud.bolt.rain", .yellow),
        ("SIGMET", "exclamationmark.triangle", .red),
    ]

    private var feature3Screen: some View {
        onboardingPage {
            VStack(spacing: 0) {
                Spacer(minLength: 20)

                VStack(spacing: 12) {
                    // Row 1: Flight levels
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            // Double the items for seamless loop feel
                            ForEach(0..<12, id: \.self) { i in
                                let item = levelRow1[i % levelRow1.count]
                                levelCard(level: item.level, feet: item.feet, color: item.color)
                            }
                        }
                        .offset(x: levelCardsRow1Offset)
                    }
                    .frame(height: 90)

                    // Row 2: Turbulence types
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(0..<12, id: \.self) { i in
                                let item = levelRow2[i % levelRow2.count]
                                typeCard(label: item.label, icon: item.icon, color: item.color)
                            }
                        }
                        .offset(x: levelCardsRow2Offset)
                    }
                    .frame(height: 90)
                }
                .scaleEffect(iconScale)
                .opacity(iconOpacity)

                Spacer().frame(height: 32)

                VStack(spacing: 4) {
                    Text("Every Altitude")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundColor(accent)
                    Text("Covered")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.2))
                }
                .opacity(titleOpacity)

                Spacer().frame(height: 12)

                Text("Turbulence data at every flight level\nfrom FL100 to FL390")
                    .font(.system(size: 17))
                    .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(subtitleOpacity)

                Spacer(minLength: 24)

                continueButton { withAnimation { currentStep = 4 } }
                    .padding(.bottom, 50)
            }
            .padding(.horizontal, 24)
        }
    }

    private func levelCard(level: String, feet: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: "airplane")
                .font(.system(size: 18))
                .foregroundColor(color)
            Text(level)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.2))
            Text(feet)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(width: 100, height: 80)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }

    private func typeCard(label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(color.gradient)
                .cornerRadius(10)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.2))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(width: 100, height: 80)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }

    private func startLevelCarouselAnimation() {
        withAnimation(.linear(duration: 14).repeatForever(autoreverses: false)) {
            levelCardsRow1Offset = -400
        }
        withAnimation(.linear(duration: 14).repeatForever(autoreverses: false).delay(0.3)) {
            levelCardsRow2Offset = 400
        }
    }

    // MARK: - Step 4: Live Pilot Reports

    private let pirepCards: [(aircraft: String, level: String, severity: String, color: Color, icon: String)] = [
        ("B738", "FL350", "Moderate", .orange, "cloud.bolt.fill"),
        ("A320", "FL300", "Light", .yellow, "cloud.fill"),
        ("B777", "FL390", "Severe", .red, "exclamationmark.triangle.fill"),
    ]

    private var feature4Screen: some View {
        onboardingPage {
            VStack(spacing: 0) {
                Spacer(minLength: 20)

                VStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { i in
                        let card = pirepCards[i]
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(card.color.gradient)
                                    .frame(width: 48, height: 48)
                                Image(systemName: card.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(card.aircraft) at \(card.level)")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.2))
                                Text("\(card.severity) Turbulence")
                                    .font(.system(size: 14))
                                    .foregroundColor(card.color)
                            }
                            Spacer()
                            Text("PIREP")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(card.color)
                                .cornerRadius(6)
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
                        .scaleEffect(reportCardsVisible[i] ? 1.0 : 0.3)
                        .opacity(reportCardsVisible[i] ? 1.0 : 0)
                    }
                }
                .padding(.horizontal, 16)

                Spacer().frame(height: 32)

                VStack(spacing: 4) {
                    Text("Live Pilot")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundColor(accent)
                    Text("Reports")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.2))
                }
                .opacity(titleOpacity)

                Spacer().frame(height: 12)

                Text("Real-time turbulence reports from pilots\naround the world, updated every 5 minutes")
                    .font(.system(size: 17))
                    .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(subtitleOpacity)

                Spacer(minLength: 24)

                continueButton { withAnimation { currentStep = 5 } }
                    .padding(.bottom, 50)
            }
            .padding(.horizontal, 24)
        }
    }

    private func startReportCardsAnimation() {
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 + Double(i) * 0.2) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                    reportCardsVisible[i] = true
                }
            }
        }
    }

    // MARK: - Step 5: Trusted Data (Quadrants)

    private var dataQuadrantsScreen: some View {
        onboardingPage {
            VStack(spacing: 0) {
                Spacer(minLength: 20)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    dataQuadrant(icon: "building.columns.fill", title: "NOAA", subtitle: "Atmospheric models", color: .blue, index: 0)
                    dataQuadrant(icon: "shield.checkered", title: "FAA AWC", subtitle: "Aviation weather", color: .green, index: 1)
                    dataQuadrant(icon: "globe.americas.fill", title: "Open-Meteo", subtitle: "Global forecasts", color: .purple, index: 2)
                    dataQuadrant(icon: "bubble.left.and.bubble.right.fill", title: "PIREPs", subtitle: "Real-time reports", color: .orange, index: 3)
                }
                .padding(.horizontal, 16)

                Spacer().frame(height: 32)

                VStack(spacing: 4) {
                    Text("Trusted")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundColor(accent)
                    Text("Aviation Data")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.2))
                }
                .opacity(titleOpacity)

                Spacer().frame(height: 12)

                Text("Powered by official weather services\nand real pilot reports worldwide")
                    .font(.system(size: 17))
                    .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(subtitleOpacity)

                Spacer(minLength: 24)

                continueButton { withAnimation { currentStep = 6 } }
                    .padding(.bottom, 50)
            }
            .padding(.horizontal, 24)
        }
    }

    private func dataQuadrant(icon: String, title: String, subtitle: String, color: Color, index: Int) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.2))
            Text(subtitle)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        .scaleEffect(quadrantVisible[index] ? 1.0 : 0.3)
        .opacity(quadrantVisible[index] ? 1.0 : 0)
    }

    private func startQuadrantAnimations() {
        for i in 0..<4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 + Double(i) * 0.15) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    quadrantVisible[i] = true
                }
            }
        }
    }

    // MARK: - Quiz 1: Flight Anxiety

    private var quiz1Screen: some View {
        onboardingPage {
            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                Text("How do you feel\nabout flying?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.15))
                    .multilineTextAlignment(.center)
                    .opacity(titleOpacity)

                Spacer().frame(height: 40)

                VStack(spacing: 12) {
                    quizOption("I love flying", subtitle: "Enjoy every minute in the air", isSelected: quizAnswer1 == "love") { quizAnswer1 = "love" }
                        .offset(y: cardOffsets[0]).opacity(cardsOpacity)
                    quizOption("A bit nervous", subtitle: "Some anxiety, especially during bumps", isSelected: quizAnswer1 == "nervous") { quizAnswer1 = "nervous" }
                        .offset(y: cardOffsets[1]).opacity(cardsOpacity)
                    quizOption("Quite anxious", subtitle: "Turbulence really worries me", isSelected: quizAnswer1 == "anxious") { quizAnswer1 = "anxious" }
                        .offset(y: cardOffsets[2]).opacity(cardsOpacity)
                    quizOption("Fear of flying", subtitle: "I get very stressed before and during flights", isSelected: quizAnswer1 == "fear") { quizAnswer1 = "fear" }
                        .offset(y: cardOffsets[3]).opacity(cardsOpacity)
                }
                .padding(.horizontal, 16)

                Spacer(minLength: 40)

                continueButton(disabled: quizAnswer1 == nil) { withAnimation { currentStep = 7 } }
                    .padding(.bottom, 50)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Quiz 2: Flight Frequency

    private var quiz2Screen: some View {
        onboardingPage {
            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                Text("How often do\nyou fly?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.15))
                    .multilineTextAlignment(.center)
                    .opacity(titleOpacity)

                Spacer().frame(height: 40)

                VStack(spacing: 12) {
                    quizOption("Frequent flyer", subtitle: "Several times a month", isSelected: quizAnswer2 == "frequent") { quizAnswer2 = "frequent" }
                        .offset(y: cardOffsets[0]).opacity(cardsOpacity)
                    quizOption("Regular traveler", subtitle: "A few times a year", isSelected: quizAnswer2 == "regular") { quizAnswer2 = "regular" }
                        .offset(y: cardOffsets[1]).opacity(cardsOpacity)
                    quizOption("Occasional", subtitle: "Once or twice a year", isSelected: quizAnswer2 == "occasional") { quizAnswer2 = "occasional" }
                        .offset(y: cardOffsets[2]).opacity(cardsOpacity)
                    quizOption("Rare / First time", subtitle: "Hardly ever or never flown", isSelected: quizAnswer2 == "rare") { quizAnswer2 = "rare" }
                        .offset(y: cardOffsets[3]).opacity(cardsOpacity)
                }
                .padding(.horizontal, 16)

                Spacer(minLength: 40)

                continueButton(disabled: quizAnswer2 == nil) { withAnimation { currentStep = 8 } }
                    .padding(.bottom, 50)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Quiz 3: Turbulence Knowledge

    private var quiz3Screen: some View {
        onboardingPage {
            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                Text("How familiar are you\nwith turbulence?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.15))
                    .multilineTextAlignment(.center)
                    .opacity(titleOpacity)

                Spacer().frame(height: 40)

                VStack(spacing: 12) {
                    quizOption("Pilot / Aviation pro", subtitle: "I read METARs, TAFs, and PIREPs", isSelected: quizAnswer3 == "pilot") { quizAnswer3 = "pilot" }
                        .offset(y: cardOffsets[0]).opacity(cardsOpacity)
                    quizOption("I know the basics", subtitle: "Light, moderate, severe — I get it", isSelected: quizAnswer3 == "basics") { quizAnswer3 = "basics" }
                        .offset(y: cardOffsets[1]).opacity(cardsOpacity)
                    quizOption("Heard of it", subtitle: "I know it exists but not much more", isSelected: quizAnswer3 == "heard") { quizAnswer3 = "heard" }
                        .offset(y: cardOffsets[2]).opacity(cardsOpacity)
                    quizOption("Complete beginner", subtitle: "I'd like to learn", isSelected: quizAnswer3 == "beginner") { quizAnswer3 = "beginner" }
                        .offset(y: cardOffsets[3]).opacity(cardsOpacity)
                }
                .padding(.horizontal, 16)

                Spacer(minLength: 40)

                continueButton(disabled: quizAnswer3 == nil) { withAnimation { currentStep = 9 } }
                    .padding(.bottom, 50)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Quiz 4: What interests you (multi-select)

    private let interestOptions: [(id: String, icon: String, title: String)] = [
        ("route", "✈️", "Route turbulence forecast"),
        ("levels", "📊", "Detailed flight level data"),
        ("tips", "💡", "Tips for handling turbulence"),
        ("notifications", "🔔", "Pre-flight notifications"),
        ("map", "🗺️", "Real-time turbulence map"),
        ("multiday", "📅", "Multi-day forecast"),
        ("pilotdata", "👨‍✈️", "Pilot-grade weather data"),
        ("anxiety", "🧘", "Anxiety management advice"),
    ]

    private var quiz4Screen: some View {
        onboardingPage {
            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                Text("What would\nhelp you most?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.15))
                    .multilineTextAlignment(.center)
                    .opacity(titleOpacity)

                Spacer().frame(height: 12)

                Text("Select all that apply")
                    .font(.system(size: 15))
                    .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.5))
                    .opacity(subtitleOpacity)

                Spacer().frame(height: 28)

                VStack(spacing: 8) {
                    ForEach(Array(interestOptions.enumerated()), id: \.element.id) { index, item in
                        interestCheckbox(id: item.id, icon: item.icon, title: item.title)
                            .offset(y: index < 4 ? cardOffsets[index] : cardOffsets[min(index - 4, 3)])
                            .opacity(cardsOpacity)
                    }
                }
                .padding(.horizontal, 16)

                Spacer(minLength: 40)

                continueButton(disabled: selectedInterests.isEmpty) { withAnimation { currentStep = 10 } }
                    .padding(.bottom, 50)
            }
            .padding(.horizontal, 24)
        }
    }

    private func interestCheckbox(id: String, icon: String, title: String) -> some View {
        let isSelected = selectedInterests.contains(id)
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if isSelected { selectedInterests.remove(id) }
                else { selectedInterests.insert(id) }
            }
        } label: {
            HStack(spacing: 10) {
                Text(icon).font(.system(size: 22))
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.2))
                    .lineLimit(1).minimumScaleFactor(0.8)
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? accent : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        RoundedRectangle(cornerRadius: 6).fill(accent).frame(width: 22, height: 22)
                        Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(isSelected ? accent.opacity(0.08) : Color.white)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? accent : Color.clear, lineWidth: 1.5))
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        }
    }

    // MARK: - Quiz 5: When do you check

    private var quiz5Screen: some View {
        onboardingPage {
            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                Text("When do you usually\ncheck your flight?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.15))
                    .multilineTextAlignment(.center)
                    .opacity(titleOpacity)

                Spacer().frame(height: 12)

                Text("We'll optimize your forecast range")
                    .font(.system(size: 15))
                    .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.5))
                    .opacity(subtitleOpacity)

                Spacer().frame(height: 40)

                VStack(spacing: 12) {
                    quizOption("Day of the flight", subtitle: "I check right before traveling", isSelected: quizAnswer5 == "sameday") { quizAnswer5 = "sameday" }
                        .offset(y: cardOffsets[0]).opacity(cardsOpacity)
                    quizOption("1–2 days before", subtitle: "I like a bit of advance notice", isSelected: quizAnswer5 == "1-2days") { quizAnswer5 = "1-2days" }
                        .offset(y: cardOffsets[1]).opacity(cardsOpacity)
                    quizOption("3–5 days before", subtitle: "I plan well ahead", isSelected: quizAnswer5 == "3-5days") { quizAnswer5 = "3-5days" }
                        .offset(y: cardOffsets[2]).opacity(cardsOpacity)
                    quizOption("A week or more", subtitle: "I want the longest possible forecast", isSelected: quizAnswer5 == "week") { quizAnswer5 = "week" }
                        .offset(y: cardOffsets[3]).opacity(cardsOpacity)
                }
                .padding(.horizontal, 16)

                Spacer(minLength: 40)

                continueButton(disabled: quizAnswer5 == nil) { withAnimation { currentStep = 11 } }
                    .padding(.bottom, 50)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Dark Setup Screen

    private let setupSteps = [
        "Loading atmospheric models…",
        "Calibrating turbulence algorithms…",
        "Connecting to weather stations…",
        "Personalizing your experience…"
    ]

    private let creamColor = Color(red: 0.98, green: 0.96, blue: 0.93)

    private var darkSetupScreen: some View {
        ZStack {
            Color(red: 0.04, green: 0.06, blue: 0.12).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 80)

                    Text("Preparing Your\nForecast Engine")
                        .font(.system(size: 38, weight: .bold, design: .serif))
                        .foregroundColor(creamColor)
                        .multilineTextAlignment(.center)
                        .scaleEffect(x: 0.85, y: 1.0)

                    Spacer().frame(height: 40)

                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 16)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(creamColor)
                            .frame(width: max(0, (UIScreen.main.bounds.width - 80) * setupProgress), height: 12)
                            .padding(.leading, 2)
                    }
                    .padding(.horizontal, 32)

                    Spacer().frame(height: 32)

                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(0..<4, id: \.self) { i in
                            darkSetupStepRow(
                                text: setupSteps[i],
                                isActive: currentSetupStepIndex == i,
                                isCompleted: setupStepsCompleted[i]
                            )
                        }
                    }
                    .padding(.horizontal, 40)

                    Spacer().frame(height: 60)

                    if showSetupStats {
                        VStack(spacing: 8) {
                            Text("Trusted by")
                                .font(.system(size: 18))
                                .foregroundColor(creamColor.opacity(0.7))
                            Text("Travelers & Pilots")
                                .font(.system(size: 32, weight: .bold, design: .serif))
                                .foregroundColor(creamColor)
                        }
                        .transition(.opacity.combined(with: .scale))

                        Spacer().frame(height: 24)
                        darkTestimonialsCarousel
                    }

                    Spacer().frame(height: 50)
                }
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func darkSetupStepRow(text: String, isActive: Bool, isCompleted: Bool) -> some View {
        HStack(spacing: 12) {
            if isCompleted {
                Text("✓").font(.system(size: 16, weight: .bold)).foregroundColor(creamColor.opacity(0.7)).frame(width: 20)
            } else if isActive {
                Text("◉").font(.system(size: 16)).foregroundColor(creamColor).frame(width: 20)
            } else {
                Text("○").font(.system(size: 16)).foregroundColor(creamColor.opacity(0.5)).frame(width: 20)
            }
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(isActive ? creamColor : (isCompleted ? creamColor.opacity(0.7) : creamColor.opacity(0.5)))
        }
    }

    private var darkTestimonialsCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                darkTestimonialCard(
                    text: "Finally I can check turbulence before I fly. Really helps with my anxiety.",
                    author: "Sarah M.", role: "Nervous Flyer"
                )
                darkTestimonialCard(
                    text: "I use this before every flight. The forecast has been surprisingly accurate.",
                    author: "David K.", role: "Frequent Traveler"
                )
                darkTestimonialCard(
                    text: "The flight level breakdown is very useful for pre-flight planning.",
                    author: "Capt. James R.", role: "Commercial Pilot"
                )
                darkTestimonialCard(
                    text: "So simple. Enter your route and get instant results. Love it!",
                    author: "Emma L.", role: "Business Traveler"
                )
            }
            .padding(.horizontal, 24)
        }
    }

    private func darkTestimonialCard(text: String, author: String, role: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill").font(.system(size: 12)).foregroundColor(.white)
                }
            }
            Text("\"\(text)\"")
                .font(.system(size: 17)).foregroundColor(creamColor).lineSpacing(2)
            Text("— \(author), \(role)")
                .font(.system(size: 14, weight: .medium)).foregroundColor(creamColor.opacity(0.6))
        }
        .padding(20)
        .frame(width: 280)
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }

    // MARK: - Completion Screen

    private var completionScreen: some View {
        onboardingPage {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)

                Text("✈️")
                    .font(.system(size: 80))
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)

                Spacer().frame(height: 30)

                Text("You're Ready to Fly")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.2))
                    .multilineTextAlignment(.center)
                    .opacity(titleOpacity)

                Spacer().frame(height: 16)

                Text("Your personalized turbulence forecast\nis set up and ready to go.")
                    .font(.system(size: 19))
                    .foregroundColor(Color(red: 0.35, green: 0.35, blue: 0.4))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .opacity(subtitleOpacity)

                Spacer(minLength: 40)

                Button {
                    onComplete()
                } label: {
                    Text("Get Started")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: 340)
                        .frame(height: 64)
                        .background(Color.black)
                        .cornerRadius(32)
                }
                .padding(.bottom, 50)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Setup Animation

    private func startSetupAnimation() {
        setupProgress = 0
        setupStepsCompleted = [false, false, false, false]
        currentSetupStepIndex = -1
        showSetupStats = false
        animateSetupStep(index: 0)
    }

    private func animateSetupStep(index: Int) {
        guard index < 4 else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { showSetupStats = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation { currentStep = 12 }
                }
            }
            return
        }
        withAnimation(.easeOut(duration: 0.3)) { currentSetupStepIndex = index }
        withAnimation(.easeInOut(duration: 0.8)) { setupProgress = CGFloat(index + 1) / 4.0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.3)) {
                setupStepsCompleted[index] = true
                currentSetupStepIndex = -1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                animateSetupStep(index: index + 1)
            }
        }
    }

    // MARK: - Shared Components

    private func onboardingPage<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        GeometryReader { geo in
            ScrollView(showsIndicators: false) {
                content()
                    .frame(maxWidth: 520)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: geo.size.height)
            }
        }
    }

    private func continueButton(disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("Continue")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: 340)
                .frame(height: 64)
                .background(disabled ? Color.gray : accent)
                .cornerRadius(32)
                .shadow(color: accent.opacity(0.3), radius: 12, x: 0, y: 4)
        }
        .disabled(disabled)
    }

    private func quizOption(_ title: String, subtitle: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.2))
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.5))
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(isSelected ? accent : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    if isSelected {
                        Circle().fill(accent).frame(width: 16, height: 16)
                    }
                }
            }
            .padding(20)
            .background(isSelected ? accent.opacity(0.08) : Color.white)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(isSelected ? accent : Color.clear, lineWidth: 2))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - App Rating

    private func requestAppRating() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
            }
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
