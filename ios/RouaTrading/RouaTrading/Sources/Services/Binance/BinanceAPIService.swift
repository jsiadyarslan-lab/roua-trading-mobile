// ============================================================================
// BinanceAPIService.swift
// RouaTrading — Direct Binance REST API client for market data.
//
// Provides candlestick (kline) data and 24hr ticker quotes directly from
// Binance's public API. This bypasses the backend's /exchange/* endpoints
// which do not exist in the current deployment.
//
// Binance API docs:
//   Klines:  https://binance-docs.github.io/apidocs/spot/en/#kline-candlestick-data
//   Ticker:  https://binance-docs.github.io/apidocs/spot/en/#24hr-ticker-price-change-statistics
// ============================================================================

import Foundation

// MARK: - Binance API Service

/// Direct client for Binance public REST API endpoints.
///
/// Used for fetching market data (klines + 24hr tickers) because the
/// backend `/exchange/*` proxy routes are not deployed.  All endpoints
/// are public — no API key is required.
///
/// Usage:
/// ```swift
/// let service = BinanceAPIService.shared
/// let candles = try await service.fetchKlines(symbol: "BTCUSDT", interval: "1h", limit: 500)
/// let ticker = try await service.fetch24hrTicker(symbol: "BTCUSDT")
/// ```
@MainActor
final class BinanceAPIService {

    // MARK: - Singleton

    static let shared = BinanceAPIService()

    // MARK: - Configuration

    private let baseURL = "https://api.binance.com"
    private let session: URLSession
    private let logger = AppLogger.network

    // MARK: - Init

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: config)
    }

    // MARK: - Fetch Klines (Candlestick Data)

    /// Fetches candlestick data from Binance's public klines endpoint.
    ///
    /// - Parameters:
    ///   - symbol: Trading pair in Binance format, e.g. "BTCUSDT" (uppercase, no slash).
    ///   - interval: Binance interval string, e.g. "1m", "5m", "15m", "1h", "4h", "1d", "1w".
    ///   - limit: Maximum number of candles to return (1–1000, default 500).
    /// - Returns: Array of `CandleData` ready for chart rendering.
    func fetchKlines(
        symbol: String,
        interval: String,
        limit: Int = 500
    ) async throws -> [CandleData] {
        let endpoint = "/api/v3/klines"
        var components = URLComponents(string: baseURL + endpoint)
        components?.queryItems = [
            URLQueryItem(name: "symbol", value: symbol.uppercased()),
            URLQueryItem(name: "interval", value: interval),
            URLQueryItem(name: "limit", value: String(min(limit, 1000)))
        ]

        guard let url = components?.url else {
            throw BinanceAPIError.invalidURL
        }

        logger.debug("📊 Binance klines: \(symbol) \(interval) limit=\(limit)")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            logger.error("Binance klines network error: \(error.localizedDescription)")
            throw BinanceAPIError.networkError(underlying: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BinanceAPIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data.prefix(500), encoding: .utf8) ?? "n/a"
            logger.error("Binance klines HTTP \(httpResponse.statusCode): \(body)")
            throw BinanceAPIError.httpError(statusCode: httpResponse.statusCode, message: body)
        }

        // Binance returns an array of arrays:
        // [openTime, open, high, low, close, volume, closeTime, quoteVolume, trades,
        //  takerBuyBaseVolume, takerBuyQuoteVolume, ignore]
        guard let rawArray = try? JSONSerialization.jsonObject(with: data) as? [[Any]] else {
            throw BinanceAPIError.decodingError("Expected array of arrays from Binance klines")
        }

        let candles = rawArray.compactMap { item -> CandleData? in
            guard item.count >= 6 else { return nil }
            guard let openTime = item[0] as? Int64 else { return nil }

            return CandleData(
                time: Int(openTime / 1000), // Binance sends ms, we need seconds
                open: Double(String(describing: item[1])) ?? 0,
                high: Double(String(describing: item[2])) ?? 0,
                low: Double(String(describing: item[3])) ?? 0,
                close: Double(String(describing: item[4])) ?? 0,
                volume: Double(String(describing: item[5])) ?? 0
            )
        }

        logger.debug("📊 Binance klines: received \(candles.count) candles")
        return candles
    }

    // MARK: - Fetch 24hr Ticker

    /// Fetches 24-hour price change statistics from Binance.
    ///
    /// - Parameter symbol: Trading pair in Binance format, e.g. "BTCUSDT".
    /// - Returns: A `Quote` populated with Binance 24hr ticker data.
    func fetch24hrTicker(symbol: String) async throws -> Quote {
        let endpoint = "/api/v3/ticker/24hr"
        var components = URLComponents(string: baseURL + endpoint)
        components?.queryItems = [
            URLQueryItem(name: "symbol", value: symbol.uppercased())
        ]

        guard let url = components?.url else {
            throw BinanceAPIError.invalidURL
        }

        logger.debug("📊 Binance ticker: \(symbol)")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            logger.error("Binance ticker network error: \(error.localizedDescription)")
            throw BinanceAPIError.networkError(underlying: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BinanceAPIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data.prefix(500), encoding: .utf8) ?? "n/a"
            logger.error("Binance ticker HTTP \(httpResponse.statusCode): \(body)")
            throw BinanceAPIError.httpError(statusCode: httpResponse.statusCode, message: body)
        }

        // Decode Binance 24hr ticker response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw BinanceAPIError.decodingError("Expected JSON object from Binance ticker")
        }

        let quote = Quote(
            symbol: json["symbol"] as? String ?? symbol,
            price: Double(json["lastPrice"] as? String ?? "0") ?? 0,
            change: Double(json["priceChange"] as? String ?? "0") ?? 0,
            changePct: Double(json["priceChangePercent"] as? String ?? "0") ?? 0,
            high: Double(json["highPrice"] as? String ?? "0") ?? 0,
            low: Double(json["lowPrice"] as? String ?? "0") ?? 0,
            open: Double(json["openPrice"] as? String ?? "0") ?? 0,
            volume: Double(json["volume"] as? String ?? "0") ?? 0,
            bid: Double(json["bidPrice"] as? String ?? "0"),
            ask: Double(json["askPrice"] as? String ?? "0"),
            timestamp: String(json["closeTime"] as? Int64 ?? 0),
            source: "binance_api"
        )

        logger.debug("📊 Binance ticker: \(symbol) = $\(String(format: "%.2", quote.price))")
        return quote
    }
}

// MARK: - Binance API Error

/// Errors from Binance REST API calls.
enum BinanceAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, message: String)
    case networkError(underlying: Error)
    case decodingError(String)
    case rateLimited(retryAfter: TimeInterval?)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Binance API URL"
        case .invalidResponse:
            return "Invalid response from Binance"
        case .httpError(let code, let message):
            return "Binance API error \(code): \(message)"
        case .networkError(let error):
            return "Binance network error: \(error.localizedDescription)"
        case .decodingError(let detail):
            return "Failed to decode Binance response: \(detail)"
        case .rateLimited(let retryAfter):
            if let retryAfter {
                return "Binance rate limited. Try again in \(Int(retryAfter)) seconds."
            }
            return "Binance rate limited. Please try again later."
        }
    }
}
