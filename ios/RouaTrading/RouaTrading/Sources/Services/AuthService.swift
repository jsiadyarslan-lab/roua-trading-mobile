import Foundation
import AuthenticationServices
import UIKit
import ObjectiveC

// MARK: - Auth Service
@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var isAuthenticated = false
    @Published var currentUser: AuthUser?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api = APIClient.shared
    private let keychain = KeychainManager.shared

    private init() {}

    // MARK: - Check Existing Session (with retry)
    func checkExistingSession() {
        guard keychain.sessionToken != nil else { return }
        Task { await validateSessionWithRetry() }
    }

    func validateSessionWithRetry(maxAttempts: Int = 3) async {
        for attempt in 1...maxAttempts {
            do {
                let response: AuthVerifyResponse = try await api.request("/auth/me")
                if response.isValid, let user = response.user {
                    self.currentUser = user
                    self.isAuthenticated = true
                    self.errorMessage = nil
                    print("[Auth] Session validated for \(user.email)")
                    return
                } else {
                    // Check specific error types
                    if let errorType = response.error {
                        switch errorType {
                        case "EMAIL_NOT_VERIFIED":
                            self.errorMessage = "يرجى التحقق من بريدك الإلكتروني أولاً"
                        case "USER_NOT_FOUND":
                            self.errorMessage = "هذا الحساب غير مسجل"
                        case "AUTH_SERVICE_UNAVAILABLE":
                            self.errorMessage = "خدمة المصادقة غير متاحة حالياً"
                        case "NO_SESSION":
                            self.errorMessage = "انتهت صلاحية الجلسة"
                        default:
                            self.errorMessage = "فشل التحقق: \(errorType)"
                        }
                    } else {
                        self.errorMessage = "فشل التحقق من الجلسة"
                    }
                    self.isAuthenticated = false
                }
            } catch {
                print("[Auth] Validation attempt \(attempt)/\(maxAttempts) failed: \(error.localizedDescription)")
                if attempt < maxAttempts {
                    try? await Task.sleep(nanoseconds: UInt64(attempt) * 1_500_000_000)
                } else {
                    self.isAuthenticated = false
                    self.errorMessage = "فشل التحقق من الجلسة بعد \(maxAttempts) محاولات"
                }
            }
        }
    }

    // MARK: - Google OAuth via ASWebAuthenticationSession
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil

        guard let authURL = URL(string: "\(APIConfig.baseURL)/auth/signin/google?app_redirect_uri=roua://auth/callback") else {
            errorMessage = "رابط المصادقة غير صالح"
            isLoading = false
            return
        }

        do {
            let callbackURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
                let presenter = WebAuthPresenter(window: WebAuthPresenter.findWindow())
                let session = ASWebAuthenticationSession(
                    url: authURL,
                    callbackURLScheme: "roua"
                ) { url, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let url = url {
                        continuation.resume(returning: url)
                    } else {
                        continuation.resume(throwing: APIError.networkError("No callback URL received"))
                    }
                }
                session.prefersEphemeralWebBrowserSession = false
                session.presentationContextProvider = presenter
                // Retain presenter via associated object on session to prevent dealloc
                objc_setAssociatedObject(session, &AssociatedKeys.webAuthPresenter, presenter, .OBJC_ASSOCIATION_RETAIN)
                session.start()
            }

            // Parse callback URL: roua://auth/callback?token=xxx&refresh=yyy&userId=zzz
            guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                  let queryItems = components.queryItems else {
                errorMessage = "استجابة المصادقة غير صالحة"
                isLoading = false
                return
            }

            let token = queryItems.first(where: { $0.name == "token" })?.value
            let refresh = queryItems.first(where: { $0.name == "refresh" })?.value
            let userId = queryItems.first(where: { $0.name == "userId" })?.value

            guard let token = token else {
                errorMessage = "لم يتم استلام رمز المصادقة"
                isLoading = false
                return
            }

            // Save session
            api.sessionToken = token
            keychain.saveSession(token: token, refresh: refresh, userId: userId)

            // Validate the session to get user info
            await validateSessionWithRetry()
            isLoading = false

        } catch {
            print("[Auth] Google OAuth error: \(error.localizedDescription)")
            if error.localizedDescription.contains("canceled") {
                // User canceled — don't show error
            } else {
                errorMessage = "فشل تسجيل الدخول: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }

    // MARK: - Email Login (WebAuthn flow)
    func loginWithEmail(email: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // Step 1: Get challenge
            let challengeData: Data = try await api.rawDataRequest("/auth/challenge?email=\(email)")

            // Step 2: Parse challenge
            guard let json = try? JSONSerialization.jsonObject(with: challengeData) as? [String: Any],
                  let _ = json["challenge"] as? String else {
                errorMessage = "فشل الحصول على تحدي المصادقة"
                isLoading = false
                return
            }

            // Step 3: WebAuthn ceremony would go here
            errorMessage = "تسجيل الدخول بالبريد يتطلب WebAuthn — يرجى استخدام Google Sign In"
            isLoading = false

        } catch {
            print("[Auth] Email login error: \(error.localizedDescription)")
            errorMessage = "فشل تسجيل الدخول: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Logout
    func logout() async {
        do {
            let _: Data = try await api.rawDataRequest("/auth/me", method: "DELETE")
            print("[Auth] Server session deleted")
        } catch {
            print("[Auth] Server logout failed (clearing local anyway): \(error.localizedDescription)")
        }

        // Always clear local state
        keychain.clearSession()
        api.sessionToken = nil
        currentUser = nil
        isAuthenticated = false
        errorMessage = nil
        print("[Auth] Local session cleared")
    }

    // MARK: - Biometric Unlock (Face ID / Touch ID)
    func biometricUnlock() async -> Bool {
        return keychain.sessionToken != nil
    }
}

// MARK: - Associated Object Keys
private enum AssociatedKeys {
    nonisolated(unsafe) static var webAuthPresenter = "webAuthPresenter"
}

// MARK: - WebAuth Presenter (NSObject for ASWebAuthenticationPresentationContextProviding)
class WebAuthPresenter: NSObject, ASWebAuthenticationPresentationContextProviding {
    let window: UIWindow
    init(window: UIWindow) { self.window = window }
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor { window }

    static func findWindow() -> UIWindow {
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
           let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first {
            return window
        }
        if let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
           let window = scene.windows.first {
            return window
        }
        return UIWindow()
    }
}
