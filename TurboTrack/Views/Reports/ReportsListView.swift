import SwiftUI

struct ReportsListView: View {
    @StateObject private var viewModel = ReportsViewModel()
    @EnvironmentObject var subscriptionService: SubscriptionService
    @State private var showSettings = false
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Premium banner
                if !subscriptionService.isPro {
                    PremiumBannerView(context: .reports) {
                        showPaywall = true
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }

                // Severity filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterChip(title: "All", severity: nil, icon: "list.bullet")
                        ForEach(TurbulenceSeverity.allCases.filter { $0 != .none }) { severity in
                            filterChip(title: severity.displayName, severity: severity, icon: nil)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }

                // Stats bar
                if !viewModel.reports.isEmpty {
                    statsBar
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }

                Divider()

                if viewModel.isLoading && viewModel.reports.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading PIREPs...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else if let error = viewModel.errorMessage, viewModel.reports.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button {
                            Task { await viewModel.loadReports() }
                        } label: {
                            Label("Retry", systemImage: "arrow.clockwise")
                                .font(.subheadline.bold())
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(.blue)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                    .padding()
                    Spacer()
                } else if viewModel.filteredReports.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("No reports match your filters")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        if viewModel.selectedSeverityFilter != nil || !viewModel.searchText.isEmpty {
                            Button("Clear Filters") {
                                viewModel.clearFilters()
                            }
                            .font(.subheadline)
                        }
                    }
                    Spacer()
                } else {
                    List(viewModel.filteredReports) { report in
                        ReportRow(report: report)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Pilot Reports")
            .searchable(text: $viewModel.searchText, prompt: "Search airport, aircraft, raw text...")
            .refreshable {
                await viewModel.loadReports()
            }
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
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(subscriptionService)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(source: "reports") {
                    showPaywall = false
                }
                .environmentObject(subscriptionService)
            }
            .task {
                await viewModel.loadReports()
            }
        }
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        HStack(spacing: 12) {
            statBadge(
                count: viewModel.filteredReports.count,
                label: "Total",
                color: .blue
            )

            let severeCount = viewModel.filteredReports.filter {
                $0.severity == .severe || $0.severity == .extreme
            }.count
            if severeCount > 0 {
                statBadge(count: severeCount, label: "Severe", color: .red)
            }

            let modCount = viewModel.filteredReports.filter { $0.severity == .moderate }.count
            if modCount > 0 {
                statBadge(count: modCount, label: "Moderate", color: .orange)
            }

            Spacer()
        }
    }

    private func statBadge(count: Int, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text("\(count)")
                .font(.caption.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }

    // MARK: - Filter Chip

    private func filterChip(title: String, severity: TurbulenceSeverity?, icon: String?) -> some View {
        let isSelected = viewModel.selectedSeverityFilter == severity

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectedSeverityFilter = severity
            }
        } label: {
            HStack(spacing: 5) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption2)
                } else {
                    Circle()
                        .fill(severity?.color ?? .clear)
                        .frame(width: 8, height: 8)
                }
                Text(title)
                    .font(.caption.bold())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                isSelected
                ? (severity?.color ?? Color.blue)
                : Color(.tertiarySystemFill)
            )
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        isSelected ? .clear : Color(.separator),
                        lineWidth: 0.5
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ReportsListView()
        .environmentObject(SubscriptionService())
}
