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
            // Load account overview (includes positions + summary) — requires auth
            let account: AccountOverview = try await api.request("/trading/account")
            self.accountOverview = account
            self.positions = account.positions ?? []
        } catch {
            // Show auth error to user
            if let apiError = error as? APIError, case .unauthorized = apiError {
                self.errorMessage = "يرجى تسجيل الدخول لعرض بياناتك"
                self.showError = true
            }
            print("[Dashboard] Account data unavailable: \(error.localizedDescription)")
        }

        do {
            // Load trade history separately — requires auth
            let historyResponse: TradeHistoryResponse = try await api.request("/trading/history")
            self.trades = historyResponse.trades ?? []
        } catch {
            print("[Dashboard] Trade history unavailable: \(error.localizedDescription)")
        }

        self.isLoading = false
    }

    func retry() async {
        await loadDashboard()
    }
}
