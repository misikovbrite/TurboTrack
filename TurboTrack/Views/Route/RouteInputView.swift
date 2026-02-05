import SwiftUI

struct RouteInputView: View {
    @StateObject private var viewModel = RouteViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Input section
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("FROM")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                            TextField("KJFK", text: $viewModel.departureCode)
                                .textFieldStyle(.roundedBorder)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .font(.system(.body, design: .monospaced))
                        }

                        Image(systemName: "arrow.right")
                            .foregroundColor(.secondary)
                            .padding(.top, 16)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("TO")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                            TextField("KLAX", text: $viewModel.arrivalCode)
                                .textFieldStyle(.roundedBorder)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .font(.system(.body, design: .monospaced))
                        }
                    }

                    HStack(spacing: 12) {
                        Button {
                            Task { await viewModel.searchRoute() }
                        } label: {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "magnifyingglass")
                                }
                                Text("Check Route")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(.blue)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .disabled(viewModel.isLoading)

                        if viewModel.showRoute {
                            Button {
                                viewModel.clearRoute()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    // Turbulence summary
                    if viewModel.showRoute {
                        HStack {
                            Image(systemName: turbulenceIcon)
                                .foregroundColor(turbulenceColor)
                            Text(viewModel.turbulenceSummary)
                                .font(.subheadline)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(turbulenceColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding()
                .background(Color(.systemGroupedBackground))

                // Route map
                RouteMapView(viewModel: viewModel)
            }
            .navigationTitle("Flight Route")
            .navigationBarTitleDisplayMode(.inline)
        }
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
