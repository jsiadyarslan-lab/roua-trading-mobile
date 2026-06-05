import Foundation
import Combine

// MARK: - Real-Time Event Types

/// Events received from the backend's real-time channels.
enum RealTimeEvent {
    /// Ticker price update.
    case ticker(symbol: String, price: String, change24h: String?, changePercent24h: String?)

    /// Market status change (open/closed, circuit breaker, etc.).
    case marketStatus(status: String, message: String?)

    /// System notification (maintenance, upgrade, etc.).
    case system(message: String, level: String?)

    /// User notification (trade filled, signal triggered, etc.).
    case notification(id: String, title: String, body: String, type: String?)

    /// Auto-executed trading signal.
    case autoExecuteSignal(signalId: String, symbol: String, action: String, price: String?)

    /// Unread notification count update.
    case unreadCount(count: Int)
}

// MARK: - Socket Manager

/// Manages real-time communication with the Roua Trading backend.
///
/// Since the backend uses Socket.IO but we want to avoid the Socket.IO
/// client dependency, this manager uses a hybrid approach:
///
/// - **Exchange namespace**: Uses `URLSessionWebSocketTask` to connect to
///   the backend's WebSocket endpoint for price updates.
/// - **Notifications namespace**: Uses REST polling at a configurable interval
///   since notifications don't require sub-second latency.
///
/// Both channels authenticate using the session token stored in Keychain.
///
/// - Note: If Socket.IO client support is added later via SPM dependency,
///   replace the implementations in `connectExchange()` and the polling
///   timer with proper Socket.IO event handlers.
@MainActor
final class SocketManager: ObservableObject {

    // MARK: - Published

    /// Whether the exchange WebSocket is connected.
    @Published private(set) var isExchangeConnected: Bool = false

    /// Whether the notification poller is active.
    @Published private(set) var isNotificationsActive: Bool = false

    // MARK: - Callbacks

    /// Called when a real-time event is received from any channel.
    var onEvent: ((RealTimeEvent) -> Void)?

    // MARK: - Private Properties

    private var exchangeTask: URLSessionWebSocketTask?
    private let session: URLSession

    /// REST polling timer for notifications.
    private var notificationPollTimer: Timer?

    /// Polling interval for notifications (seconds).
    private var notificationPollInterval: TimeInterval = 15.0

    /// Last unread count to detect changes.
    private var lastUnreadCount: Int = 0

    private let keychain = KeychainManager.shared
    private let apiClient = APIClient.shared
    private let logger = AppLogger.webSocket

    /// Reconnect attempt counter for the exchange channel.
    private var reconnectAttempt: Int = 0
    private let maxReconnectAttempts: Int = 10
    private let baseReconnectDelay: TimeInterval = 2.0

    /// Whether a deliberate disconnect is in progress.
    private var isDisconnecting: Bool = false

    // MARK: - Initialization

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    deinit {
        notificationPollTimer?.invalidate()
    }

    // MARK: - Connect All

    /// Connects both the exchange WebSocket and the notification poller.
    func connect() {
        connectExchange()
        startNotificationPolling()
    }

    /// Disconnects both channels.
    func disconnect() {
        isDisconnecting = true
        disconnectExchange()
        stopNotificationPolling()
    }

    // MARK: - Exchange Channel (WebSocket)

    /// Connects to the backend's exchange WebSocket for real-time price updates.
    ///
    /// The backend exposes a WebSocket at `/exchange` that pushes `ticker` events.
    /// We connect using `URLSessionWebSocketTask` with the session token
    /// in the `x-roua-session` header for authentication.
    private func connectExchange() {
        guard let sessionToken = keychain.retrieve(key: AppConfig.sessionTokenKey) else {
            logger.warning("No session token — skipping exchange WebSocket")
            return
        }

        isDisconnecting = false
        reconnectAttempt = 0

        let urlString = "\(AppConfig.socketURL)/exchange"
        guard let url = URL(string: urlString) else {
            logger.error("Invalid exchange WebSocket URL")
            return
        }

        var request = URLRequest(url: url)
        request.setValue(sessionToken, forHTTPHeaderField: "x-roua-session")
        request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")

        exchangeTask = session.webSocketTask(with: request)
        exchangeTask?.resume()

        isExchangeConnected = true
        logger.info("Exchange WebSocket connected")

        listenExchange()
    }

    /// Disconnects the exchange WebSocket.
    private func disconnectExchange() {
        exchangeTask?.cancel(with: .goingAway, reason: "Disconnecting".data(using: .utf8))
        exchangeTask = nil
        isExchangeConnected = false
    }

    /// Starts the async receive loop for the exchange WebSocket.
    private func listenExchange() {
        Task {
            guard let task = exchangeTask else { return }

            do {
                while true {
                    let message = try await task.receive()

                    switch message {
                    case .string(let text):
                        parseExchangeMessage(text)
                    case .data(let data):
                        if let text = String(data: data, encoding: .utf8) {
                            parseExchangeMessage(text)
                        }
                    @unknown default:
                        break
                    }
                }
            } catch {
                if !isDisconnecting {
                    logger.error("Exchange WebSocket error: \(error)")
                    handleExchangeDisconnect()
                }
            }
        }
    }

    /// Parses a message from the exchange WebSocket.
    private func parseExchangeMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        let eventType = json["event"] as? String ?? json["type"] as? String ?? ""

        switch eventType {
        case "ticker":
            let symbol = json["symbol"] as? String ?? ""
            let price = json["price"] as? String ?? json["lastPrice"] as? String ?? ""
            let change = json["priceChange"] as? String
            let changePercent = json["priceChangePercent"] as? String ?? json["changePercent"] as? String
            onEvent?(.ticker(symbol: symbol, price: price, change24h: change, changePercent24h: changePercent))

        case "market_status":
            let status = json["status"] as? String ?? ""
            let message = json["message"] as? String
            onEvent?(.marketStatus(status: status, message: message))

        case "system":
            let message = json["message"] as? String ?? ""
            let level = json["level"] as? String
            onEvent?(.system(message: message, level: level))

        default:
            // Unknown event type — log in debug
            #if DEBUG
            logger.debug("Unknown exchange event: \(eventType) — \(text.prefix(200))")
            #endif
        }
    }

    /// Handles exchange WebSocket disconnection with reconnection.
    private func handleExchangeDisconnect() {
        isExchangeConnected = false

        guard !isDisconnecting else { return }

        if reconnectAttempt >= maxReconnectAttempts {
            logger.error("Max exchange WebSocket reconnection attempts reached")
            return
        }

        reconnectAttempt += 1
        let delay = min(
            baseReconnectDelay * pow(2.0, Double(reconnectAttempt - 1)),
            30.0
        )

        logger.info("Reconnecting exchange WebSocket in \(delay)s (attempt \(reconnectAttempt))")

        Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !isDisconnecting else { return }
            connectExchange()
        }
    }

    // MARK: - Notification Channel (REST Polling)

    /// Starts polling for notifications at the configured interval.
    private func startNotificationPolling() {
        guard keychain.retrieve(key: AppConfig.sessionTokenKey) != nil else {
            logger.warning("No session token — skipping notification polling")
            return
        }

        stopNotificationPolling()

        isNotificationsActive = true
        logger.info("Notification polling started (every \(notificationPollInterval)s)")

        // Immediate first poll
        Task { await pollNotifications() }

        notificationPollTimer = Timer.scheduledTimer(
            withTimeInterval: notificationPollInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.pollNotifications()
            }
        }
    }

    /// Stops notification polling.
    private func stopNotificationPolling() {
        notificationPollTimer?.invalidate()
        notificationPollTimer = nil
        isNotificationsActive = false
    }

    /// Polls the backend for new notifications and unread count.
    private func pollNotifications() async {
        do {
            // Fetch unread count
            let countResponse: UnreadCountResponse = try await apiClient.request(
                .notificationsUnreadCount
            )
            let newCount = countResponse.count ?? countResponse.data ?? 0

            if newCount != lastUnreadCount {
                lastUnreadCount = newCount
                onEvent?(.unreadCount(count: newCount))
            }

            // Fetch recent unread notifications
            let notifications: [NotificationItem] = try await apiClient.request(
                .notifications(limit: 5, offset: 0, unread: true, type: nil)
            )
            for notification in notifications {
                onEvent?(.notification(
                    id: notification.id,
                    title: notification.title,
                    body: notification.body,
                    type: notification.type
                ))
            }
        } catch {
            logger.warning("Notification poll failed: \(error)")
        }
    }

    // MARK: - Send Message

    /// Sends a text message through the exchange WebSocket.
    func sendExchangeMessage(_ text: String) {
        Task {
            try? await exchangeTask?.send(.string(text))
        }
    }
}

// MARK: - Helper Models

/// Response from the unread count endpoint.
private struct UnreadCountResponse: Codable {
    let count: Int?
    let data: Int?
}

/// A notification item from the backend.
struct NotificationItem: Codable, Identifiable {
    let id: String
    let title: String
    let body: String
    let type: String?
    let read: Bool?
    let createdAt: String?

    private enum CodingKeys: String, CodingKey {
        case id, title, body, type, read
        case createdAt = "created_at"
    }
}
