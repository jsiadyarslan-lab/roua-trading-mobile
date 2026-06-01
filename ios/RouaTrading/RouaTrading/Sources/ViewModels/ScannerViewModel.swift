import Foundation

// MARK: - Scanner ViewModel
@MainActor
class ScannerViewModel: ObservableObject {
    @Published var results: [ScanResult] = []
    @Published var heatmapData: [HeatmapItem] = []
    @Published var overview: ScannerOverview?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    private let api = APIClient.shared

    func runScan() async {
        isLoading = true
        errorMessage = nil

        // Load scan results (public endpoint)
        do {
            let scanResponse: ScannerScanResponse = try await api.request("/scanner/scan")
            self.results = scanResponse.items ?? []
            print("[Scanner] Loaded \(results.count) scan results")
        } catch {
            print("[Scanner] Scan error: \(error.localizedDescription)")
        }

        // Load heatmap data (public endpoint — returns { success, data: [...] })
        do {
            let heatmapItems: [HeatmapItem] = try await api.request("/scanner/heatmap")
            self.heatmapData = heatmapItems
            print("[Scanner] Loaded \(heatmapData.count) heatmap items")
        } catch {
            print("[Scanner] Heatmap error: \(error.localizedDescription)")
        }

        // Load market overview (public endpoint)
        do {
            let scannerOverview: ScannerOverview = try await api.request("/scanner/overview")
            self.overview = scannerOverview
            print("[Scanner] Loaded market overview")
        } catch {
            print("[Scanner] Overview error: \(error.localizedDescription)")
        }

        self.isLoading = false

        // Show error only if ALL data failed to load
        if results.isEmpty && heatmapData.isEmpty {
            self.errorMessage = "فشل تحميل بيانات السوق. اسحب للأسفل للمحاولة مرة أخرى."
            self.showError = true
        }
    }

    func retry() async {
        await runScan()
    }
}
