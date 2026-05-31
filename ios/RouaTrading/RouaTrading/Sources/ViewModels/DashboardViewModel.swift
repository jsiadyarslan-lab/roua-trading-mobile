import Foundation

// MARK: - Dashboard ViewModel
@MainActor
class DashboardViewModel: ObservableObject {
    @Published var accountOverview: AccountOverview?
    @Published var positions: [Position] = []
    @Published var trades: [Trade] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    private let api = APIClient.shared

    // Computed portfolio summary from account overview
    var portfolioSummary: PortfolioSummary? {
        guard let acc = accountOverview else { return nil }
        return PortfolioSummary(
            totalValue: acc.totalValue ?? 0,
            totalPnl: (acc.totalRealizedPnl ?? 0) + (acc.totalUnrealizedPnl ?? 0),
            dailyPnl: acc.totalUnrealizedPnl ?? 0,
            positions: acc.positions,
            unrealizedPnl: acc.totalUnrealizedPnl,
            realizedPnl: acc.totalRealizedPnl
        )
    }

    func loadDashboard() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load account overview (includes positions + summary)
            let account: AccountOverview = try await api.request("/trading/account")
            self.accountOverview = account
            self.positions = account.positions ?? []

            // Load trade history separately
            let historyResponse: TradeHistoryResponse = try await api.request("/trading/history")
            self.trades = historyResponse.trades ?? []

            self.isLoading = false
        } catch {
            self.isLoading = false
            self.errorMessage = "فشل تحميل لوحة المعلومات: \(error.localizedDescription)"
            self.showError = true
            print("[Dashboard] Load error: \(error)")
        }
    }

    func retry() async {
        await loadDashboard()
    }
}
