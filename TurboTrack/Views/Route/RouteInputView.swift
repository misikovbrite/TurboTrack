import SwiftUI

struct RouteInputView: View {
    @StateObject private var viewModel = RouteViewModel()
    @EnvironmentObject var subscriptionService: SubscriptionService
    @State private var showPaywall = false
    @State private var showFAQ = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                    .onTapGesture { dismissKeyboard() }

                ScrollView {
                    VStack(spacing: 0) {
                        // Premium banner
                        if !subscriptionService.isPro {
                            PremiumBannerView(context: .forecast) {
                                showPaywall = true
                            }
                            .frame(maxWidth: 560)
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            .padding(.bottom, 8)
                        }

                        Spacer().frame(height: 12)

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

                        // Route card (onboarding-style)
                        routeCard
                            .frame(maxWidth: 560)
                            .padding(.horizontal, 20)

                        // Forecast period
                        forecastPeriodSection
                            .frame(maxWidth: 560)
                            .padding(.horizontal, 20)
                            .padding(.top, 12)

                        // Search button
                        searchButton
                            .frame(maxWidth: 560)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(maxWidth: 560)
                                .padding(.horizontal, 24)
                                .padding(.top, 8)
                        }

                        // FAQ link
                        Button {
                            showFAQ = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "questionmark.circle")
                                Text("What is turbulence?")
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                        .padding(.top, 24)

                        // Forecast history
                        if !ForecastHistory.shared.entries.isEmpty {
                            forecastHistorySection
                                .frame(maxWidth: 560)
                                .padding(.horizontal, 20)
                                .padding(.top, 24)
                        }

                        Spacer().frame(height: 40)
                    }
                }
            }
            .navigationTitle("Turbulence Forecast")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
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
            .navigationDestination(isPresented: $viewModel.showRoute) {
                ForecastResultView(viewModel: viewModel)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(source: "forecast") {
                    showPaywall = false
                }
                .environmentObject(subscriptionService)
            }
            .sheet(isPresented: $showFAQ) {
                TurbulenceFAQView()
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(subscriptionService)
            }
        }
    }

    // MARK: - Route Card

    private var routeCard: some View {
        VStack(spacing: 0) {
            // Departure
            routeField(
                label: "FROM",
                placeholder: "City or airport code",
                text: $viewModel.departureText,
                selectedAirport: viewModel.departureAirport,
                suggestions: viewModel.departureSuggestions,
                dotColor: .green,
                onClear: {
                    viewModel.departureAirport = nil
                    viewModel.departureText = ""
                    viewModel.departureSuggestions = []
                },
                onSelect: { airport in
                    viewModel.selectDeparture(airport)
                },
                onTextChange: {
                    viewModel.departureAirport = nil
                    viewModel.updateDepartureSuggestions()
                }
            )

            // Divider with swap
            HStack {
                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(height: 1)
                Button {
                    let tmpText = viewModel.departureText
                    let tmpAirport = viewModel.departureAirport
                    viewModel.departureText = viewModel.arrivalText
                    viewModel.departureAirport = viewModel.arrivalAirport
                    viewModel.arrivalText = tmpText
                    viewModel.arrivalAirport = tmpAirport
                    viewModel.departureSuggestions = []
                    viewModel.arrivalSuggestions = []
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                        .frame(width: 36, height: 36)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                }
                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(height: 1)
            }
            .padding(.horizontal, 16)

            // Arrival
            routeField(
                label: "TO",
                placeholder: "City or airport code",
                text: $viewModel.arrivalText,
                selectedAirport: viewModel.arrivalAirport,
                suggestions: viewModel.arrivalSuggestions,
                dotColor: .red,
                onClear: {
                    viewModel.arrivalAirport = nil
                    viewModel.arrivalText = ""
                    viewModel.arrivalSuggestions = []
                },
                onSelect: { airport in
                    viewModel.selectArrival(airport)
                },
                onTextChange: {
                    viewModel.arrivalAirport = nil
                    viewModel.updateArrivalSuggestions()
                }
            )
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
    }

    private func routeField(
        label: String,
        placeholder: String,
        text: Binding<String>,
        selectedAirport: Airport?,
        suggestions: [Airport],
        dotColor: Color,
        onClear: @escaping () -> Void,
        onSelect: @escaping (Airport) -> Void,
        onTextChange: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Circle()
                    .fill(dotColor)
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(1)

                    if let airport = selectedAirport {
                        HStack(spacing: 6) {
                            Text(airport.displayName)
                                .font(.system(size: 17, weight: .semibold))
                            Text("·")
                                .foregroundColor(.secondary)
                            Text(airport.name)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    } else {
                        TextField(placeholder, text: text)
                            .font(.system(size: 17))
                            .autocorrectionDisabled()
                            .onChange(of: text.wrappedValue) { _ in
                                onTextChange()
                            }
                    }
                }

                Spacer()

                if selectedAirport != nil {
                    Button(action: onClear) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color(.systemGray3))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            // Suggestions dropdown
            if !suggestions.isEmpty && selectedAirport == nil {
                VStack(spacing: 0) {
                    ForEach(Array(suggestions.prefix(5))) { airport in
                        Button {
                            onSelect(airport)
                            dismissKeyboard()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "airplane.departure")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                    .frame(width: 20)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(airport.displayName)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.primary)
                                    Text(airport.name)
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }

                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                        }

                        if airport.id != suggestions.prefix(5).last?.id {
                            Divider().padding(.leading, 46)
                        }
                    }
                }
                .background(Color(.tertiarySystemGroupedBackground))
            }
        }
    }

    // MARK: - Forecast Period

    private var forecastPeriodSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Forecast Period")
                .font(.subheadline.bold())
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                ForEach(RouteViewModel.availableForecastDays, id: \.self) { days in
                    Button {
                        viewModel.forecastDays = days
                    } label: {
                        Text("\(days)-day")
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(viewModel.forecastDays == days ? Color.blue : Color(.tertiarySystemFill))
                            .foregroundColor(viewModel.forecastDays == days ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
        .padding(16)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }

    // MARK: - Search Button

    private var searchButton: some View {
        Button {
            dismissKeyboard()
            if subscriptionService.isPro {
                Task { await viewModel.searchRoute() }
            } else {
                showPaywall = true
            }
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
            .frame(height: 52)
            .background(canSearch ? .blue : .blue.opacity(0.4))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!canSearch)
    }

    // MARK: - Forecast History

    private var forecastHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Recent Forecasts", systemImage: "clock.arrow.circlepath")
                    .font(.subheadline.bold())
                    .foregroundColor(.secondary)
                Spacer()
            }

            ForEach(ForecastHistory.shared.entries) { entry in
                Button {
                    loadHistoryEntry(entry)
                } label: {
                    HStack(spacing: 12) {
                        VStack(spacing: 4) {
                            Circle().fill(.green).frame(width: 8, height: 8)
                            Rectangle().fill(.secondary.opacity(0.3)).frame(width: 1.5, height: 12)
                            Circle().fill(.red).frame(width: 8, height: 8)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(entry.departureICAO) → \(entry.arrivalICAO)")
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)
                            Text("\(entry.forecastDays)-day · \(entry.severity) · \(entry.dateFormatted)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Circle()
                            .fill(entry.severityColor)
                            .frame(width: 10, height: 10)

                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(.background)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(16)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func loadHistoryEntry(_ entry: ForecastHistoryEntry) {
        viewModel.departureText = entry.departureICAO
        viewModel.arrivalText = entry.arrivalICAO
        viewModel.departureAirport = Airport.find(icao: entry.departureICAO)
        viewModel.arrivalAirport = Airport.find(icao: entry.arrivalICAO)
        viewModel.forecastDays = entry.forecastDays
        if let dep = viewModel.departureAirport {
            viewModel.departureText = dep.displayName
        }
        if let arr = viewModel.arrivalAirport {
            viewModel.arrivalText = arr.displayName
        }
        if subscriptionService.isPro {
            Task { await viewModel.searchRoute() }
        } else {
            showPaywall = true
        }
    }

    private var canSearch: Bool {
        !viewModel.isLoading && !viewModel.departureText.isEmpty && !viewModel.arrivalText.isEmpty
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    RouteInputView()
        .environmentObject(SubscriptionService())
}
