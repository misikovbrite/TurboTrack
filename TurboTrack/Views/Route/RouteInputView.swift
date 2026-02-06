import SwiftUI

struct RouteInputView: View {
    @StateObject private var viewModel = RouteViewModel()
    @FocusState private var focusedField: RouteField?

    enum RouteField {
        case departure, arrival
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Map background
                RouteMapView(viewModel: viewModel)
                    .ignoresSafeArea(edges: .bottom)
                    .onTapGesture {
                        focusedField = nil
                    }

                // Floating input card + suggestions
                VStack(spacing: 0) {
                    inputCard
                        .padding(.horizontal)
                        .padding(.top, 8)

                    // Suggestions dropdown
                    if !currentSuggestions.isEmpty {
                        suggestionsView
                            .padding(.horizontal)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    if viewModel.showRoute {
                        summaryCard
                            .padding(.horizontal)
                            .padding(.top, 8)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    Spacer()
                }
                .animation(.easeInOut(duration: 0.2), value: currentSuggestions.count)
            }
            .navigationTitle("Flight Route")
            .navigationBarTitleDisplayMode(.inline)
            .animation(.easeInOut(duration: 0.3), value: viewModel.showRoute)
        }
    }

    private var currentSuggestions: [Airport] {
        switch focusedField {
        case .departure: return viewModel.departureSuggestions
        case .arrival: return viewModel.arrivalSuggestions
        case nil: return []
        }
    }

    // MARK: - Input Card

    private var inputCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                // Route dots
                VStack(spacing: 6) {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    Rectangle()
                        .fill(.secondary.opacity(0.3))
                        .frame(width: 2, height: 20)
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                }

                VStack(spacing: 8) {
                    TextField("City or ICAO — Barcelona, KJFK...", text: $viewModel.departureText)
                        .autocorrectionDisabled()
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .focused($focusedField, equals: .departure)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .arrival }
                        .onChange(of: viewModel.departureText) {
                            viewModel.departureAirport = nil
                            viewModel.updateDepartureSuggestions()
                        }

                    TextField("City or ICAO — London, KLAX...", text: $viewModel.arrivalText)
                        .autocorrectionDisabled()
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .focused($focusedField, equals: .arrival)
                        .submitLabel(.search)
                        .onSubmit {
                            focusedField = nil
                            Task { await viewModel.searchRoute() }
                        }
                        .onChange(of: viewModel.arrivalText) {
                            viewModel.arrivalAirport = nil
                            viewModel.updateArrivalSuggestions()
                        }
                }

                // Search button
                Button {
                    focusedField = nil
                    Task { await viewModel.searchRoute() }
                } label: {
                    Group {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.body)
                        }
                    }
                    .frame(width: 44, height: 44)
                    .background(.blue)
                    .foregroundColor(.white)
                    .clipShape(Circle())
                }
                .disabled(viewModel.isLoading || viewModel.departureText.isEmpty || viewModel.arrivalText.isEmpty)
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if viewModel.showRoute {
                Button(role: .destructive) {
                    viewModel.clearRoute()
                } label: {
                    Label("Clear Route", systemImage: "xmark")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
    }

    // MARK: - Suggestions

    private var suggestionsView: some View {
        VStack(spacing: 0) {
            ForEach(Array(currentSuggestions.prefix(5))) { airport in
                Button {
                    selectSuggestion(airport)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "airplane")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(airport.city)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Text("\(airport.id) — \(airport.name)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)

                if airport.id != currentSuggestions.prefix(5).last?.id {
                    Divider().padding(.leading, 44)
                }
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
    }

    private func selectSuggestion(_ airport: Airport) {
        switch focusedField {
        case .departure:
            viewModel.selectDeparture(airport)
            focusedField = .arrival
        case .arrival:
            viewModel.selectArrival(airport)
            focusedField = nil
        case nil:
            break
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(turbulenceColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: turbulenceIcon)
                    .font(.title3)
                    .foregroundColor(turbulenceColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(routeTitle)
                    .font(.subheadline.bold())
                Text(viewModel.turbulenceSummary)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }

    // MARK: - Helpers

    private var routeTitle: String {
        let dep = viewModel.departureAirport?.icao ?? viewModel.departureText
        let arr = viewModel.arrivalAirport?.icao ?? viewModel.arrivalText
        return "\(dep) → \(arr)"
    }

    private var turbulenceIcon: String {
        if viewModel.routePireps.isEmpty { return "checkmark.circle.fill" }
        let hasSevere = viewModel.routePireps.contains { $0.severity == .severe || $0.severity == .extreme }
        let hasModerate = viewModel.routePireps.contains { $0.severity == .moderate }
        if hasSevere { return "exclamationmark.triangle.fill" }
        if hasModerate { return "exclamationmark.circle.fill" }
        return "info.circle.fill"
    }

    private var turbulenceColor: Color {
        if viewModel.routePireps.isEmpty { return .green }
        let hasSevere = viewModel.routePireps.contains { $0.severity == .severe || $0.severity == .extreme }
        let hasModerate = viewModel.routePireps.contains { $0.severity == .moderate }
        if hasSevere { return .red }
        if hasModerate { return .orange }
        return .yellow
    }
}

#Preview {
    RouteInputView()
}
