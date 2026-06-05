import Foundation
import LocalAuthentication

// MARK: - Biometric Auth Error

/// Errors specific to biometric authentication.
enum BiometricAuthError: LocalizedError {
    /// Biometric authentication is not available on this device.
    case notAvailable

    /// Biometric authentication is not enrolled (no Face ID / Touch ID set up).
    case notEnrolled

    /// The device is locked and biometric authentication is locked out.
    case lockedOut

    /// The user cancelled the biometric prompt.
    case cancelled

    /// The user chose the fallback (passcode) option.
    case fallbackSelected

    /// An unknown biometric error occurred.
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Biometric authentication is not available on this device."
        case .notEnrolled:
            return "No Face ID or Touch ID enrolled. Please set up biometrics in Settings."
        case .lockedOut:
            return "Biometric authentication is locked out. Please unlock with passcode first."
        case .cancelled:
            return "Biometric authentication was cancelled."
        case .fallbackSelected:
            return "Passcode fallback selected."
        case .unknown(let error):
            return "Biometric authentication error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Biometric Type

/// The type of biometric authentication available on the device.
enum BiometricType {
    /// Face ID is available.
    case faceID

    /// Touch ID is available.
    case touchID

    /// No biometric authentication is available.
    case none
}

// MARK: - Biometric Auth

/// Provides biometric authentication using Face ID or Touch ID.
///
/// Usage:
/// ```swift
/// let biometricAuth = BiometricAuth()
/// let authenticated = try await biometricAuth.authenticate(reason: "Unlock the app")
/// ```
///
/// - Note: Ensure `NSFaceIDUsageDescription` is present in `Info.plist` for Face ID.
struct BiometricAuth {

    // MARK: - Device Capability

    /// Returns the type of biometric authentication available on the device.
    static var biometricType: BiometricType {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        default:
            return .none
        }
    }

    /// Whether the device supports biometric authentication.
    static var isAvailable: Bool {
        biometricType != .none
    }

    /// A user-friendly name for the biometric type ("Face ID" or "Touch ID").
    static var displayName: String {
        switch biometricType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .none: return "Biometrics"
        }
    }

    // MARK: - Authentication

    /// Evaluates biometric authentication with the given reason.
    ///
    /// - Parameter reason: The localized reason displayed in the biometric prompt.
    /// - Returns: `true` if authentication succeeded.
    /// - Throws: `BiometricAuthError` on failure.
    func authenticate(reason: String) async throws -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Enter Passcode"
        context.localizedFallbackTitle = "Use Passcode"

        var error: NSError?

        // Check capability first
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let laError = error as? LAError {
                switch laError.code {
                case .biometryNotAvailable:
                    throw BiometricAuthError.notAvailable
                case .biometryNotEnrolled:
                    throw BiometricAuthError.notEnrolled
                case .biometryLockout:
                    throw BiometricAuthError.lockedOut
                @unknown default:
                    throw BiometricAuthError.unknown(laError)
                }
            }
            throw BiometricAuthError.notAvailable
        }

        // Evaluate
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return success
        } catch let laError as LAError {
            switch laError.code {
            case .authenticationFailed:
                throw BiometricAuthError.cancelled
            case .userCancel:
                throw BiometricAuthError.cancelled
            case .userFallback:
                throw BiometricAuthError.fallbackSelected
            case .biometryLockout, .touchIDLockout:
                throw BiometricAuthError.lockedOut
            case .biometryNotEnrolled, .touchIDNotEnrolled:
                throw BiometricAuthError.notEnrolled
            case .biometryNotAvailable, .touchIDNotAvailable:
                throw BiometricAuthError.notAvailable
            case .appCancel, .systemCancel:
                throw BiometricAuthError.cancelled
            case .passcodeNotSet:
                throw BiometricAuthError.notAvailable
            case .notInteractive:
                throw BiometricAuthError.cancelled
            case .invalidContext:
                throw BiometricAuthError.unknown(laError)
            @unknown default:
                throw BiometricAuthError.unknown(laError)
            }
        }
    }

    /// Evaluates biometric authentication with the device owner policy
    /// (falls back to passcode if biometrics fail).
    ///
    /// - Parameter reason: The localized reason displayed in the prompt.
    /// - Returns: `true` if authentication succeeded.
    func authenticateWithFallback(reason: String) async throws -> Bool {
        let context = LAContext()

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            throw BiometricAuthError.notAvailable
        }

        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
        } catch {
            throw BiometricAuthError.unknown(error)
        }
    }
}
