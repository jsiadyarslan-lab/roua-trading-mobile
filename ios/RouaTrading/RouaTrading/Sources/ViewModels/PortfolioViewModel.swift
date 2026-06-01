import Foundation

// MARK: - Portfolio ViewModel
@MainActor
class PortfolioViewModel: ObservableObject {
    @Published var credentials: [ExchangeCredential] = []
    @Published var balances: [ExchangeBalance] = []
    @Published var totalValue: Double = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    private let api = APIClient.shared

    func loadData() async {
        isLoading = true
        errorMessage = nil

        // Try loading credentials (requires auth)
        do {
            let response: CredentialsResponse = try await api.request("/portfolio/credentials")
            self.credentials = response.data ?? []
        } catch {
            if let apiError = error as? APIError, case .unauthorized = apiError {
                self.errorMessage = "يرجى تسجيل الدخول لعرض محفظتك"
            } else {
                self.errorMessage = "فشل تحميل المحفظة: \(error.localizedDescription)"
            }
            self.showError = true
            print("[Portfolio] Error: \(error)")
        }

        // Load account overview for total portfolio value (use v2 endpoint)
        do {
            let account: AccountOverview = try await api.request("/trading/v2/portfolio")
            self.totalValue = account.effectiveTotalValue
            print("[Portfolio] ✅ Portfolio value loaded: $\(account.effectiveTotalValue)")
        } catch {
            print("[Portfolio] Account data unavailable: \(error.localizedDescription)")
        }

        // Try loading balances (correct endpoint: /portfolio/credentials/balances)
        do {
            let response: BalancesResponse = try await api.request("/portfolio/credentials/balances")
            self.balances = response.exchanges ?? []
            if let totalEquity = response.totalEquityUsd {
                self.totalValue = totalEquity
            }
            print("[Portfolio] ✅ Loaded \(self.balances.count) exchange balances, total equity: $\(response.totalEquityUsd ?? 0)")
        } catch {
            print("[Portfolio] Balances unavailable: \(error.localizedDescription)")
        }

        self.isLoading = false
    }

    func retry() async {
        await loadData()
    }
}
