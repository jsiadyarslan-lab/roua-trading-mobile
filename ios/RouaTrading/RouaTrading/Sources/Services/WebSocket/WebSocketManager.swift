import Foundation
import Combine

// MARK: - WebSocket Models

/// A parsed Binance kline (candlestick) update.
struct BinanceKline: Codable, Sendable {
    let eventType: String
    let eventTime: Int64
    let symbol: String
    let interval: String
    let openTime: Int64
    let open: String
    let high: String
    let low: String
    let close: String
    let volume: String
    let closeTime: Int64
    let quoteVolume: String
    let trades: Int
    let isClosed: Bool

    private enum CodingKeys: String, CodingKey {
        case eventType = "e"
        case eventTime = "E"
        case symbol = "s"
        case interval = "i"
        case openTime = "t"
        case open = "o"
        case high = "h"
        case low = "l"
        case close = "c"
        case volume = "v"
        case closeTime = "T"
        case quoteVolume = "q"
        case trades = "n"
        case isClosed = "x"
    }
}

/// A parsed Binance 24hr ticker update.
struct BinanceTicker: Codable, Sendable {
    let eventType: String
    let eventTime: Int64
    let symbol: String
    let priceChange: String
    let priceChangePercent: String
    let weightedAvgPrice: String
    let lastPrice: String
    let lastQty: String
    let open: String
    let high: String
    let low: String
    let volume: String
    let quoteVolume: String
    let trades: Int

    private enum CodingKeys: String, CodingKey {
        case eventType = "e"
        case eventTime = "E"
        case symbol = "s"
        case priceChange = "p"
        case priceChangePercent = "P"
        case weightedAvgPrice = "w"
        case lastPrice = "c"
        case lastQty = "Q"
        case open = "o"
        case high = "h"
        case low = "l"
        case volume = "v"
        case quoteVolume = "q"
        case trades = "n"
    }
}

// MARK: - WebSocket Connection State

/// The current state of the WebSocket connection.
enum WebSocketConnectionState: Sendable {
    case disconnected
    case connecting
    case connected
    case reconnecting(attempt: Int)
    case failed(Error)
}

// MARK: - WebSocket Manager

/// Manages a persistent WebSocket connection to Binance's combined stream endpoint.
///
/// Features:
/// - Connects to `wss://stream.binance.com:9443/stream?streams=...`
/// - Auto-reconnect with exponential backoff
/// - Throttles updates to ~24 FPS using a buffer/flush mechanism
/// - Callbacks for kline and ticker updates
/// - Symbol switching (disconnects old, connects new)
///
/// Usage:
/// ```swift
/// let ws = WebSocketManager()
/// ws.onKlineUpdate = { kline in ... }
/// ws.onTickerUpdate = { ticker in ... }
/// ws.connect(symbols: ["btcusdt"], intervals: ["1m"])
/// ```
@MainActor
final class WebSocketManager: ObservableObject {

    // MARK: - Published

    @Published private(set) var connectionState: WebSocketConnectionState = .disconnected

    // MARK: - Callbacks

    /// Called when a kline (candlestick) update is received.
    var onKlineUpdate: ((BinanceKline) -> Void)?

    /// Called when a 24hr ticker update is received.
    var onTickerUpdate: ((BinanceTicker) -> Void)?

    // MARK: - Private Properties

    private var webSocketTask: URLSessionWebSocketTask?
    private let session: URLSession

    /// Current subscription streams (e.g., "btcusdt@kline_1m/btcusdt@ticker").
    private var currentStreams: String = ""

    /// Currently subscribed symbols (lowercase).
    private var currentSymbols: [String] = []

    /// Currently subscribed intervals.
    private var currentIntervals: [String] = []

    /// Reconnect attempt counter.
    private var reconnectAttempt: Int = 0

    /// Maximum number of reconnect attempts before giving up.
    private let maxReconnectAttempts: Int = 10

    /// Base delay for exponential backoff (seconds).
    private let baseReconnectDelay: TimeInterval = 1.0

    /// Maximum reconnect delay (seconds).
    private let maxReconnectDelay: TimeInterval = 30.0

    /// Throttle timer interval (≈24 FPS → ~42ms).
    private let throttleInterval: TimeInterval = 1.0 / 24.0

    /// Buffer for throttled kline updates (latest per symbol).
    private var klineBuffer: [String: BinanceKline] = [:]

    /// Buffer for throttled ticker updates (latest per symbol).
    private var tickerBuffer: [String: BinanceTicker] = [:]

    /// Throttle flush timer.
    private var throttleTimer: Timer?

    /// Whether a deliberate disconnect is in progress.
    private var isDisconnecting: Bool = false

    private let logger = AppLogger.webSocket

    // MARK: - Initialization

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    deinit {
        throttleTimer?.invalidate()
    }

    // MARK: - Connect

    /// Connects to the Binance WebSocket for the given symbols and intervals.
    ///
    /// - Parameters:
    ///   - symbols: Trading pairs in lowercase (e.g., `["btcusdt", "ethusdt"]`).
    ///   - intervals: Kline intervals (e.g., `["1m", "5m", "1h"]`).
    func connect(symbols: [String], intervals: [String] = ["1m"]) {
        // Disconnect any existing connection
        disconnect()

        currentSymbols = symbols.map { $0.lowercased() }
        currentIntervals = intervals

        // Build the combined stream path
        var streams: [String] = []
        for symbol in currentSymbols {
            for interval in currentIntervals {
                streams.append("\(symbol)@kline_\(interval)")
            }
            streams.append("\(symbol)@ticker")
        }

        currentStreams = streams.joined(separator: "/")

        let urlString = "\(AppConfig.binanceWSURL)?streams=\(currentStreams)"
        guard let url = URL(string: urlString) else {
            logger.error("Invalid WebSocket URL: \(urlString)")
            return
        }

        isDisconnecting = false
        reconnectAttempt = 0
        connectionState = .connecting

        logger.info("Connecting to Binance WS: \(currentStreams)")

        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()

        startListening()
        startThrottleTimer()
    }

    /// Switches to a new symbol, disconnecting and reconnecting with the new stream.
    ///
    /// - Parameters:
    ///   - symbol: The new trading pair in lowercase.
    ///   - intervals: Kline intervals (default: current intervals).
    func switchSymbol(_ symbol: String, intervals: [String]? = nil) {
        connect(symbols: [symbol], intervals: intervals ?? currentIntervals)
    }

    // MARK: - Disconnect

    /// Gracefully disconnects the WebSocket.
    func disconnect() {
        isDisconnecting = true
        throttleTimer?.invalidate()
        throttleTimer = nil

        webSocketTask?.cancel(with: .goingAway, reason: "Disconnecting".data(using: .utf8))
        webSocketTask = nil

        klineBuffer.removeAll()
        tickerBuffer.removeAll()

        connectionState = .disconnected
    }

    // MARK: - Listening

    /// Starts the async message receive loop.
    private func startListening() {
        Task {
            guard let task = webSocketTask else { return }

            do {
                while true {
                    let message = try await task.receive()

                    switch message {
                    case .string(let text):
                        handleMessage(text)
                    case .data(let data):
                        if let text = String(data: data, encoding: .utf8) {
                            handleMessage(text)
                        }
                    @unknown default:
                        break
                    }
                }
            } catch {
                if !isDisconnecting {
                    logger.error("WebSocket receive error: \(error)")
                    handleDisconnect()
                }
            }
        }
    }

    // MARK: - Message Handling

    /// Parses an incoming WebSocket message and buffers it for throttled delivery.
    private func handleMessage(_ text: String) {
        // Binance combined stream wraps messages in { "stream": "...", "data": {...} }
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let streamName = json["stream"] as? String,
              let payloadData = json["data"] as? [String: Any] else {
            return
        }

        guard let payloadJSON = try? JSONSerialization.data(withJSONObject: payloadData) else {
            return
        }

        if streamName.contains("@kline_") {
            if let klineRaw = try? JSONDecoder().decode(BinanceKline.self, from: payloadJSON) {
                klineBuffer[klineRaw.symbol] = klineRaw
            }
        } else if streamName.contains("@ticker") {
            if let tickerRaw = try? JSONDecoder().decode(BinanceTicker.self, from: payloadJSON) {
                tickerBuffer[tickerRaw.symbol] = tickerRaw
            }
        }
    }

    // MARK: - Throttle (24 FPS Flush)

    /// Starts a timer that flushes buffered updates at ~24 FPS.
    private func startThrottleTimer() {
        throttleTimer?.invalidate()
        throttleTimer = Timer.scheduledTimer(
            withTimeInterval: throttleInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.flushBufferedUpdates()
            }
        }
    }

    /// Flushes all buffered kline and ticker updates to their callbacks.
    private func flushBufferedUpdates() {
        // Flush klines
        for (_, kline) in klineBuffer {
            onKlineUpdate?(kline)
        }
        klineBuffer.removeAll()

        // Flush tickers
        for (_, ticker) in tickerBuffer {
            onTickerUpdate?(ticker)
        }
        tickerBuffer.removeAll()
    }

    // MARK: - Reconnection

    /// Handles an unexpected disconnection with exponential backoff reconnection.
    private func handleDisconnect() {
        connectionState = .disconnected

        guard !isDisconnecting else { return }

        if reconnectAttempt >= maxReconnectAttempts {
            let error = NSError(
                domain: "WebSocketManager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Max reconnection attempts reached"]
            )
            connectionState = .failed(error)
            logger.error("Max WebSocket reconnection attempts reached")
            return
        }

        reconnectAttempt += 1
        connectionState = .reconnecting(attempt: reconnectAttempt)

        // Exponential backoff: 1s, 2s, 4s, 8s, 16s, 30s, 30s, ...
        let delay = min(
            baseReconnectDelay * pow(2.0, Double(reconnectAttempt - 1)),
            maxReconnectDelay
        )

        logger.info("Reconnecting in \(delay)s (attempt \(reconnectAttempt)/\(maxReconnectAttempts))")

        Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !isDisconnecting else { return }
            connect(symbols: currentSymbols, intervals: currentIntervals)
        }
    }

    // MARK: - Subscribe / Unsubscribe (Binance Live Subscription)

    /// Sends a subscribe message to the Binance combined stream.
    ///
    /// - Parameter streams: Stream names to subscribe to (e.g., `["ethusdt@ticker"]`).
    func subscribe(streams: [String]) {
        let message: [String: Any] = [
            "method": "SUBSCRIBE",
            "params": streams,
            "id": Int.random(in: 1...100000),
        ]
        sendJSON(message)
    }

    /// Sends an unsubscribe message to the Binance combined stream.
    ///
    /// - Parameter streams: Stream names to unsubscribe from.
    func unsubscribe(streams: [String]) {
        let message: [String: Any] = [
            "method": "UNSUBSCRIBE",
            "params": streams,
            "id": Int.random(in: 1...100000),
        ]
        sendJSON(message)
    }

    // MARK: - Send Helpers

    /// Sends a JSON-encoded message through the WebSocket.
    private func sendJSON(_ message: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: message),
              let text = String(data: data, encoding: .utf8) else {
            return
        }

        Task {
            try? await webSocketTask?.send(.string(text))
        }
    }
}
