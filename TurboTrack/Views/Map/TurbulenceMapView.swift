import SwiftUI
import MapKit

struct TurbulenceMapView: View {
    @StateObject private var viewModel = MapViewModel()
    @EnvironmentObject var subscriptionService: SubscriptionService
    @State private var showFilters = false
    @State private var showSettings = false
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $viewModel.cameraPosition) {
                    // PIREP markers
                    ForEach(viewModel.filteredPireps) { report in
                        if let coord = report.coordinate {
                            Annotation(
                                report.severity.displayName,
                                coordinate: coord,
                                anchor: .center
                            ) {
                                TurbulenceAnnotation(severity: report.severity)
                                    .onTapGesture {
                                        viewModel.selectReport(report)
                                    }
                            }
                        }
                    }

                    // SIGMET/AIRMET polygons
                    ForEach(viewModel.filteredSigmets) { sigmet in
                        if sigmet.polygonCoordinates.count >= 3 {
                            MapPolygon(coordinates: sigmet.polygonCoordinates)
                                .foregroundStyle(
                                    sigmet.turbulenceSeverity.color.opacity(0.2)
                                )
                                .stroke(
                                    sigmet.turbulenceSeverity.color,
                                    lineWidth: 2
                                )
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .mapControls {
                    MapCompass()
                    MapScaleView()
                    MapUserLocationButton()
                }

                VStack {
                    // Premium banner overlay
                    if !subscriptionService.isPro {
                        PremiumBannerView(context: .map) {
                            showPaywall = true
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }

                    Spacer()

                    // Loading overlay
                    if viewModel.isLoading {
                        HStack {
                            ProgressView()
                                .tint(.white)
                            Text("Loading...")
                                .foregroundColor(.white)
                                .font(.caption)
                        }
                        .padding(8)
                        .background(.black.opacity(0.6))
                        .clipShape(Capsule())
                        .padding(.bottom, 8)
                    }

                    // Legend
                    HStack {
                        legendItem(severity: .light)
                        legendItem(severity: .moderate)
                        legendItem(severity: .severe)
                        legendItem(severity: .extreme)
                    }
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
            .navigationTitle("Turbulence Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showFilters.toggle()
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(viewModel.altitudeFilterEnabled ? .blue : .primary)
                    }

                    Button {
                        Task { await viewModel.loadData() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }

                    if !subscriptionService.isPro {
                        Button { showPaywall = true } label: {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.orange)
                        }
                    }

                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showDetail) {
                if let report = viewModel.selectedReport {
                    ReportDetailSheet(report: report)
                        .presentationDetents([.medium, .large])
                }
            }
            .sheet(isPresented: $showFilters) {
                altitudeFilterSheet
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(subscriptionService)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(source: "map") {
                    showPaywall = false
                }
                .environmentObject(subscriptionService)
            }
            .task {
                await viewModel.loadData()
                viewModel.startAutoRefresh()
            }
            .onDisappear {
                viewModel.stopAutoRefresh()
            }
        }
    }

    private func legendItem(severity: TurbulenceSeverity) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(severity.color)
                .frame(width: 10, height: 10)
            Text(severity.displayName)
                .font(.caption2)
        }
    }

    private var altitudeFilterSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Toggle("Filter by Altitude", isOn: $viewModel.altitudeFilterEnabled)

                if viewModel.altitudeFilterEnabled {
                    VStack(alignment: .leading) {
                        Text("Altitude Range")
                            .font(.headline)

                        HStack {
                            Text(Int(viewModel.altitudeFilterLow).flightLevel)
                                .font(.caption)
                                .monospacedDigit()
                            Spacer()
                            Text(Int(viewModel.altitudeFilterHigh).flightLevel)
                                .font(.caption)
                                .monospacedDigit()
                        }

                        HStack {
                            Slider(
                                value: $viewModel.altitudeFilterLow,
                                in: 0...45000,
                                step: 1000
                            )
                        }

                        HStack {
                            Slider(
                                value: $viewModel.altitudeFilterHigh,
                                in: 0...45000,
                                step: 1000
                            )
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Altitude Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showFilters = false }
                }
            }
        }
    }
}

#Preview {
    TurbulenceMapView()
        .environmentObject(SubscriptionService())
}
