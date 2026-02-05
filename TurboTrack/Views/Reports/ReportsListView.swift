import SwiftUI

struct ReportsListView: View {
    @StateObject private var viewModel = ReportsViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Severity filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterChip(title: "All", severity: nil)
                        ForEach(TurbulenceSeverity.allCases.filter { $0 != .none }) { severity in
                            filterChip(title: severity.displayName, severity: severity)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color(.systemGroupedBackground))

                if viewModel.isLoading && viewModel.reports.isEmpty {
                    Spacer()
                    ProgressView("Loading reports...")
                    Spacer()
                } else if let error = viewModel.errorMessage {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button("Retry") {
                            Task { await viewModel.loadReports() }
                        }
                    }
                    Spacer()
                } else if viewModel.filteredReports.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "airplane.circle")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No reports found")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List(viewModel.filteredReports) { report in
                        ReportRow(report: report)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("PIREP Reports")
            .searchable(text: $viewModel.searchText, prompt: "Search by airport or aircraft")
            .refreshable {
                await viewModel.loadReports()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text("\(viewModel.filteredReports.count) reports")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .task {
                await viewModel.loadReports()
            }
        }
    }

    private func filterChip(title: String, severity: TurbulenceSeverity?) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectedSeverityFilter = severity
            }
        } label: {
            Text(title)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    viewModel.selectedSeverityFilter == severity
                    ? (severity?.color ?? Color.blue)
                    : Color(.systemGray5)
                )
                .foregroundColor(
                    viewModel.selectedSeverityFilter == severity
                    ? .white : .primary
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ReportsListView()
}
