import Foundation
import AuthenticationServices
import CryptoKit

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
            let sessionInfo: SessionInfo = try await apiClient.request(.authSession)
            self.currentUser = sessionInfo.user
            self.isAuthenticated = true
            logger.info("Session validated for user: \(sessionInfo.user.email)")

            // Persist user object
            keychain.store(key: userKey, value: sessionInfo.user)
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

        let request = provider.createCredentialRequest(
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
                clientDataJSON: credential.clientDataJSON.base64EncodedString(),
                attestationObject: credential.attestationObject?.base64EncodedString(),
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

        let request = provider.getCredentialAssertionRequest(
            challenge: challengeData
        )

        // If the server specified allowed credentials, add them
        if let allowCredentials = challengeResponse.allowCredentials {
            request.allowedCredentials = allowCredentials.map { cred in
                let credData = Data(base64Encoded: cred.id) ?? Data()
                return ASAuthorizationPlatformPublicKeyCredentialDescriptor(
                    credentialID: credData,
                    transports: cred.transports?.compactMap { transport in
                        ASAuthorizationSecurityKeyCredentialTransport(rawValue: transport)
                    } ?? []
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
                clientDataJSON: assertion.clientDataJSON.base64EncodedString(),
                attestationObject: nil,
                authenticatorData: assertion.authenticatorData.base64EncodedString(),
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

    // MARK: - Google OAuth

    /// Initiates Google OAuth sign-in via `ASWebAuthenticationSession`.
    ///
    /// The browser-based flow redirects back to the app via the `roua://`
    /// custom URL scheme with a session token.
    ///
    /// - Parameter windowProvider: An object that can provide the presenting window.
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
                session.start()
            }
        } catch {
            if (error as? ASWebAuthenticationSessionError)?.code == .canceledLogin {
                throw AuthError.oauthCancelled
            }
            throw AuthError.oauthFailed(error.localizedDescription)
        }

        // Extract session token from callback URL
        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            throw AuthError.oauthFailed("Invalid callback URL format")
        }

        let sessionToken = queryItems.first(where: { $0.name == "token" })?.value
            ?? queryItems.first(where: { $0.name == "session_token" })?.value

        guard let sessionToken else {
            throw AuthError.oauthFailed("No session token in OAuth callback")
        }

        // Store the token and validate the session
        keychain.store(key: AppConfig.sessionTokenKey, value: sessionToken)
        try await validateAfterOAuth()
    }

    /// After a successful OAuth callback, validate the session to get user info.
    private func validateAfterOAuth() async throws {
        do {
            let sessionInfo: SessionInfo = try await apiClient.request(.authSession)
            handleSuccessfulAuth(sessionInfo: sessionInfo)
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
    private func clearSession() {
        keychain.delete(key: AppConfig.sessionTokenKey)
        keychain.delete(key: AppConfig.refreshTokenKey)
        keychain.delete(key: userKey)
        currentUser = nil
        isAuthenticated = false
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
    private func performAuthorization<T: ASAuthorizationCredential>(
        controller: ASAuthorizationController
    ) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            let delegate = AuthorizationDelegate(continuation: continuation)
            // Retain the delegate until the controller completes
            objc_setAssociatedObject(controller, "authDelegate", delegate, .OBJC_ASSOCIATION_RETAIN)
            delegate.controller = controller
            controller.delegate = delegate
            controller.performRequests()
        }
    }
}

// MARK: - Authorization Delegate

/// A delegate that bridges `ASAuthorizationController` callbacks to async/await.
private class AuthorizationDelegate: NSObject, ASAuthorizationControllerDelegate {

    private let continuation: CheckedContinuation<ASAuthorizationCredential, Error>
    weak var controller: ASAuthorizationController?

    init(continuation: CheckedContinuation<ASAuthorizationCredential, Error>) {
        self.continuation = continuation
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        continuation.resume(returning: authorization.credential)
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        continuation.resume(throwing: error)
    }
}
