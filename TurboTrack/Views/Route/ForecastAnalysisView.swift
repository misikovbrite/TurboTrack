import SwiftUI
import AVFoundation
import Combine

// MARK: - Looping Video Background

struct VideoBackgroundView: UIViewRepresentable {
    let videoName: String

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        guard let path = Bundle.main.path(forResource: videoName, ofType: "mp4") else { return view }
        let url = URL(fileURLWithPath: path)
        let player = AVPlayer(url: url)
        player.isMuted = true
        player.actionAtItemEnd = .none

        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(playerLayer)

        // Loop
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }

        player.play()
        context.coordinator.player = player
        context.coordinator.playerLayer = playerLayer

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.playerLayer?.frame = uiView.bounds
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator {
        var player: AVPlayer?
        var playerLayer: AVPlayerLayer?
    }
}

// MARK: - Animated Airplane

struct FlyingAirplaneView: View {
    @State private var flyOffset: CGFloat = -150
    @State private var flyVertical: CGFloat = 0
    @State private var rotation: Double = 0

    var body: some View {
        Image(systemName: "airplane")
            .font(.system(size: 40, weight: .light))
            .foregroundStyle(.white)
            .shadow(color: .white.opacity(0.4), radius: 12)
            .rotationEffect(.degrees(rotation))
            .offset(x: flyOffset, y: flyVertical)
            .onAppear {
                animateFlight()
            }
    }

    private func animateFlight() {
        // Fly right
        withAnimation(.easeInOut(duration: 4)) {
            flyOffset = 150
            flyVertical = -20
            rotation = -10
        }

        // Fly back left
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.2) {
            withAnimation(.easeInOut(duration: 4)) {
                flyOffset = -120
                flyVertical = 15
                rotation = -30
            }
        }

        // Return center and repeat
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.4) {
            withAnimation(.easeInOut(duration: 3)) {
                flyOffset = 0
                flyVertical = 0
                rotation = -15
            }
        }

        // Loop
        DispatchQueue.main.asyncAfter(deadline: .now() + 12) {
            animateFlight()
        }
    }
}

// MARK: - Main View

struct ForecastAnalysisView: View {
    @ObservedObject var viewModel: RouteViewModel
    @State private var elapsedSeconds: Int = 0
    @State private var timer: AnyCancellable?

    private let totalDuration = 75
    private let steps: [(icon: String, text: String, startAt: Int)] = [
        ("antenna.radiowaves.left.and.right", "Connecting to aviation data sources...", 0),
        ("airplane", "Analyzing flight route & altitude...", 10),
        ("barometer", "Checking atmospheric pressure levels...", 20),
        ("person.wave.2", "Fetching live pilot reports...", 32),
        ("wind", "Processing wind shear data...", 44),
        ("chart.bar.doc.horizontal", "Generating your forecast...", 56),
        ("checkmark.shield", "Finalizing analysis...", 66),
    ]

    private var progress: Double {
        min(Double(elapsedSeconds) / Double(totalDuration), 1.0)
    }

    private var timeRemaining: Int {
        max(totalDuration - elapsedSeconds, 0)
    }

    private var timeRemainingText: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var currentPhase: Int {
        var phase = 0
        for (index, step) in steps.enumerated() {
            if elapsedSeconds >= step.startAt {
                phase = index
            }
        }
        return phase
    }

    var body: some View {
        ZStack {
            // Video background
            VideoBackgroundView(videoName: "weather_bg")
                .ignoresSafeArea()

            // Dark overlay for readability
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: Top — Big message to user
                VStack(spacing: 12) {
                    Text("Analyzing Your Route")
                        .font(.title.bold())
                        .foregroundColor(.white)

                    Text("This takes about a minute.\nYou can minimize the app — we'll have\nyour report ready when you return.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.top, 32)

                Spacer().frame(height: 24)

                // MARK: Animated airplane
                FlyingAirplaneView()
                    .frame(height: 80)

                // Route info
                Text(viewModel.routeTitle)
                    .font(.title3.bold())
                    .foregroundColor(.white)
                    .padding(.top, 8)

                Text("\(viewModel.forecastDays)-day forecast")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.top, 2)

                Spacer().frame(height: 24)

                // MARK: Progress bar
                VStack(spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.white.opacity(0.15))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * progress, height: 8)
                                .animation(.linear(duration: 1), value: progress)
                        }
                    }
                    .frame(height: 8)

                    HStack {
                        Text("Analyzing route...")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                        Spacer()
                        Text(timeRemainingText)
                            .font(.caption.monospacedDigit())
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 32)

                Spacer().frame(height: 20)

                // MARK: Analysis steps
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        if elapsedSeconds >= step.startAt {
                            HStack(spacing: 14) {
                                let isComplete = index < currentPhase ||
                                    (index == steps.count - 1 && elapsedSeconds >= totalDuration)

                                ZStack {
                                    if isComplete {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.green)
                                    } else {
                                        ProgressView()
                                            .tint(.cyan)
                                            .scaleEffect(0.8)
                                            .frame(width: 20, height: 20)
                                    }
                                }
                                .frame(width: 24)

                                Image(systemName: step.icon)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.6))
                                    .frame(width: 20)

                                Text(step.text)
                                    .font(.subheadline)
                                    .foregroundColor(isComplete ? .white.opacity(0.5) : .white)
                            }
                            .padding(.vertical, 6)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                }
                .padding(.horizontal, 32)
                .animation(.easeOut(duration: 0.4), value: currentPhase)

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    stopTimer()
                    viewModel.isAnalyzing = false
                    viewModel.dataReady = false
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Cancel")
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
    }

    private func startTimer() {
        if let start = viewModel.analysisStartTime {
            elapsedSeconds = Int(Date().timeIntervalSince(start))
        }

        if elapsedSeconds >= totalDuration && viewModel.dataReady {
            viewModel.completeAnalysis()
            return
        }

        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if let start = viewModel.analysisStartTime {
                    elapsedSeconds = Int(Date().timeIntervalSince(start))
                } else {
                    elapsedSeconds += 1
                }

                viewModel.analysisPhase = currentPhase

                if elapsedSeconds >= totalDuration && viewModel.dataReady {
                    stopTimer()
                    viewModel.completeAnalysis()
                }
            }
    }

    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }
}

#Preview {
    NavigationStack {
        ForecastAnalysisView(viewModel: RouteViewModel())
    }
}
