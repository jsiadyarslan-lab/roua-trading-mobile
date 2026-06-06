// ============================================================================
// AuthModels.swift
// RouaTrading — Models for WebAuthn passkey authentication, session
// management, and user identity.
//
// The backend uses WebAuthn with session cookies (roua_session, roua_refresh)
// and also accepts Authorization Bearer headers.
// ============================================================================

import Foundation

// MARK: - User

/// The authenticated user's profile.
struct User: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let email: String
    let displayName: String
    let tier: UserTier
    let avatarUrl: String?
    let createdAt: String

    // ---- CodingKeys (backend may send 'name' instead of 'displayName') ----
    private enum CodingKeys: String, CodingKey {
        case id, email, displayName, tier
        case name
        case avatarUrl = "avatarUrl"
        case createdAt
    }

    /// Fallback initializer that accepts 'name' as an alias for 'displayName'.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        tier = try container.decodeIfPresent(UserTier.self, forKey: .tier) ?? .free
        avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt) ?? ""
        // Accept 'displayName' or fall back to 'name' for backend compatibility
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
            ?? container.decodeIfPresent(String.self, forKey: .name)
            ?? email
    }

    /// Custom encode — only emit stored properties (not the 'name' alias).
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(tier, forKey: .tier)
        try container.encodeIfPresent(avatarUrl, forKey: .avatarUrl)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
    }

    // Direct memberwise init for programmatic creation
    init(id: String, email: String, displayName: String, tier: UserTier = .free, avatarUrl: String? = nil, createdAt: String = "") {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.tier = tier
        self.avatarUrl = avatarUrl
        self.createdAt = createdAt
    }

    // ---- Hashable (email-based identity) ----
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: User, rhs: User) -> Bool { lhs.id == rhs.id }

    // ---- Computed helpers ----

    /// Short display name – falls back to email prefix.
    var shortName: String {
        displayName.isEmpty ? email.components(separatedBy: "@").first ?? email : displayName
    }

    /// Initials for avatar placeholders.
    var initials: String {
        let parts = displayName.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].first ?? "?")\(parts[1].first ?? "?")"
        }
        return String(displayName.first ?? email.first ?? "?")
    }
}

// MARK: - Auth Session

/// A single browser / device session tied to the user.
struct AuthSession: Codable, Identifiable, Hashable {
    let id: String
    let device: String?
    let ipAddress: String?
    let maskedIp: String?
    let userAgent: String?
    let createdAt: String
    let expiresAt: String
    let lastActive: String

    // ---- Computed helpers ----

    /// Whether the session appears to be a mobile device.
    var isMobile: Bool {
        guard let ua = userAgent?.lowercased() else { return false }
        return ua.contains("iphone") || ua.contains("ipad") || ua.contains("android")
    }

    /// Friendly device label – falls back to "Unknown device".
    var deviceLabel: String {
        device ?? "Unknown device"
    }
}

// MARK: - Auth Verify Response

/// Returned after a successful WebAuthn authentication ceremony.
struct AuthVerifyResponse: Codable {
    let success: Bool
    let user: User?
}

// MARK: - Session Response

/// Returned by the `GET /auth/session` endpoint to check current auth state.
struct SessionResponse: Codable {
    let authenticated: Bool
    let user: User?
}

// MARK: - WebAuthn Registration Options

/// PublicKeyCredentialCreationOptions sent by the server before passkey
/// registration.  The raw types (e.g. `[UInt8]`) are intentionally `Data`
/// in this model – the WebAuthn bridge layer handles base64 conversion.
struct WebAuthnRegistrationOptions: Codable {
    let challenge: String
    let rp: WebAuthnRelyingParty
    let user: WebAuthnUserEntity
    let pubKeyCredParams: [WebAuthnCredentialParam]
    let timeout: Int?
    let attestation: String?
    let excludeCredentials: [WebAuthnCredentialDescriptor]?

    // ---- Nested types ----

    struct WebAuthnRelyingParty: Codable, Hashable {
        let name: String
        let id: String
    }

    struct WebAuthnUserEntity: Codable, Hashable {
        let id: String
        let name: String
        let displayName: String
    }

    struct WebAuthnCredentialParam: Codable, Hashable {
        let type: String
        let alg: Int
    }

    struct WebAuthnCredentialDescriptor: Codable, Hashable {
        let type: String
        let id: String
        let transports: [String]?
    }
}

// MARK: - WebAuthn Authentication Options

/// PublicKeyCredentialRequestOptions sent by the server before passkey
/// authentication.
struct WebAuthnAuthenticationOptions: Codable {
    let challenge: String
    let rpId: String?
    let allowCredentials: [WebAuthnRegistrationOptions.WebAuthnCredentialDescriptor]?
    let timeout: Int?
    let userVerification: String?
}
