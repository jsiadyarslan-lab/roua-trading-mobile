// ============================================================================
// TradingViewModel.swift
// RouaTrading — Full trading experience ViewModel.
//
// Manages chart data, live quotes, positions, trade history, order
// placement, and position closing. Uses WebSocketManager for real-time
// price and kline updates.
// ============================================================================

import Foundation
import SwiftUI

// MARK: - Trading ViewModel

/// Provides the full trading experience for a single symbol.
///
/// Manages:
/// - Candlestick chart data and timeframe switching
/// - Real-time quotes via WebSocket
/// - Open positions and closed trade history
/// - Order placement and position closing
///
/// The ViewModel subscribes to `WebSocketManager` for live price/kline
/// updates and automatically updates `currentQuote` and `candles` on
/// each WebSocket callback.
///
/// Usage:
/// ```swift
/// @StateObject private var tradingVM = TradingViewModel()
///
/// .task { await tradingVM.loadAllData() }
/// .onChange(of: tradingVM.currentSymbol) { _ in /* symbol changed */ }
/// ```
@MainActor
final class TradingViewModel: ObservableObject {

    // MARK: - Published State

    /// The currently selected trading symbol (e.g., "BTCUSDT").
    @Published var currentSymbol: String = "BTCUSDT"

    /// Candlestick data for the chart.
    @Published var candles: [CandleData] = []

    /// The latest quote for the current symbol.
    @Published var currentQuote: Quote?

    /// Open positions for the authenticated user.
    @Published var positions: [Position] = []

    /// Closed trade history.
    @Published var closedTrades: [Trade] = []

    /// The selected chart timeframe.
    @Published var selectedTimeframe: CandleInterval = .oneHour

    /// Whether the order sheet is presented.
    @Published var isOrderSheetPresented: Bool = false

    /// The result of the most recent order execution.
    @Published var orderResult: OrderExecutionResult?

    /// Whether a loading operation is in progress.
    @Published var isLoading: Bool = false

    /// Exchange credentials for order placement.
    @Published var credentials: [Credential] = []

    /// Whether an order is currently being placed.
    @Published var isPlacingOrder: Bool = false

    /// The most recent error message, if any.
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let apiClient = APIClient.shared
    private let cache = CacheManager.shared
    private let webSocket = WebSocketManager()
    private let logger = AppLogger.trading

    // MARK: - Initialization

    init() {
        setupWebSocketCallbacks()
    }

    deinit {
        // WebSocketManager's own deinit handles cleanup;
        // calling @MainActor disconnect() from synchronous deinit is invalid.
    }

    // MARK: - Load All Data

    /// Loads chart data, quote, positions, credentials, and trade history in parallel.
    func loadAllData() {
        Task {
            isLoading = true
            errorMessage = nil

            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.loadChartData() }
                group.addTask { await self.loadQuote() }
                group.addTask { await self.loadPositions() }
                group.addTask { await self.loadTradeHistory() }
                group.addTask { await self.loadCredentials() }
            }

            isLoading = false
            connectWebSocket()
        }
    }

    // MARK: - Chart Data

    /// Loads candlestick chart data for the current symbol and timeframe.
    func loadChartData() async {
        do {
            let intervalString = selectedTimeframe.rawValue
            let history: [CandleData] = try await cache.valueOrFetch(
                forKey: CacheKeys.exchangeHistory(symbol: currentSymbol, interval: intervalString),
                ttl: AppConfig.marketDataCacheTimeout
            ) {
                try await self.apiClient.request(
                    .exchangeHistory(symbol: self.currentSymbol, interval: intervalString, limit: 500)
                )
            }
            self.candles = history
        } catch {
            logger.error("Failed to load chart data: \(error.localizedDescription)")
            errorMessage = "Failed to load chart data."
        }
    }

    // MARK: - Quote

    /// Loads the latest quote for the current symbol.
    func loadQuote() async {
        do {
            let quote: Quote = try await cache.valueOrFetch(
                forKey: CacheKeys.exchangeQuote(symbol: currentSymbol),
                ttl: AppConfig.marketDataCacheTimeout
            ) {
                try await self.apiClient.request(.exchangeQuote(symbol: self.currentSymbol))
            }
            self.currentQuote = quote
        } catch {
            logger.error("Failed to load quote: \(error.localizedDescription)")
            errorMessage = "Failed to load quote."
        }
    }

    // MARK: - Positions

    /// Loads open positions via the Trading V2 API.
    func loadPositions() async {
        do {
            let positions: [Position] = try await apiClient.request(.tradingV2Positions)
            self.positions = positions
        } catch {
            logger.error("Failed to load positions: \(error.localizedDescription)")
            // Positions may be empty — not critical enough to show as error
        }
    }

    // MARK: - Trade History

    /// Loads exchange credentials for order placement.
    func loadCredentials() async {
        do {
            let creds: [Credential] = try await apiClient.request(.portfolioCredentials)
            self.credentials = creds
        } catch {
            logger.error("Failed to load credentials: \(error.localizedDescription)")
        }
    }

    /// Loads closed trade history.
    func loadTradeHistory() async {
        do {
            let history: TradeHistory = try await apiClient.request(.tradingHistory)
            self.closedTrades = history.trades
        } catch {
            logger.error("Failed to load trade history: \(error.localizedDescription)")
        }
    }

    // MARK: - Order Placement

    /// Places a new order via the Trading V2 API.
    ///
    /// On success, `orderResult` is updated and the positions list is
    /// refreshed automatically.
    ///
    /// - Parameter request: The order request payload.
    func placeOrder(_ request: OrderRequest) async {
        isPlacingOrder = true
        errorMessage = nil

        do {
            let result: OrderExecutionResult = try await apiClient.request(
                .tradingV2CreateOrder,
                body: request
            )
            self.orderResult = result
            logger.info("Order placed: \(result.orderId) — status: \(result.status.rawValue)")

            // Refresh positions after placing an order
            await loadPositions()
        } catch {
            errorMessage = error.localizedDescription
            logger.error("Failed to place order: \(error.localizedDescription)")
        }

        isPlacingOrder = false
    }

    // MARK: - Close Position

    /// Closes an open position by its ID.
    ///
    /// - Parameter id: The position identifier.
    func closePosition(id: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let request = ClosePositionRequest(positionId: id, quantity: nil)
            let _: Data = try await apiClient.requestRaw(.tradingClosePosition, body: request)
            logger.info("Position closed: \(id)")

            // Refresh positions after closing
            await loadPositions()
        } catch {
            errorMessage = error.localizedDescription
            logger.error("Failed to close position: \(error.localizedDescription)")
        }

        isLoading = false
    }

    // MARK: - Symbol Switching

    /// Switches the active trading symbol.
    ///
    /// Disconnects the current WebSocket subscription, updates the symbol,
    /// reloads chart data and quote, and reconnects the WebSocket.
    ///
    /// - Parameter symbol: The new trading symbol (e.g., "ETHUSDT").
    func switchSymbol(_ symbol: String) {
        let newSymbol = symbol.uppercased()
        guard newSymbol != currentSymbol else { return }

        currentSymbol = newSymbol
        candles = []
        currentQuote = nil
        orderResult = nil
        errorMessage = nil

        // Reload data for the new symbol
        Task {
            isLoading = true
            await loadChartData()
            await loadQuote()
            isLoading = false
        }

        connectWebSocket()
    }

    // MARK: - Timeframe Switching

    /// Switches the chart timeframe and reloads candle data.
    ///
    /// - Parameter interval: The new candle interval.
    func switchTimeframe(_ interval: CandleInterval) {
        guard interval != selectedTimeframe else { return }

        selectedTimeframe = interval
        candles = []
        errorMessage = nil

        Task {
            await loadChartData()
        }

        // Reconnect WebSocket with new interval
        connectWebSocket()
    }

    // MARK: - WebSocket Management

    /// Connects the WebSocket for live price and kline updates.
    private func connectWebSocket() {
        let symbol = currentSymbol.lowercased()
        let interval = selectedTimeframe.rawValue
        webSocket.connect(symbols: [symbol], intervals: [interval])
    }

    /// Sets up WebSocket callbacks for real-time data updates.
    private func setupWebSocketCallbacks() {
        webSocket.onKlineUpdate = { [weak self] kline in
            guard let self else { return }
            self.handleKlineUpdate(kline)
        }

        webSocket.onTickerUpdate = { [weak self] ticker in
            guard let self else { return }
            self.handleTickerUpdate(ticker)
        }
    }

    /// Processes a kline update from the WebSocket.
    ///
    /// If the kline is for a closed candle, it is appended to the chart.
    /// If it's for the current (open) candle, the last candle is updated.
    private func handleKlineUpdate(_ kline: BinanceKline) {
        guard kline.symbol.uppercased() == currentSymbol else { return }

        let updatedCandle = CandleData(
            time: Int(kline.openTime / 1000),
            open: Double(kline.open) ?? 0,
            high: Double(kline.high) ?? 0,
            low: Double(kline.low) ?? 0,
            close: Double(kline.close) ?? 0,
            volume: Double(kline.volume) ?? 0
        )

        if kline.isClosed {
            // Closed candle — append to chart if not already present
            if candles.last?.time != updatedCandle.time {
                candles.append(updatedCandle)
            } else if let lastIndex = candles.indices.last {
                candles[lastIndex] = updatedCandle
            }
        } else {
            // Open (current) candle — update the last entry
            if let lastIndex = candles.indices.last,
               candles[lastIndex].time == updatedCandle.time {
                candles[lastIndex] = updatedCandle
            } else {
                candles.append(updatedCandle)
            }
        }
    }

    /// Processes a ticker update from the WebSocket.
    ///
    /// Updates `currentQuote` with the latest price and change data.
    private func handleTickerUpdate(_ ticker: BinanceTicker) {
        guard ticker.symbol.uppercased() == currentSymbol else { return }

        let quote = Quote(
            symbol: ticker.symbol.uppercased(),
            price: Double(ticker.lastPrice) ?? (currentQuote?.price ?? 0),
            change: Double(ticker.priceChange) ?? 0,
            changePct: Double(ticker.priceChangePercent) ?? 0,
            high: Double(ticker.high) ?? 0,
            low: Double(ticker.low) ?? 0,
            open: Double(ticker.open) ?? 0,
            volume: Double(ticker.volume) ?? 0,
            bid: nil,
            ask: nil,
            timestamp: String(ticker.eventTime),
            source: "binance_ws"
        )

        self.currentQuote = quote
    }
}
