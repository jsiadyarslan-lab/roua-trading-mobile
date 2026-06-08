package com.roua.trading.core.auth

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import com.roua.trading.core.network.di.NetworkModule
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Secure session token storage using EncryptedSharedPreferences.
 * Implements NetworkModule.TokenProvider so the OkHttpClient interceptor
 * can read the current session token without direct Hilt dependency.
 */
@Singleton
class SessionManager @Inject constructor(
    @ApplicationContext context: Context
) : NetworkModule.TokenProvider {

    private val masterKey = MasterKey.Builder(context)
        .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
        .build()

    private val prefs: SharedPreferences = EncryptedSharedPreferences.create(
        context,
        "roua_secure_session",
        masterKey,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )

    companion object {
        private const val KEY_SESSION_TOKEN = "roua_session_token"
        private const val KEY_REFRESH_TOKEN = "roua_refresh_token"
        private const val KEY_USER_EMAIL = "roua_user_email"
        private const val KEY_USER_TIER = "roua_user_tier"
    }

    // --- TokenProvider implementation (used by NetworkModule interceptor) ---
    override fun getSessionToken(): String? = prefs.getString(KEY_SESSION_TOKEN, null)
    override fun getRefreshToken(): String? = prefs.getString(KEY_REFRESH_TOKEN, null)

    // --- Public API ---
    fun saveSession(token: String, refreshToken: String? = null, email: String? = null, tier: String? = null) {
        prefs.edit().apply {
            putString(KEY_SESSION_TOKEN, token)
            refreshToken?.let { putString(KEY_REFRESH_TOKEN, it) }
            email?.let { putString(KEY_USER_EMAIL, it) }
            tier?.let { putString(KEY_USER_TIER, it) }
            apply()
        }
    }

    fun saveRefreshToken(refreshToken: String) {
        prefs.edit().putString(KEY_REFRESH_TOKEN, refreshToken).apply()
    }

    fun clearSession() {
        prefs.edit().clear().apply()
    }

    // --- TokenProvider saveTokens (used by NetworkModule authenticator) ---
    override fun saveTokens(sessionToken: String, refreshToken: String) {
        prefs.edit().apply {
            putString(KEY_SESSION_TOKEN, sessionToken)
            putString(KEY_REFRESH_TOKEN, refreshToken)
            apply()
        }
    }

    fun getUserEmail(): String? = prefs.getString(KEY_USER_EMAIL, null)
    fun getUserTier(): String? = prefs.getString(KEY_USER_TIER, null)
    fun isLoggedIn(): Boolean = !getSessionToken().isNullOrEmpty()
}
