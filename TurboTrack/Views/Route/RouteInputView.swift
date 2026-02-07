import SwiftUI

struct RouteInputView: View {
    @StateObject private var viewModel = RouteViewModel()
    @FocusState private var focusedField: RouteField?

    enum RouteField { case departure, arrival }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                    .onTapGesture { focusedField = nil }

                VStack(spacing: 0) {
                    Spacer()

                    // Header
                    VStack(spacing: 10) {
                        Image(systemName: "airplane")
                            .font(.system(size: 44))
                            .foregroundStyle(.blue)
                        Text("Where are you flying?")
                            .font(.title3.bold())
                        Text("Check turbulence forecast for your route")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 28)

                    // Input card
                    inputCard
                        .padding(.horizontal, 20)

                    // Suggestions
                    if !currentSuggestions.isEmpty {
                        suggestionsView
                            .padding(.horizontal, 20)
                            .padding(.top, 4)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    Spacer()
                    Spacer()
                }
                .animation(.easeInOut(duration: 0.2), value: currentSuggestions.count)
            }
            .navigationTitle("Turbulence Forecast")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $viewModel.showRoute) {
                ForecastResultView(viewModel: viewModel)
            }
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
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                // Route dots
                VStack(spacing: 6) {
                    Circle().fill(.green).frame(width: 8, height: 8)
                    Rectangle().fill(.secondary.opacity(0.3)).frame(width: 2, height: 20)
                    Circle().fill(.red).frame(width: 8, height: 8)
                }

                VStack(spacing: 8) {
                    TextField("From — New York, KJFK...", text: $viewModel.departureText)
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

                    TextField("To — London, EGLL...", text: $viewModel.arrivalText)
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
            }

            // Search button
            Button {
                focusedField = nil
                Task { await viewModel.searchRoute() }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "paperplane.fill")
                        Text("Check Turbulence")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(canSearch ? .blue : .blue.opacity(0.4))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!canSearch)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
    }

    private var canSearch: Bool {
        !viewModel.isLoading && !viewModel.departureText.isEmpty && !viewModel.arrivalText.isEmpty
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
}

#Preview {
    RouteInputView()
}
