import SwiftUI
import StoreKit
import UIKit

struct OnboardingView: View {
    var onComplete: () -> Void

    @State private var currentStep = 0
    @State private var quizAnxiety: String?
    @State private var quizWorstFear: String?
    @State private var quizImpact: String?
    @State private var selectedHelpers: Set<String> = []
    @State private var quizNextFlight: String?

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
    @State private var planeOffset: CGFloat = 0
    @State private var calendarCellsVisible: [Bool] = Array(repeating: false, count: 14)
    @State private var routeDrawProgress: CGFloat = 0
    @State private var mapLegendOpacity: Double = 0

    // Setup screen states
    @State private var setupProgress: CGFloat = 0
    @State private var setupStepsCompleted: [Bool] = [false, false, false, false]
    @State private var currentSetupStepIndex: Int = -1
    @State private var showSetupStats = false

    private let totalSteps = 10 // 0-9, step 9 = dark setup → onComplete → paywall

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isIPad: Bool { horizontalSizeClass == .regular }

    // Theme
    private let accent = Color(red: 0.20, green: 0.50, blue: 0.95)
    private let accentLight = Color(red: 0.40, green: 0.65, blue: 1.0)

    var body: some View {
        ZStack {
            if currentStep != 9 {
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
                case 1: featureKnowScreen
                case 2: featurePlanScreen
                case 3: featureUnderstandScreen
                case 4: quizAnxietyScreen
                case 5: quizWorstFearScreen
                case 6: quizImpactScreen
                case 7: quizHelpScreen
                case 8: quizNextFlightScreen
                case 9: darkSetupScreen
                default: EmptyView()
                }
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: currentStep)
        }
        .onChange(of: currentStep) { _ in
            resetAnimations()
            triggerAnimations()
            if currentStep == 1 { startFlightCardAnimation() }
            if currentStep == 2 { startCalendarAnimation(); requestAppRating() }
            if currentStep == 3 { startMapAnimation() }
            if currentStep == 9 { startSetupAnimation() }
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
        planeOffset = 0
        calendarCellsVisible = Array(repeating: false, count: 14)
        routeDrawProgress = 0
        mapLegendOpacity = 0
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
                Spacer()

                Image("onboarding_welcome")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 220, height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: accent.opacity(0.3), radius: 24, x: 0, y: 12)
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)

                Spacer().frame(height: 28)

                VStack(spacing: 4) {
                    Text("Fly Calm")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundColor(accent)
                    Text("Every Time")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.2))
                }
                .opacity(titleOpacity)

                Spacer().frame(height: 12)

                Text("Know what turbulence to expect\nbefore you board")
                    .font(.system(size: 17))
                    .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.5))
                    .multilineTextAlignment(.center)
                    .opacity(subtitleOpacity)

                Spacer().frame(height: 32)

                continueButton { withAnimation { currentStep = 1 } }
                    .padding(.bottom, 50)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Step 1: Know Before You Fly

    private var featureKnowScreen: some View {
        onboardingPage {
            VStack(spacing: 0) {
                Spacer()

                flightCardWidget
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)

                Spacer().frame(height: 24)

                VStack(spacing: 4) {
                    Text("Know Before")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundColor(accent)
                    Text("You Fly")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.2))
                }
                .opacity(titleOpacity)

                Spacer().frame(height: 12)

                Text("Enter your flight and see exactly\nwhen and where to expect bumps")
                    .font(.system(size: 17))
                    .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(subtitleOpacity)

                Spacer().frame(height: 32)

                continueButton { withAnimation { currentStep = 2 } }
                    .padding(.bottom, 50)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Flight Card Widget

    private var flightCardWidget: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        Circle().fill(Color.green).frame(width: 8, height: 8)
                        Text("JFK").font(.system(size: 11, weight: .bold)).foregroundColor(.secondary)
                    }
                    Text("New York")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.2))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 5) {
                        Text("LHR").font(.system(size: 11, weight: .bold)).foregroundColor(.secondary)
                        Circle().fill(Color.red).frame(width: 8, height: 8)
                    }
                    Text("London")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.2))
                }
            }

            GeometryReader { geo in
                let w = geo.size.width
                let t = planeOffset
                let curveY: CGFloat = 20 * (1 - 3 * t + 3 * t * t)

                Path { p in
                    p.move(to: CGPoint(x: 0, y: 20))
                    p.addQuadCurve(to: CGPoint(x: w, y: 20), control: CGPoint(x: w / 2, y: -10))
                }
                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                .foregroundColor(Color.gray.opacity(0.25))

                Image(systemName: "airplane")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(accent)
                    .position(x: max(1, w * t), y: curveY)
                    .opacity(t > 0 ? 1 : 0)
            }
            .frame(height: 40)

            HStack(spacing: 6) {
                Circle().fill(Color(red: 0.80, green: 0.68, blue: 0.0)).frame(width: 8, height: 8)
                Text("Light Turbulence")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 0.4, green: 0.35, blue: 0.05))
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(Color(red: 0.80, green: 0.68, blue: 0.0).opacity(0.12))
            .cornerRadius(20)

            HStack {
                Label("7h 20m", systemImage: "clock")
                    .font(.system(size: 12, weight: .medium)).foregroundColor(.secondary)
                Spacer()
                Label("Feb 18", systemImage: "calendar")
                    .font(.system(size: 12, weight: .medium)).foregroundColor(.secondary)
            }
        }
        .padding(22)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 16)
    }

    private func startFlightCardAnimation() {
        planeOffset = 0
        withAnimation(.easeInOut(duration: 2.0).delay(0.5)) {
            planeOffset = 1.0
        }
    }

    // MARK: - Step 2: Plan Ahead (Forecast Fan)

    // MARK: - Step 2: 14-Day Forecast (Calendar)

    private let calendarData: [(day: Int, color: Color)] = [
        (15, Color(red: 0.30, green: 0.69, blue: 0.31)),
        (16, Color(red: 0.30, green: 0.69, blue: 0.31)),
        (17, Color(red: 0.80, green: 0.68, blue: 0.0)),
        (18, Color(red: 0.30, green: 0.69, blue: 0.31)),
        (19, Color(red: 0.30, green: 0.69, blue: 0.31)),
        (20, Color(red: 1.0, green: 0.60, blue: 0.0)),
        (21, Color(red: 0.30, green: 0.69, blue: 0.31)),
        (22, Color(red: 0.80, green: 0.68, blue: 0.0)),
        (23, Color(red: 0.30, green: 0.69, blue: 0.31)),
        (24, Color(red: 0.30, green: 0.69, blue: 0.31)),
        (25, Color(red: 0.30, green: 0.69, blue: 0.31)),
        (26, Color(red: 0.96, green: 0.26, blue: 0.21)),
        (27, Color(red: 0.30, green: 0.69, blue: 0.31)),
        (28, Color(red: 0.80, green: 0.68, blue: 0.0)),
    ]

    private var featurePlanScreen: some View {
        onboardingPage {
            VStack(spacing: 0) {
                Spacer()

                calendarWidget
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)

                Spacer().frame(height: 24)

                VStack(spacing: 4) {
                    Text("14-Day")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundColor(accent)
                    Text("Forecast")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.2))
                }
                .opacity(titleOpacity)

                Spacer().frame(height: 12)

                Text("Plan ahead — check turbulence\nup to two weeks before your flight")
                    .font(.system(size: 17))
                    .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(subtitleOpacity)

                Spacer().frame(height: 32)

                continueButton { withAnimation { currentStep = 3 } }
                    .padding(.bottom, 50)
            }
            .padding(.horizontal, 24)
        }
    }

    private var calendarWidget: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Feb 15 — Mar 1")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.2))
                Spacer()
                Image(systemName: "airplane.departure")
                    .font(.system(size: 14))
                    .foregroundColor(accent)
            }

            let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]
            HStack(spacing: 6) {
                ForEach(0..<7, id: \.self) { i in
                    Text(dayLabels[i])
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            HStack(spacing: 6) {
                ForEach(0..<7, id: \.self) { i in calendarCell(index: i) }
            }

            HStack(spacing: 6) {
                ForEach(7..<14, id: \.self) { i in calendarCell(index: i) }
            }

            HStack(spacing: 12) {
                calendarLegend(color: Color(red: 0.30, green: 0.69, blue: 0.31), label: "Smooth")
                calendarLegend(color: Color(red: 0.80, green: 0.68, blue: 0.0), label: "Light")
                calendarLegend(color: Color(red: 1.0, green: 0.60, blue: 0.0), label: "Moderate")
                calendarLegend(color: Color(red: 0.96, green: 0.26, blue: 0.21), label: "Severe")
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 16)
    }

    private func calendarCell(index: Int) -> some View {
        let item = calendarData[index]
        return Text("\(item.day)")
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(item.color)
            .cornerRadius(8)
            .scaleEffect(calendarCellsVisible[index] ? 1.0 : 0.3)
            .opacity(calendarCellsVisible[index] ? 1.0 : 0)
    }

    private func calendarLegend(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label).font(.system(size: 11)).foregroundColor(.secondary)
        }
    }

    private func startCalendarAnimation() {
        calendarCellsVisible = Array(repeating: false, count: 14)
        for i in 0..<14 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + Double(i) * 0.06) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    calendarCellsVisible[i] = true
                }
            }
        }
    }

    // MARK: - Step 3: Understand Every Bump

    // MARK: - Step 3: Understand Every Bump (Turbulence Map)

    private var featureUnderstandScreen: some View {
        onboardingPage {
            VStack(spacing: 0) {
                Spacer()

                turbulenceMapWidget
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)

                Spacer().frame(height: 24)

                VStack(spacing: 4) {
                    Text("Understand")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundColor(accent)
                    Text("Every Bump")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.2))
                }
                .opacity(titleOpacity)

                Spacer().frame(height: 12)

                Text("From a gentle ripple to a bumpy road —\nwe explain each level in plain words")
                    .font(.system(size: 17))
                    .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(subtitleOpacity)

                Spacer().frame(height: 32)

                continueButton { withAnimation { currentStep = 4 } }
                    .padding(.bottom, 50)
            }
            .padding(.horizontal, 24)
        }
    }

    private var turbulenceMapWidget: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Turbulence Map")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                HStack(spacing: 4) {
                    Circle().fill(Color.green).frame(width: 6, height: 6)
                    Text("Live")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color.green.opacity(0.15))
                .cornerRadius(8)
            }
            .padding(.horizontal, 20).padding(.top, 20)

            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let route = mapRoutePath(width: w, height: h)

                // Subtle grid
                ForEach(0..<4, id: \.self) { i in
                    Path { p in
                        let y = h * CGFloat(i + 1) / 5
                        p.move(to: CGPoint(x: 0, y: y))
                        p.addLine(to: CGPoint(x: w, y: y))
                    }
                    .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                }
                ForEach(0..<6, id: \.self) { i in
                    Path { p in
                        let x = w * CGFloat(i + 1) / 7
                        p.move(to: CGPoint(x: x, y: 0))
                        p.addLine(to: CGPoint(x: x, y: h))
                    }
                    .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                }

                // Green segment 0–35%
                route
                    .trim(from: 0, to: min(routeDrawProgress, 0.35))
                    .stroke(Color(red: 0.30, green: 0.69, blue: 0.31), style: StrokeStyle(lineWidth: 3, lineCap: .round))

                // Yellow segment 35–55%
                if routeDrawProgress > 0.35 {
                    route
                        .trim(from: 0.35, to: min(routeDrawProgress, 0.55))
                        .stroke(Color(red: 0.80, green: 0.68, blue: 0.0), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                }

                // Orange segment 55–70%
                if routeDrawProgress > 0.55 {
                    route
                        .trim(from: 0.55, to: min(routeDrawProgress, 0.70))
                        .stroke(Color(red: 1.0, green: 0.60, blue: 0.0), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                }

                // Green segment 70–100%
                if routeDrawProgress > 0.70 {
                    route
                        .trim(from: 0.70, to: routeDrawProgress)
                        .stroke(Color(red: 0.30, green: 0.69, blue: 0.31), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                }

                // Airport markers
                Circle().fill(Color.white).frame(width: 8, height: 8)
                    .position(x: 24, y: h * 0.65)
                Text("JFK")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
                    .position(x: 24, y: h * 0.65 + 14)

                Circle().fill(Color.white).frame(width: 8, height: 8)
                    .position(x: w - 24, y: h * 0.35)
                Text("LHR")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
                    .position(x: w - 24, y: h * 0.35 + 14)
            }
            .frame(height: 140)
            .padding(.horizontal, 16).padding(.vertical, 12)

            HStack(spacing: 16) {
                mapLegendItem(color: Color(red: 0.30, green: 0.69, blue: 0.31), label: "Smooth")
                mapLegendItem(color: Color(red: 0.80, green: 0.68, blue: 0.0), label: "Light")
                mapLegendItem(color: Color(red: 1.0, green: 0.60, blue: 0.0), label: "Moderate")
            }
            .padding(.bottom, 16)
            .opacity(mapLegendOpacity)
        }
        .background(Color(red: 0.08, green: 0.10, blue: 0.18))
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 16)
    }

    private func mapRoutePath(width: CGFloat, height: CGFloat) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 24, y: height * 0.65))
        path.addCurve(
            to: CGPoint(x: width - 24, y: height * 0.35),
            control1: CGPoint(x: width * 0.35, y: height * 0.15),
            control2: CGPoint(x: width * 0.65, y: height * 0.55)
        )
        return path
    }

    private func mapLegendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 12, height: 4)
            Text(label).font(.system(size: 11, weight: .medium)).foregroundColor(.white.opacity(0.6))
        }
    }

    private func startMapAnimation() {
        routeDrawProgress = 0
        mapLegendOpacity = 0
        withAnimation(.easeInOut(duration: 1.8).delay(0.4)) {
            routeDrawProgress = 1.0
        }
        withAnimation(.easeOut(duration: 0.5).delay(2.0)) {
            mapLegendOpacity = 1.0
        }
    }

    // MARK: - Quiz 1: Does turbulence make your heart race?

    private var quizAnxietyScreen: some View {
        onboardingPage {
            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                Text("Does turbulence make\nyour heart race?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.15))
                    .multilineTextAlignment(.center)
                    .opacity(titleOpacity)

                Spacer().frame(height: 40)

                VStack(spacing: 12) {
                    quizOption("Not really", subtitle: "I stay calm during flights", isSelected: quizAnxiety == "calm") { quizAnxiety = "calm" }
                        .offset(y: cardOffsets[0]).opacity(cardsOpacity)
                    quizOption("A little", subtitle: "I grip the armrest during bumps", isSelected: quizAnxiety == "little") { quizAnxiety = "little" }
                        .offset(y: cardOffsets[1]).opacity(cardsOpacity)
                    quizOption("Yes, definitely", subtitle: "My heart pounds and palms sweat", isSelected: quizAnxiety == "yes") { quizAnxiety = "yes" }
                        .offset(y: cardOffsets[2]).opacity(cardsOpacity)
                    quizOption("I can barely breathe", subtitle: "I have full panic attacks", isSelected: quizAnxiety == "panic") { quizAnxiety = "panic" }
                        .offset(y: cardOffsets[3]).opacity(cardsOpacity)
                }
                .padding(.horizontal, 16)

                Spacer(minLength: 40)

                continueButton(disabled: quizAnxiety == nil) { withAnimation { currentStep = 5 } }
                    .padding(.bottom, 50)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Quiz 2: What worries you most?

    private var quizWorstFearScreen: some View {
        onboardingPage {
            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                Text("What worries you most\nabout flying?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.15))
                    .multilineTextAlignment(.center)
                    .opacity(titleOpacity)

                Spacer().frame(height: 40)

                VStack(spacing: 12) {
                    quizOption("Sudden turbulence", subtitle: "Not knowing when it will hit", isSelected: quizWorstFear == "turbulence") { quizWorstFear = "turbulence" }
                        .offset(y: cardOffsets[0]).opacity(cardsOpacity)
                    quizOption("Is the plane safe?", subtitle: "What if something goes wrong", isSelected: quizWorstFear == "safety") { quizWorstFear = "safety" }
                        .offset(y: cardOffsets[1]).opacity(cardsOpacity)
                    quizOption("Feeling trapped", subtitle: "Can't get off if I want to", isSelected: quizWorstFear == "trapped") { quizWorstFear = "trapped" }
                        .offset(y: cardOffsets[2]).opacity(cardsOpacity)
                    quizOption("Losing control", subtitle: "The panic itself scares me", isSelected: quizWorstFear == "control") { quizWorstFear = "control" }
                        .offset(y: cardOffsets[3]).opacity(cardsOpacity)
                }
                .padding(.horizontal, 16)

                Spacer(minLength: 40)

                continueButton(disabled: quizWorstFear == nil) { withAnimation { currentStep = 6 } }
                    .padding(.bottom, 50)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Quiz 3: Has anxiety changed your plans?

    private var quizImpactScreen: some View {
        onboardingPage {
            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                Text("Has flight anxiety ever\nchanged your plans?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.15))
                    .multilineTextAlignment(.center)
                    .opacity(titleOpacity)

                Spacer().frame(height: 40)

                VStack(spacing: 12) {
                    quizOption("Never", subtitle: "I fly without issues", isSelected: quizImpact == "never") { quizImpact = "never" }
                        .offset(y: cardOffsets[0]).opacity(cardsOpacity)
                    quizOption("I've considered it", subtitle: "Thought about canceling a flight", isSelected: quizImpact == "considered") { quizImpact = "considered" }
                        .offset(y: cardOffsets[1]).opacity(cardsOpacity)
                    quizOption("Yes, changed plans", subtitle: "Picked driving over flying", isSelected: quizImpact == "changed") { quizImpact = "changed" }
                        .offset(y: cardOffsets[2]).opacity(cardsOpacity)
                    quizOption("I avoid flying", subtitle: "I haven't flown in years", isSelected: quizImpact == "avoid") { quizImpact = "avoid" }
                        .offset(y: cardOffsets[3]).opacity(cardsOpacity)
                }
                .padding(.horizontal, 16)

                Spacer(minLength: 40)

                continueButton(disabled: quizImpact == nil) { withAnimation { currentStep = 7 } }
                    .padding(.bottom, 50)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Quiz 4: What would help you fly calmer? (multi-select)

    private let helperOptions: [(id: String, icon: String, title: LocalizedStringKey)] = [
        ("forecast", "✈️", "Knowing turbulence in advance"),
        ("intensity", "📊", "Seeing exactly how strong it is"),
        ("breathing", "🫁", "Breathing exercises during bumps"),
        ("alerts", "🔔", "Alerts before turbulence zones"),
        ("planning", "📅", "Planning days ahead"),
        ("understand", "💬", "Understanding what's happening"),
        ("tips", "🧘", "Tips to manage anxiety"),
        ("offline", "📱", "Works offline on the plane"),
    ]

    private var quizHelpScreen: some View {
        onboardingPage {
            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                Text("What would help you\nfly calmer?")
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
                    ForEach(Array(helperOptions.enumerated()), id: \.element.id) { index, item in
                        helperCheckbox(id: item.id, icon: item.icon, title: item.title)
                            .offset(y: index < 4 ? cardOffsets[index] : cardOffsets[min(index - 4, 3)])
                            .opacity(cardsOpacity)
                    }
                }
                .padding(.horizontal, 16)

                Spacer(minLength: 40)

                continueButton(disabled: selectedHelpers.isEmpty) { withAnimation { currentStep = 8 } }
                    .padding(.bottom, 50)
            }
            .padding(.horizontal, 24)
        }
    }

    private func helperCheckbox(id: String, icon: String, title: LocalizedStringKey) -> some View {
        let isSelected = selectedHelpers.contains(id)
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if isSelected { selectedHelpers.remove(id) }
                else { selectedHelpers.insert(id) }
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

    // MARK: - Quiz 5: When is your next flight?

    private var quizNextFlightScreen: some View {
        onboardingPage {
            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                Text("When is your\nnext flight?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.15))
                    .multilineTextAlignment(.center)
                    .opacity(titleOpacity)

                Spacer().frame(height: 12)

                Text("We'll have your forecast ready")
                    .font(.system(size: 15))
                    .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.5))
                    .opacity(subtitleOpacity)

                Spacer().frame(height: 40)

                VStack(spacing: 12) {
                    quizOption("This week", subtitle: "I need to prepare now", isSelected: quizNextFlight == "week") { quizNextFlight = "week" }
                        .offset(y: cardOffsets[0]).opacity(cardsOpacity)
                    quizOption("This month", subtitle: "Time to get ready", isSelected: quizNextFlight == "month") { quizNextFlight = "month" }
                        .offset(y: cardOffsets[1]).opacity(cardsOpacity)
                    quizOption("In a few months", subtitle: "I want to start preparing early", isSelected: quizNextFlight == "months") { quizNextFlight = "months" }
                        .offset(y: cardOffsets[2]).opacity(cardsOpacity)
                    quizOption("Not planned yet", subtitle: "But I want to be ready", isSelected: quizNextFlight == "none") { quizNextFlight = "none" }
                        .offset(y: cardOffsets[3]).opacity(cardsOpacity)
                }
                .padding(.horizontal, 16)

                Spacer(minLength: 40)

                continueButton(disabled: quizNextFlight == nil) { withAnimation { currentStep = 9 } }
                    .padding(.bottom, 50)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Dark Setup Screen

    private let setupSteps: [LocalizedStringKey] = [
        "Analyzing global turbulence data\u{2026}",
        "Setting up real-time alerts\u{2026}",
        "Preparing your personal forecast\u{2026}",
        "Optimizing for your comfort\u{2026}"
    ]

    private let creamColor = Color(red: 0.98, green: 0.96, blue: 0.93)

    private var darkSetupScreen: some View {
        ZStack {
            Color(red: 0.04, green: 0.06, blue: 0.12).ignoresSafeArea()

            GeometryReader { geo in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer().frame(height: 80)

                        Text("Building Your\nCalm Flight Plan")
                            .font(.system(size: isIPad ? 48 : 38, weight: .bold, design: .serif))
                            .foregroundColor(creamColor)
                            .multilineTextAlignment(.center)
                            .scaleEffect(x: 0.85, y: 1.0)

                        Spacer().frame(height: 40)

                        let barWidth = min(geo.size.width - 80, 600)
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.15))
                                .frame(width: barWidth, height: 16)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(creamColor)
                                .frame(width: max(0, barWidth * setupProgress), height: 12)
                                .padding(.leading, 2)
                        }

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
                                Text("Anxious Flyers Worldwide")
                                    .font(.system(size: isIPad ? 40 : 32, weight: .bold, design: .serif))
                                    .foregroundColor(creamColor)
                                    .multilineTextAlignment(.center)
                            }
                            .transition(.opacity.combined(with: .scale))

                            Spacer().frame(height: 24)
                            darkTestimonialsCarousel
                        }

                        Spacer().frame(height: 50)
                    }
                    .frame(maxWidth: isIPad ? 700 : 520)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: geo.size.height)
                }
            }
        }
    }

    private func darkSetupStepRow(text: LocalizedStringKey, isActive: Bool, isCompleted: Bool) -> some View {
        HStack(spacing: 12) {
            if isCompleted {
                Text("\u{2713}").font(.system(size: 16, weight: .bold)).foregroundColor(creamColor.opacity(0.7)).frame(width: 20)
            } else if isActive {
                Text("\u{25C9}").font(.system(size: 16)).foregroundColor(creamColor).frame(width: 20)
            } else {
                Text("\u{25CB}").font(.system(size: 16)).foregroundColor(creamColor.opacity(0.5)).frame(width: 20)
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
                    text: "\"I used to dread every flight. Now I check the forecast and know exactly what to expect.\"",
                    author: "Sarah M.", role: "Nervous Flyer"
                )
                darkTestimonialCard(
                    text: "\"The not-knowing was the worst part. Seeing the forecast before I fly helps me relax.\"",
                    author: "David K.", role: "Frequent Traveler"
                )
                darkTestimonialCard(
                    text: "\"I recommend this to nervous passengers. Knowledge really does replace fear.\"",
                    author: "Capt. James R.", role: "Commercial Pilot"
                )
                darkTestimonialCard(
                    text: "\"My hands used to shake for days before a flight. Now I just check the app and breathe.\"",
                    author: "Emma L.", role: "Anxious Traveler"
                )
            }
            .padding(.horizontal, 24)
        }
    }

    private func darkTestimonialCard(text: LocalizedStringKey, author: String, role: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill").font(.system(size: 12)).foregroundColor(.white)
                }
            }
            Text(text)
                .font(.system(size: 17)).foregroundColor(creamColor).lineSpacing(2)
            Text("— \(author), ").font(.system(size: 14, weight: .medium)).foregroundColor(creamColor.opacity(0.6)) +
            Text(role).font(.system(size: 14, weight: .medium)).foregroundColor(creamColor.opacity(0.6))
        }
        .padding(20)
        .frame(width: isIPad ? 340 : 280)
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
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
                    onComplete()
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
                    .frame(maxWidth: isIPad ? 700 : 520)
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
                .frame(maxWidth: isIPad ? 440 : 340)
                .frame(height: 64)
                .background(disabled ? Color.gray : accent)
                .cornerRadius(32)
                .shadow(color: accent.opacity(0.3), radius: 12, x: 0, y: 4)
        }
        .disabled(disabled)
    }

    private func quizOption(_ title: LocalizedStringKey, subtitle: LocalizedStringKey, isSelected: Bool, action: @escaping () -> Void) -> some View {
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
