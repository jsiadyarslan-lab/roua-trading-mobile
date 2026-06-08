import Foundation
import AuthenticationServices
import CryptoKit
import UIKit

// MARK: - Auth Models

// NOTE: `User` is defined in AuthModels.swift — do not redefine here.

/// Challenge response from the WebAuthn registration/authentication flow.
struct WebAuthnChallenge: Codable {
    let challenge: String
    let rpId: String?
    let allowCredentials: [AuthCredentialDescriptor]?
    let excludeCredentials: [AuthCredentialDescriptor]?

    private enum CodingKeys: String, CodingKey {
        case challenge, rpId
        case allowCredentials = "allow_credentials"
        case excludeCredentials = "exclude_credentials"
    }
}

/// A credential descriptor used in WebAuthn challenges.
/// Named differently from WebAuthnRegistrationOptions.WebAuthnCredentialDescriptor
/// in AuthModels.swift to avoid any ambiguity.
struct AuthCredentialDescriptor: Codable {
    let id: String
    let type: String?
    let transports: [String]?
}

/// Verification payload sent after WebAuthn registration or authentication.
struct WebAuthnVerification: Codable {
    let id: String
    let rawId: String
    let response: WebAuthnVerificationResponse
    let type: String
}

/// The response portion of a WebAuthn verification.
struct WebAuthnVerificationResponse: Codable {
    let clientDataJSON: String
    let attestationObject: String?
    let authenticatorData: String?
    let signature: String?
    let userHandle: String?

    private enum CodingKeys: String, CodingKey {
        case clientDataJSON = "clientDataJSON"
        case attestationObject = "attestationObject"
        case authenticatorData = "authenticatorData"
        case signature
        case userHandle = "userHandle"
    }
}

/// Registration request body.
struct RegistrationRequest: Codable {
    let email: String
    let name: String?
}

/// OTP send request body.
struct OtpSendRequest: Codable {
    let email: String
}

/// OTP verify request body.
struct OtpVerifyRequest: Codable {
    let email: String
    let otp: String
}

/// OTP send response.
struct OtpSendResponse: Codable {
    let success: Bool
    let message: String?
}

/// OTP verify response — backend returns { authenticated, user, isGuest }.
struct OtpVerifyResponse: Codable {
    let authenticated: Bool
    let user: User?
    let isGuest: Bool?
}

/// Session info returned by the backend.
struct SessionInfo: Codable {
    let user: User
    let sessionToken: String?
    let expiresAt: String?

    private enum CodingKeys: String, CodingKey {
        case user, sessionToken
        case expiresAt = "expires_at"
    }
}

// MARK: - Auth Service Error

enum AuthError: LocalizedError {
    case webAuthnNotSupported
    case challengeFailed(String)
    case credentialCreationFailed(Error)
    case assertionFailed(Error)
    case verificationFailed(String)
    case oauthCancelled
    case oauthFailed(String)
    case sessionValidationFailed
    case refreshFailed
    case biometricNotAvailable
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .webAuthnNotSupported:
            return "WebAuthn is not supported on this device."
        case .challengeFailed(let reason):
            return "Failed to get challenge: \(reason)"
        case .credentialCreationFailed(let error):
            return "Credential creation failed: \(error.localizedDescription)"
        case .assertionFailed(let error):
            return "Authentication assertion failed: \(error.localizedDescription)"
        case .verificationFailed(let reason):
            return "Verification failed: \(reason)"
        case .oauthCancelled:
            return "Sign-in was cancelled."
        case .oauthFailed(let reason):
            return "OAuth sign-in failed: \(reason)"
        case .sessionValidationFailed:
            return "Could not validate session."
        case .refreshFailed:
            return "Failed to refresh session."
        case .biometricNotAvailable:
            return "Biometric authentication is not available."
        case .notAuthenticated:
            return "Not authenticated."
        }
    }
}

// MARK: - Auth Service

/// Manages authentication state and flows for the app.
///
/// Supports three authentication methods:
/// 1. **WebAuthn (Passkeys)** — registration and authentication via the FIDO2 standard
/// 2. **Google OAuth** — via `ASWebAuthenticationSession`
/// 3. **Biometric unlock** — quick re-authentication using Face ID / Touch ID
///
/// The service persists tokens in the Keychain via `KeychainManager` and
/// validates the session on app launch.
@MainActor
final class AuthService: ObservableObject {

    // MARK: - Singleton

    static let shared = AuthService()

    // MARK: - Published State

    /// Whether the user is currently authenticated.
    @Published private(set) var isAuthenticated: Bool = false

    /// The currently authenticated user, if any.
    @Published private(set) var currentUser: User?

    // MARK: - Dependencies

    private let apiClient = APIClient.shared
    private let keychain = KeychainManager.shared
    private let logger = AppLogger.auth

    /// Keychain key for storing the user object.
    private let userKey = "roua_user"

    // MARK: - OAuth Session Retention

    /// Strong reference to the active `ASWebAuthenticationSession` to prevent
    /// premature deallocation while the browser is open.
    private var webAuthSession: ASWebAuthenticationSession?

    /// Provides the presentation anchor (key window) for `ASWebAuthenticationSession`.
    private let webAuthProvider = OAuthPresentationProvider()

    // MARK: - Initialization

    private init() {}

    // MARK: - Session Validation (App Launch)

    /// Validates the current session on app launch.
    ///
    /// Call this from `App.onAppear` or the scene delegate. If a valid session
    /// token exists, it fetches the current user. If the session is expired,
    /// it attempts a refresh.
    func validateSession() async {
        guard keychain.contains(key: AppConfig.sessionTokenKey) else {
            logger.info("No session token found — user is not authenticated")
            isAuthenticated = false
            currentUser = nil
            return
        }

        do {
            // The backend /auth/session endpoint returns:
            //   Authenticated:   {"authenticated": true, "user": {...}}
            //   Not authenticated: {"authenticated": false}
            // We first check the `authenticated` flag, then extract user data.
            let rawData = try await apiClient.requestRaw(.authSession)

            // Try to decode as a simple response with `authenticated` flag
            if let json = try? JSONSerialization.jsonObject(with: rawData) as? [String: Any] {
                let isAuthed = json["authenticated"] as? Bool ?? false

                guard isAuthed else {
                    logger.info("Session not authenticated — attempting refresh")
                    // Token exists but session is not valid, try refresh
                    do {
                        let refreshed = try await apiClient.refreshSession()
                        if refreshed {
                            // Re-fetch session info after refresh
                            let refreshedData = try await apiClient.requestRaw(.authSession)
                            if let refreshedJson = try? JSONSerialization.jsonObject(with: refreshedData) as? [String: Any],
                               let stillAuthed = refreshedJson["authenticated"] as? Bool, stillAuthed,
                               let userData = refreshedJson["user"] {
                                let userDataJson = try JSONSerialization.data(withJSONObject: userData)
                                let user = try JSONDecoder().decode(User.self, from: userDataJson)
                                self.currentUser = user
                                self.isAuthenticated = true
                                keychain.store(key: userKey, value: user)
                                logger.info("Session refreshed and validated for user: \(user.email)")
                            } else {
                                clearSession()
                            }
                        } else {
                            clearSession()
                        }
                    } catch {
                        logger.error("Session refresh failed: \(error)")
                        clearSession()
                    }
                    return
                }

                // User is authenticated — extract user data
                if let userData = json["user"] {
                    let userDataJson = try JSONSerialization.data(withJSONObject: userData)
                    let user = try JSONDecoder().decode(User.self, from: userDataJson)
                    self.currentUser = user
                    self.isAuthenticated = true
                    keychain.store(key: userKey, value: user)
                    logger.info("Session validated for user: \(user.email)")
                } else {
                    // Try decoding as SessionInfo (legacy format)
                    let sessionInfo = try JSONDecoder().decode(SessionInfo.self, from: rawData)
                    self.currentUser = sessionInfo.user
                    self.isAuthenticated = true
                    keychain.store(key: userKey, value: sessionInfo.user)
                    if let token = sessionInfo.sessionToken {
                        keychain.store(key: AppConfig.sessionTokenKey, value: token)
                    }
                    logger.info("Session validated (legacy format) for user: \(sessionInfo.user.email)")
                }
            } else {
                // Fallback: try decoding as SessionInfo directly
                let sessionInfo: SessionInfo = try await apiClient.request(.authSession)
                self.currentUser = sessionInfo.user
                self.isAuthenticated = true
                keychain.store(key: userKey, value: sessionInfo.user)
            }
        } catch {
            logger.warning("Session validation failed: \(error) — attempting refresh")

            // Try refreshing
            do {
                let refreshed = try await apiClient.refreshSession()
                if refreshed {
                    let sessionInfo: SessionInfo = try await apiClient.request(.authSession)
                    self.currentUser = sessionInfo.user
                    self.isAuthenticated = true
                    keychain.store(key: userKey, value: sessionInfo.user)
                    logger.info("Session refreshed successfully")
                } else {
                    clearSession()
                }
            } catch {
                logger.error("Session refresh failed: \(error)")
                clearSession()
            }
        }
    }

    // MARK: - WebAuthn Registration

    /// Registers a new user with WebAuthn (Passkey).
    ///
    /// Flow:
    /// 1. POST email to `/auth/register` → receive challenge
    /// 2. Create a credential with `ASAuthorizationPlatformPublicKeyCredentialProvider`
    /// 3. POST verification to `/auth/verify`
    ///
    /// - Parameters:
    ///   - email: The user's email address.
    ///   - name: The user's display name (optional).
    func registerWithPasskey(email: String, name: String? = nil) async throws {
        // Step 1: Request a challenge from the backend
        let challengeResponse: WebAuthnChallenge
        do {
            challengeResponse = try await apiClient.request(
                .authRegister,
                body: RegistrationRequest(email: email, name: name)
            )
        } catch {
            throw AuthError.challengeFailed(error.localizedDescription)
        }

        // Step 2: Create a passkey credential
        let challengeData = try decodeBase64(challengeResponse.challenge)
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(
            relyingPartyIdentifier: challengeResponse.rpId ?? "roua-trading.com"
        )

        let request = provider.createCredentialRegistrationRequest(
            challenge: challengeData,
            name: name ?? email,
            userID: Data(email.utf8)
        )

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])

        let credential: ASAuthorizationPlatformPublicKeyCredentialRegistration
        do {
            credential = try await performAuthorization(controller: authorizationController)
        } catch {
            throw AuthError.credentialCreationFailed(error)
        }

        // Step 3: Verify with the backend
        let verification = WebAuthnVerification(
            id: credential.credentialID.base64EncodedString(),
            rawId: credential.credentialID.base64EncodedString(),
            response: WebAuthnVerificationResponse(
                clientDataJSON: credential.rawClientDataJSON.base64EncodedString(),
                attestationObject: credential.rawAttestationObject?.base64EncodedString(),
                authenticatorData: nil,
                signature: nil,
                userHandle: nil
            ),
            type: "public-key"
        )

        do {
            let sessionInfo: SessionInfo = try await apiClient.request(
                .authVerify,
                body: verification
            )
            handleSuccessfulAuth(sessionInfo: sessionInfo)
        } catch {
            throw AuthError.verificationFailed(error.localizedDescription)
        }
    }

    // MARK: - WebAuthn Authentication

    /// Authenticates an existing user with WebAuthn (Passkey).
    ///
    /// Flow:
    /// 1. POST email to `/auth/challenge` → receive challenge
    /// 2. Get an assertion with `ASAuthorizationPlatformPublicKeyCredentialProvider`
    /// 3. POST verification to `/auth/verify`
    ///
    /// - Parameter email: The user's email address.
    func authenticateWithPasskey(email: String) async throws {
        // Step 1: Request a challenge
        let challengeResponse: WebAuthnChallenge
        do {
            challengeResponse = try await apiClient.request(.authChallenge(email: email))
        } catch {
            throw AuthError.challengeFailed(error.localizedDescription)
        }

        // Step 2: Get an assertion (authenticate with existing passkey)
        let challengeData = try decodeBase64(challengeResponse.challenge)
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(
            relyingPartyIdentifier: challengeResponse.rpId ?? "roua-trading.com"
        )

        let request = provider.createCredentialAssertionRequest(
            challenge: challengeData
        )

        // If the server specified allowed credentials, add them
        if let allowCredentials = challengeResponse.allowCredentials {
            request.allowedCredentials = allowCredentials.map { cred in
                let credData = Data(base64Encoded: cred.id) ?? Data()
                return ASAuthorizationPlatformPublicKeyCredentialDescriptor(
                    credentialID: credData
                )
            }
        }

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])

        let assertion: ASAuthorizationPlatformPublicKeyCredentialAssertion
        do {
            assertion = try await performAuthorization(controller: authorizationController)
        } catch {
            throw AuthError.assertionFailed(error)
        }

        // Step 3: Verify the assertion
        let verification = WebAuthnVerification(
            id: assertion.credentialID.base64EncodedString(),
            rawId: assertion.credentialID.base64EncodedString(),
            response: WebAuthnVerificationResponse(
                clientDataJSON: assertion.rawClientDataJSON.base64EncodedString(),
                attestationObject: nil,
                authenticatorData: assertion.rawAuthenticatorData.base64EncodedString(),
                signature: assertion.signature.base64EncodedString(),
                userHandle: assertion.userID?.base64EncodedString()
            ),
            type: "public-key"
        )

        do {
            let sessionInfo: SessionInfo = try await apiClient.request(
                .authVerify,
                body: verification
            )
            handleSuccessfulAuth(sessionInfo: sessionInfo)
        } catch {
            throw AuthError.verificationFailed(error.localizedDescription)
        }
    }

    // MARK: - OTP Authentication

    /// Sends a 6-digit OTP code to the given email address.
    ///
    /// The backend `/api/auth/otp/send` endpoint generates and stores an OTP
    /// that expires after 10 minutes. The code is sent via email in production,
    /// or logged to the server console in development.
    ///
    /// - Parameter email: The user's email address.
    func sendOtp(email: String) async throws {
        do {
            let response: OtpSendResponse = try await apiClient.request(
                .authOtpSend,
                body: OtpSendRequest(email: email)
            )
            guard response.success else {
                throw AuthError.verificationFailed(response.message ?? "فشل إرسال رمز التحقق")
            }
            logger.info("OTP sent to: \(email)")
        } catch let error as APIError {
            throw AuthError.verificationFailed(error.localizedDescription)
        }
    }

    /// Verifies the OTP code and authenticates the user.
    ///
    /// The backend `/api/auth/otp/verify` endpoint checks the 6-digit code.
    /// If valid, it creates a new session and returns the user data along
    /// with `roua_session` and `roua_refresh` cookies.
    ///
    /// - Parameters:
    ///   - email: The user's email address.
    ///   - otp: The 6-digit verification code.
    func verifyOtp(email: String, otp: String) async throws {
        do {
            let rawData = try await apiClient.requestRaw(
                .authOtpVerify,
                body: OtpVerifyRequest(email: email, otp: otp)
            )

            // Parse the response — backend returns { authenticated, user } or
            // wraps it in { success: true, data: { authenticated, user } }
            if let json = try? JSONSerialization.jsonObject(with: rawData) as? [String: Any] {
                // Try direct format first: { authenticated: true, user: {...} }
                var isAuthed = json["authenticated"] as? Bool ?? false
                var userData = json["user"] as? [String: Any]

                // Try wrapped format: { success: true, data: { authenticated: true, user: {...} } }
                if !isAuthed, let dataDict = json["data"] as? [String: Any] {
                    isAuthed = dataDict["authenticated"] as? Bool ?? false
                    userData = dataDict["user"] as? [String: Any]
                }

                guard isAuthed else {
                    let errorMsg = json["error"] as? String ?? json["message"] as? String
                    throw AuthError.verificationFailed(errorMsg ?? "رمز التحقق غير صحيح")
                }

                if let userData {
                    let userDataJson = try JSONSerialization.data(withJSONObject: userData)
                    let user = try JSONDecoder().decode(User.self, from: userDataJson)
                    self.currentUser = user
                    self.isAuthenticated = true
                    keychain.store(key: userKey, value: user)
                    logger.info("OTP login successful for user: \(user.email)")
                } else {
                    throw AuthError.verificationFailed("لم يتم استلام بيانات المستخدم")
                }
            } else {
                throw AuthError.verificationFailed("فشل تحليل الاستجابة")
            }
        } catch let error as AuthError {
            throw error
        } catch let error as APIError {
            throw AuthError.verificationFailed(error.localizedDescription)
        }
    }

    // MARK: - Google OAuth

    /// Initiates Google OAuth sign-in via `ASWebAuthenticationSession`.
    ///
    /// The browser-based flow redirects back to the app via the `roua://`
    /// custom URL scheme with a session token.
    ///
    /// - Important: On iOS 13+, `ASWebAuthenticationSession` requires a
    ///   `presentationContextProvider` to determine which window presents the
    ///   browser sheet. Without it, the session fails immediately with a
    ///   generic "operation couldn't be completed" error.
    func signInWithGoogle() async throws {
        let baseURL = AppConfig.webBaseURL + AppConfig.googleOAuthPath
        guard let url = URL(string: baseURL) else {
            throw AuthError.oauthFailed("Invalid OAuth URL")
        }

        let callbackURL: URL
        do {
            callbackURL = try await withCheckedThrowingContinuation { continuation in
                let session = ASWebAuthenticationSession(
                    url: url,
                    callbackURLScheme: AppConfig.authCallbackScheme
                ) { callbackURL, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else if let callbackURL {
                        continuation.resume(returning: callbackURL)
                    } else {
                        continuation.resume(throwing: AuthError.oauthFailed("No callback URL"))
                    }
                }

                // Note: prefersEphemeralWebBrowserSession should be false for OAuth
                // so cookies persist across the sign-in flow
                session.prefersEphemeralWebBrowserSession = false

                // iOS 13+ REQUIRES a presentationContextProvider — without it,
                // the session fails immediately with:
                //   "The operation couldn't be completed" (ASWebAuthenticationSessionError)
                session.presentationContextProvider = self.webAuthProvider

                // Retain the session strongly so it isn't deallocated while
                // the browser is open. The local variable alone would be released
                // as soon as this closure returns.
                self.webAuthSession = session

                session.start()
            }
        } catch {
            webAuthSession = nil
            if (error as? ASWebAuthenticationSessionError)?.code == .canceledLogin {
                throw AuthError.oauthCancelled
            }
            throw AuthError.oauthFailed(error.localizedDescription)
        }

        // Clear the strong reference now that the flow completed
        webAuthSession = nil

        // Extract session token from callback URL
        // The backend may return the token as a query parameter or as a fragment.
        // We try multiple parameter names and locations for robustness.
        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false) else {
            throw AuthError.oauthFailed("Invalid callback URL format")
        }

        // Try query items first, then fragment items
        let allItems = (components.queryItems ?? []) + (fragmentItems(from: components.fragment))

        // Try various token parameter names the backend might use
        let sessionToken = allItems.first(where: { $0.name == "token" })?.value
            ?? allItems.first(where: { $0.name == "session_token" })?.value
            ?? allItems.first(where: { $0.name == "sessionToken" })?.value
            ?? allItems.first(where: { $0.name == "access_token" })?.value

        // Also try extracting from the path component (e.g., roua://auth/callback/TOKEN_VALUE)
        let pathToken: String? = {
            let path = callbackURL.path
            // Strip leading "/" if present
            let trimmed = path.hasPrefix("/") ? String(path.dropFirst()) : path
            return trimmed.isEmpty ? nil : trimmed
        }()

        guard let finalToken = sessionToken ?? pathToken else {
            logger.error("OAuth callback URL: \(callbackURL.absoluteString)")
            throw AuthError.oauthFailed("No session token in OAuth callback")
        }

        // Store the session token
        keychain.store(key: AppConfig.sessionTokenKey, value: finalToken)
        logger.info("Session token stored from OAuth callback")

        // Also store the refresh token if provided
        if let refreshToken = allItems.first(where: { $0.name == "refresh" })?.value
            ?? allItems.first(where: { $0.name == "refresh_token" })?.value {
            keychain.store(key: AppConfig.refreshTokenKey, value: refreshToken)
            logger.info("Refresh token stored from OAuth callback")
        }

        try await validateAfterOAuth()
    }

    /// After a successful OAuth callback, validate the session to get user info.
    /// Uses /api/auth/me (Next.js proxy) instead of /api/auth/session.
    private func validateAfterOAuth() async throws {
        do {
            // The /auth/me endpoint returns { authenticated: true, user: {...} }
            let rawData = try await apiClient.requestRaw(.authSession)

            if let json = try? JSONSerialization.jsonObject(with: rawData) as? [String: Any],
               let isAuthed = json["authenticated"] as? Bool, isAuthed,
               let userData = json["user"] as? [String: Any] {
                let userDataJson = try JSONSerialization.data(withJSONObject: userData)
                let user = try JSONDecoder().decode(User.self, from: userDataJson)
                self.currentUser = user
                self.isAuthenticated = true
                keychain.store(key: userKey, value: user)
            } else {
                throw AuthError.sessionValidationFailed
            }
        } catch {
            throw AuthError.sessionValidationFailed
        }
    }

    // MARK: - Logout

    /// Logs the user out by deleting the session server-side and clearing local state.
    func logout() async {
        do {
            // Attempt server-side session deletion (best effort)
            let _: Data = try await apiClient.requestRaw(.authDeleteSession)
        } catch {
            logger.warning("Server-side logout failed (continuing with local cleanup): \(error)")
        }

        clearSession()
        logger.info("User logged out")
    }

    // MARK: - Token Refresh

    /// Refreshes the current session token.
    func refreshSession() async throws {
        do {
            let refreshed = try await apiClient.refreshSession()
            if !refreshed {
                throw AuthError.refreshFailed
            }
        } catch {
            clearSession()
            throw error
        }
    }

    // MARK: - Biometric Unlock

    /// Attempts to unlock the app using biometric authentication.
    ///
    /// This checks that a session exists in the Keychain and then
    /// prompts the user for biometric verification.
    ///
    /// - Returns: `true` if biometric authentication succeeded and a session exists.
    func biometricUnlock() async throws -> Bool {
        guard keychain.contains(key: AppConfig.sessionTokenKey) else {
            throw AuthError.notAuthenticated
        }

        guard AppConfig.enableBiometrics else {
            return true
        }

        let biometricAuth = BiometricAuth()
        let authenticated = try await biometricAuth.authenticate(reason: "Unlock Roua Trading")
        return authenticated
    }

    // MARK: - Session Management

    /// Deletes a specific session by ID.
    func deleteSession(id: String) async throws {
        let _: Data = try await apiClient.requestRaw(.authDeleteSessionById(id: id))
    }

    /// Deletes all sessions except the current one.
    func deleteAllSessions() async throws {
        let _: Data = try await apiClient.requestRaw(.authDeleteAllSessions)
    }

    /// Fetches all active sessions for the current user.
    func fetchSessions() async throws -> [SessionInfo] {
        try await apiClient.request(.authSessions)
    }

    // MARK: - Private Helpers

    /// Handles a successful authentication response by updating state and persisting data.
    private func handleSuccessfulAuth(sessionInfo: SessionInfo) {
        self.currentUser = sessionInfo.user
        self.isAuthenticated = true

        // Persist user and tokens
        keychain.store(key: userKey, value: sessionInfo.user)

        if let token = sessionInfo.sessionToken {
            keychain.store(key: AppConfig.sessionTokenKey, value: token)
        }
    }

    /// Clears all local session data.
    func clearSession() {
        keychain.delete(key: AppConfig.sessionTokenKey)
        keychain.delete(key: AppConfig.refreshTokenKey)
        keychain.delete(key: userKey)
        currentUser = nil
        isAuthenticated = false
    }

    /// Parses a URL fragment string (e.g., "token=abc&refresh=def") into query items.
    private func fragmentItems(from fragment: String?) -> [URLQueryItem] {
        guard let fragment, !fragment.isEmpty else { return [] }
        return fragment
            .components(separatedBy: "&")
            .compactMap { pair -> URLQueryItem? in
                let parts = pair.components(separatedBy: "=")
                guard parts.count == 2 else { return nil }
                return URLQueryItem(name: parts[0], value: parts[1].removingPercentEncoding ?? parts[1])
            }
    }

    /// Decodes a base64url-encoded string to `Data`.
    private func decodeBase64(_ string: String) throws -> Data {
        // Convert base64url to base64
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        // Pad with '=' if necessary
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }

        guard let data = Data(base64Encoded: base64) else {
            throw AuthError.challengeFailed("Invalid base64 encoding")
        }
        return data
    }

    /// Performs an `ASAuthorizationController` request using async/await.
    /// Generic delegate matches the continuation type to avoid CheckedContinuation invariance issues.
    private func performAuthorization<T: ASAuthorizationCredential>(
        controller: ASAuthorizationController
    ) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            let delegate = AuthorizationDelegate<T>(continuation: continuation)
            // Retain the delegate until the controller completes
            objc_setAssociatedObject(controller, "authDelegate", delegate, .OBJC_ASSOCIATION_RETAIN)
            delegate.controller = controller
            controller.delegate = delegate
            controller.performRequests()
        }
    }
}

// MARK: - OAuth Presentation Provider

/// Provides the key window as the presentation anchor for `ASWebAuthenticationSession`.
///
/// On iOS 13+, `ASWebAuthenticationSession` requires a `presentationContextProvider`
/// to determine which window presents the authentication browser sheet.
/// Without this provider, the session fails immediately with a generic error:
/// "The operation couldn't be completed (com.apple.AuthenticationServices.WebAuthenticationSession error)".
private class OAuthPresentationProvider: NSObject, ASWebAuthenticationPresentationContextProviding {

    /// Returns the key window of the active scene to present the browser sheet.
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Find the key window from the active UIWindowScene
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
            ?? scenes.first as? UIWindowScene
        return windowScene?.windows.first { $0.isKeyWindow } ?? UIWindow()
    }
}

// MARK: - Authorization Delegate

/// A delegate that bridges `ASAuthorizationController` callbacks to async/await.
/// Generic over the expected credential type to match CheckedContinuation's type parameter.
private class AuthorizationDelegate<T: ASAuthorizationCredential>: NSObject, ASAuthorizationControllerDelegate {

    private let continuation: CheckedContinuation<T, Error>
    weak var controller: ASAuthorizationController?

    init(continuation: CheckedContinuation<T, Error>) {
        self.continuation = continuation
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? T else {
            continuation.resume(throwing: AuthError.credentialCreationFailed(
                NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unexpected credential type"])
            ))
            return
        }
        continuation.resume(returning: credential)
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        continuation.resume(throwing: error)
    }
}
