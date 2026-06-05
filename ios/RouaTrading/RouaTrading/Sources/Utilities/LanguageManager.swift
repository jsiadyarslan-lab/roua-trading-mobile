// =============================================================================
// LanguageManager.swift — Roua Trading · Language / Locale Manager
// =============================================================================
// Manages app-wide language preference (Arabic / English).
// Persists the choice in UserDefaults and publishes changes so SwiftUI
// views can react immediately.
//
// Usage:
//   Inject as @EnvironmentObject at the root, then read/switch:
//     @EnvironmentObject private var lang: LanguageManager
//     lang.isArabic  // → true / false
//     lang.toggle()  // switches language
// =============================================================================

import SwiftUI

// MARK: - Language Manager

/// Manages the app's display language (Arabic or English).
///
/// The selected language is persisted in `UserDefaults` under the key
/// `"roua_app_language"`. On first launch the default is Arabic.
@MainActor
final class LanguageManager: ObservableObject {

    // MARK: - Published

    /// The currently active language code ("ar" or "en").
    @Published var currentLanguage: AppLanguage

    // MARK: - Init

    init() {
        let stored = UserDefaults.standard.string(forKey: Self.storageKey)
        self.currentLanguage = AppLanguage(rawValue: stored ?? "ar") ?? .arabic
    }

    // MARK: - Public API

    /// Whether the current language is Arabic.
    var isArabic: Bool { currentLanguage == .arabic }

    /// Whether the current language is English.
    var isEnglish: Bool { currentLanguage == .english }

    /// The SwiftUI `Locale` matching the current language.
    var locale: Locale { Locale(identifier: currentLanguage.rawValue) }

    /// The layout direction matching the current language.
    var layoutDirection: LayoutDirection {
        currentLanguage == .arabic ? .rightToLeft : .leftToRight
    }

    /// Toggles between Arabic and English.
    func toggle() {
        currentLanguage = currentLanguage == .arabic ? .english : .arabic
        persist()
    }

    /// Sets the language explicitly.
    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
        persist()
    }

    // MARK: - Persistence

    private static let storageKey = "roua_app_language"

    private func persist() {
        UserDefaults.standard.set(currentLanguage.rawValue, forKey: Self.storageKey)
    }
}

// MARK: - Language Enum

enum AppLanguage: String, CaseIterable, Identifiable {
    case arabic = "ar"
    case english = "en"

    var id: String { rawValue }

    /// Display name in its own language.
    var nativeName: String {
        switch self {
        case .arabic:  return "العربية"
        case .english: return "English"
        }
    }

    /// Display name in the OTHER language (for the picker label).
    var otherName: String {
        switch self {
        case .arabic:  return "Arabic"
        case .english: return "العربية"
        }
    }
}
