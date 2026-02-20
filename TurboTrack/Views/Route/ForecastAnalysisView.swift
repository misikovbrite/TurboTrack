import SwiftUI
import Combine

struct ForecastAnalysisView: View {
    @ObservedObject var viewModel: RouteViewModel
    @State private var elapsedSeconds: Int = 0
    @State private var timer: AnyCancellable?

    private let totalDuration = 75 // seconds
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
            // Dark gradient background
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.05, blue: 0.15),
                         Color(red: 0.08, green: 0.12, blue: 0.25)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 40)

                // Airplane icon
                Image(systemName: "airplane")
                    .font(.system(size: 50))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(-45))
                    .shadow(color: .blue.opacity(0.5), radius: 20)

                // Route text
                Text(viewModel.routeTitle)
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .padding(.top, 16)

                Text("\(viewModel.forecastDays)-day forecast")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.top, 4)

                Spacer().frame(height: 36)

                // Progress bar
                VStack(spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.white.opacity(0.1))
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

                Spacer().frame(height: 32)

                // Analysis steps
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
                            .padding(.vertical, 8)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                }
                .padding(.horizontal, 32)
                .animation(.easeOut(duration: 0.4), value: currentPhase)

                Spacer()

                // Bottom message
                VStack(spacing: 8) {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.3))

                    Text("This may take a minute or two.\nFeel free to do something else — we'll have your report ready.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
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
        // Calculate already elapsed time (handles backgrounding)
        if let start = viewModel.analysisStartTime {
            elapsedSeconds = Int(Date().timeIntervalSince(start))
        }

        // Check if already done
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
