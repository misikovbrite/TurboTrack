import SwiftUI
import StoreKit
import UIKit

struct OnboardingView: View {
    var onComplete: () -> Void

    @State private var currentStep = 0

    // Quiz state
    @State private var quizAnswer1: String? // feeling about flying
    @State private var quizAnswer2: String? // what worries most
    @State private var quizAnswer3: String? // how often fly
    @State private var selectedInterests: Set<String> = []

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
    @State private var severityCardsVisible: [Bool] = [false, false, false, false]

    // Setup screen states
    @State private var setupProgress: CGFloat = 0
    @State private var setupStepsCompleted: [Bool] = [false, false, false, false]
    @State private var currentSetupStepIndex: Int = -1
    @State private var showSetupStats = false

    private let totalSteps = 9 // 0-8, step 8 = dark setup → paywall

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isIPad: Bool { horizontalSizeClass == .regular }

    // Theme
    private let accent = Color(red: 0.20, green: 0.50, blue: 0.95)
    private let accentLight = Color(red: 0.40, green: 0.65, blue: 1.0)
    private let darkText = Color(red: 0.1, green: 0.1, blue: 0.15)
    private let subtitleColor = Color(red: 0.45, green: 0.45, blue: 0.5)

    var body: some View {
        ZStack {
            if currentStep != 8 {
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
                case 1: featureRouteScreen
                case 2: featureSeverityScreen
                case 3: featurePirepScreen
                case 4: quiz1Screen
                case 5: quiz2Screen
                case 6: quiz3Screen
                case 7: quiz4Screen
                case 8: darkSetupScreen
                default: EmptyView()
                }
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: currentStep)
        }
        .onChange(of: currentStep) { _ in
            resetAnimations()
            triggerAnimations()
            if currentStep == 2 { startSeverityAnimation() }
            if currentStep == 3 { requestAppRating() }
            if currentStep == 8 { startSetupAnimation() }
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
        severityCardsVisible = [false, false, false, false]
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

    // MARK: - Step 0: Welcome (Empathy)

    private var welcomeScreen: some View {
        onboardingPage {
            VStack(spacing: 0) {
                Spacer(minLength: 20)

                ZStack {
                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .fill(accent.opacity(0.2))
                        .frame(width: 160, height: 160)
                        .blur(radius: 20)
                        .scaleEffect(pulseScale)

                    Image("AppLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 140, height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                        .shadow(color: accent.opacity(0.4), radius: 24, x: 0, y: 12)
                }
                .scaleEffect(iconScale)
                .opacity(iconOpacity)

                Spacer().frame(height: 32)

                VStack(spacing: 4) {
                    Text("Turbulence")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundColor(darkText)
                    Text("Forecast")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundColor(accent)
                }
                .opacity(titleOpacity)

                Spacer().frame(height: 16)

                Text("We know flying can be stressful.\nLet's take the uncertainty away.")
                    .font(.system(size: 17))
                    .foregroundColor(subtitleColor)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .opacity(subtitleOpacity)

                Spacer(minLength: 24)

                continueButton { withAnimation { currentStep = 1 } }
                    .padding(.bottom, 50)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Step 1: Feature — Know Before You Fly (Fear #1: plane will crash)

    private var featureRouteScreen: some View {
        onboardingPage {
            VStack(spacing: 0) {
                Spacer(minLength: 20)

                // Route card demo
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
                    // Severity result preview
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Smooth Flight Expected")
                                .font(.system(size: 15, weight: .bold))
                            Text("3-day forecast")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
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
                    Text("Know Before")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundColor(accent)
                    Text("You Fly")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundColor(darkText)
                }
                .opacity(titleOpacity)

                Spacer().frame(height: 12)

                Text("Check any route and see exactly\nwhat turbulence to expect")
                    .font(.system(size: 17))
                    .foregroundColor(subtitleColor)
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

    // MARK: - Step 2: Feature — Understand Every Bump (Fear #2: don't understand)

    private let severityLevels: [(name: String, icon: String, color: Color, desc: String)] = [
        ("Smooth", "checkmark.seal.fill", .green, "Calm skies, relax and enjoy"),
        ("Light", "cloud.fill", .yellow, "Minor bumps, very common"),
        ("Moderate", "cloud.bolt.fill", .orange, "Noticeable, keep seatbelt on"),
        ("Severe", "exclamationmark.triangle.fill", .red, "Rare, stay firmly buckled"),
    ]

    private var featureSeverityScreen: some View {
        onboardingPage {
            VStack(spacing: 0) {
                Spacer(minLength: 20)

                // Severity cards
                VStack(spacing: 10) {
                    ForEach(0..<4, id: \.self) { i in
                        let level = severityLevels[i]
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(level.color.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: level.icon)
                                    .font(.system(size: 18))
                                    .foregroundColor(level.color)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(level.name)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(darkText)
                                Text(level.desc)
                                    .font(.system(size: 14))
                                    .foregroundColor(subtitleColor)
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(Color.white)
                        .cornerRadius(14)
                        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
                        .opacity(severityCardsVisible[i] ? 1 : 0)
                        .offset(y: severityCardsVisible[i] ? 0 : 20)
                    }
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 32)

                VStack(spacing: 4) {
                    Text("Understand")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundColor(accent)
                    Text("Every Bump")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundColor(darkText)
                }
                .opacity(titleOpacity)

                Spacer().frame(height: 12)

                Text("Clear severity levels so you always\nknow what's normal and what's not")
                    .font(.system(size: 17))
                    .foregroundColor(subtitleColor)
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

    private func startSeverityAnimation() {
        for i in 0..<4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 + Double(i) * 0.15) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    severityCardsVisible[i] = true
                }
            }
        }
    }

    // MARK: - Step 3: Feature — Real Pilot Reports (Fear #4: no control)

    private var featurePirepScreen: some View {
        onboardingPage {
            VStack(spacing: 0) {
                Spacer(minLength: 20)

                // PIREP demo cards
                VStack(spacing: 10) {
                    pirepDemoCard(route: "KJFK → EGLL", level: "FL350", severity: "Light", color: .yellow, time: "12 min ago")
                    pirepDemoCard(route: "KLAX → KORD", level: "FL380", severity: "Moderate", color: .orange, time: "28 min ago")
                    pirepDemoCard(route: "EDDF → LEMD", level: "FL310", severity: "Smooth", color: .green, time: "45 min ago")
                }
                .padding(.horizontal, 24)
                .scaleEffect(iconScale)
                .opacity(iconOpacity)

                Spacer().frame(height: 32)

                VStack(spacing: 4) {
                    Text("Real Pilot")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundColor(accent)
                    Text("Reports")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundColor(darkText)
                }
                .opacity(titleOpacity)

                Spacer().frame(height: 12)

                Text("Live reports from pilots flying\nright now — the same data airlines use")
                    .font(.system(size: 17))
                    .foregroundColor(subtitleColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(subtitleOpacity)

                Spacer().frame(height: 16)

                // Trust badge
                HStack(spacing: 8) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                    Text("Powered by NOAA, FAA & Open-Meteo")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(subtitleColor)
                }
                .opacity(subtitleOpacity)

                Spacer(minLength: 24)

                continueButton { withAnimation { currentStep = 4 } }
                    .padding(.bottom, 50)
            }
            .padding(.horizontal, 24)
        }
    }

    private func pirepDemoCard(route: String, level: String, severity: String, color: Color, time: String) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            VStack(alignment: .leading, spacing: 2) {
                Text(route)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(darkText)
                Text("\(level) · \(severity)")
                    .font(.system(size: 13))
                    .foregroundColor(subtitleColor)
            }
            Spacer()
            Text(time)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - Step 4: Quiz 1 — How do you feel about flying?

    private var quiz1Screen: some View {
        onboardingPage {
            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                Text("How do you feel\nabout flying?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(darkText)
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

                continueButton(disabled: quizAnswer1 == nil) { withAnimation { currentStep = 5 } }
                    .padding(.bottom, 50)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Step 5: Quiz 2 — What worries you most?

    private var quiz2Screen: some View {
        onboardingPage {
            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                Text("What worries you\nmost about turbulence?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(darkText)
                    .multilineTextAlignment(.center)
                    .opacity(titleOpacity)

                Spacer().frame(height: 40)

                VStack(spacing: 12) {
                    quizOption("Is it safe?", subtitle: "I worry something could go wrong with the plane", isSelected: quizAnswer2 == "safety") { quizAnswer2 = "safety" }
                        .offset(y: cardOffsets[0]).opacity(cardsOpacity)
                    quizOption("Not knowing when", subtitle: "The sudden, unexpected bumps scare me most", isSelected: quizAnswer2 == "surprise") { quizAnswer2 = "surprise" }
                        .offset(y: cardOffsets[1]).opacity(cardsOpacity)
                    quizOption("The physical feeling", subtitle: "Dropping sensations make me panic", isSelected: quizAnswer2 == "sensation") { quizAnswer2 = "sensation" }
                        .offset(y: cardOffsets[2]).opacity(cardsOpacity)
                    quizOption("No control", subtitle: "I can't do anything about it and that's scary", isSelected: quizAnswer2 == "control") { quizAnswer2 = "control" }
                        .offset(y: cardOffsets[3]).opacity(cardsOpacity)
                }
                .padding(.horizontal, 16)

                Spacer(minLength: 40)

                continueButton(disabled: quizAnswer2 == nil) { withAnimation { currentStep = 6 } }
                    .padding(.bottom, 50)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Step 6: Quiz 3 — How often do you fly?

    private var quiz3Screen: some View {
        onboardingPage {
            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                Text("How often\ndo you fly?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(darkText)
                    .multilineTextAlignment(.center)
                    .opacity(titleOpacity)

                Spacer().frame(height: 40)

                VStack(spacing: 12) {
                    quizOption("Rarely", subtitle: "Once a year or less", isSelected: quizAnswer3 == "rarely") { quizAnswer3 = "rarely" }
                        .offset(y: cardOffsets[0]).opacity(cardsOpacity)
                    quizOption("A few times a year", subtitle: "Holidays and occasional trips", isSelected: quizAnswer3 == "few") { quizAnswer3 = "few" }
                        .offset(y: cardOffsets[1]).opacity(cardsOpacity)
                    quizOption("Monthly", subtitle: "Regular business or personal travel", isSelected: quizAnswer3 == "monthly") { quizAnswer3 = "monthly" }
                        .offset(y: cardOffsets[2]).opacity(cardsOpacity)
                    quizOption("Weekly", subtitle: "I'm always in the air", isSelected: quizAnswer3 == "weekly") { quizAnswer3 = "weekly" }
                        .offset(y: cardOffsets[3]).opacity(cardsOpacity)
                }
                .padding(.horizontal, 16)

                Spacer(minLength: 40)

                continueButton(disabled: quizAnswer3 == nil) { withAnimation { currentStep = 7 } }
                    .padding(.bottom, 50)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Step 7: Quiz 4 — What would help you most? (multi-select)

    private let interestOptions: [(id: String, icon: String, title: String)] = [
        ("forecast", "✈️", "Route turbulence forecast"),
        ("levels", "📊", "Flight level breakdown"),
        ("map", "🗺️", "Real-time turbulence map"),
        ("notifications", "🔔", "Pre-flight reminders"),
        ("multiday", "📅", "Up to 14-day forecasts"),
        ("tips", "🧘", "Calming tips for nervous flyers"),
    ]

    private var quiz4Screen: some View {
        onboardingPage {
            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                Text("What would\nhelp you most?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(darkText)
                    .multilineTextAlignment(.center)
                    .opacity(titleOpacity)

                Spacer().frame(height: 12)

                Text("Select all that apply")
                    .font(.system(size: 15))
                    .foregroundColor(subtitleColor)
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

                continueButton(disabled: selectedInterests.isEmpty) { withAnimation { currentStep = 8 } }
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

    // MARK: - Step 8: Dark Setup Screen

    private let setupSteps = [
        "Loading atmospheric models...",
        "Calibrating turbulence algorithms...",
        "Connecting to weather stations...",
        "Personalizing your experience...",
    ]

    private let creamColor = Color(red: 0.98, green: 0.96, blue: 0.93)

    private var darkSetupScreen: some View {
        ZStack {
            Color(red: 0.04, green: 0.06, blue: 0.12).ignoresSafeArea()

            GeometryReader { geo in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer().frame(height: 80)

                        Text("Preparing Your\nForecast Engine")
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
                                Text("Travelers & Pilots")
                                    .font(.system(size: isIPad ? 40 : 32, weight: .bold, design: .serif))
                                    .foregroundColor(creamColor)
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
                    text: "Knowing what to expect makes turbulence so much less scary.",
                    author: "Emma L.", role: "Anxious Flyer"
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

    private func quizOption(_ title: String, subtitle: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(darkText)
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(subtitleColor)
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
