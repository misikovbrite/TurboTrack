import SwiftUI
import AVKit
import Combine

// MARK: - Looping Video Background

struct VideoBackgroundView: UIViewRepresentable {
    let videoName: String

    func makeUIView(context: Context) -> UIView {
        let view = LoopingVideoView(videoName: videoName)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

class LoopingVideoView: UIView {
    private var player: AVQueuePlayer?
    private var playerLayer: AVPlayerLayer?
    private var looper: AVPlayerLooper?

    init(videoName: String) {
        super.init(frame: .zero)
        backgroundColor = .clear

        guard let url = Bundle.main.url(forResource: videoName, withExtension: "mp4") else {
            print("[Video] Could not find \(videoName).mp4 in bundle")
            return
        }

        let item = AVPlayerItem(url: url)
        let queuePlayer = AVQueuePlayer(items: [item])
        queuePlayer.isMuted = true

        looper = AVPlayerLooper(player: queuePlayer, templateItem: item)

        let layer = AVPlayerLayer(player: queuePlayer)
        layer.videoGravity = .resizeAspectFill
        self.layer.addSublayer(layer)

        self.player = queuePlayer
        self.playerLayer = layer

        queuePlayer.play()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }
}

// MARK: - Animated Airplane (gentle hover)

struct FlyingAirplaneView: View {
    @State private var hoverY: CGFloat = 0
    @State private var hoverRotation: Double = 0

    var body: some View {
        Image(systemName: "airplane")
            .font(.system(size: 48, weight: .light))
            .foregroundStyle(.white)
            .shadow(color: .white.opacity(0.5), radius: 16)
            .rotationEffect(.degrees(-45 + hoverRotation))
            .offset(y: hoverY)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                    hoverY = -12
                    hoverRotation = 3
                }
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
            // Video background with fallback
            Color.black.ignoresSafeArea()

            VideoBackgroundView(videoName: "weather_bg")
                .ignoresSafeArea()

            // Dark overlay
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: Top — Prominent message
                VStack(spacing: 14) {
                    Text("Analyzing Your Route")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text("This takes about a minute.\nYou can minimize the app —\nwe'll have your report ready\nwhen you come back.")
                        .font(.system(size: 17))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                }
                .padding(.top, 28)

                Spacer().frame(height: 28)

                // MARK: Airplane
                FlyingAirplaneView()
                    .frame(height: 70)

                // Route
                Text(viewModel.routeTitle)
                    .font(.title3.bold())
                    .foregroundColor(.white)
                    .padding(.top, 10)

                Text(viewModel.isConnecting ? "\(viewModel.forecastDays)-day forecast · 2 legs" : "\(viewModel.forecastDays)-day forecast")
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

                // MARK: Steps
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
