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

                // Floating input card
                VStack(spacing: 0) {
                    inputCard
                        .padding(.horizontal)
                        .padding(.top, 8)

                    if viewModel.showRoute {
                        summaryCard
                            .padding(.horizontal)
                            .padding(.top, 8)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    Spacer()
                }
            }
            .navigationTitle("Flight Route")
            .navigationBarTitleDisplayMode(.inline)
            .animation(.easeInOut(duration: 0.3), value: viewModel.showRoute)
        }
    }

    // MARK: - Input Card

    private var inputCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                // Departure
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
                    TextField("Departure — KJFK", text: $viewModel.departureCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .focused($focusedField, equals: .departure)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .arrival }

                    TextField("Arrival — KLAX", text: $viewModel.arrivalCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(.system(.body, design: .monospaced))
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
                .disabled(viewModel.isLoading || viewModel.departureCode.isEmpty || viewModel.arrivalCode.isEmpty)
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

    // MARK: - Summary Card

    private var summaryCard: some View {
        HStack(spacing: 12) {
            // Icon
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
        let dep = viewModel.departureCode.uppercased()
        let arr = viewModel.arrivalCode.uppercased()
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
