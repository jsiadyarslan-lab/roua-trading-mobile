package com.roua.trading.core.network.di

import com.roua.trading.core.network.RouaApiService
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import kotlinx.serialization.json.Json
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.kotlinx.serialization.asConverterFactory
import okhttp3.MediaType.Companion.toMediaType
import java.util.concurrent.TimeUnit
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {
    
    private const val BASE_URL = "https://roua-trading-production.up.railway.app/api/"
    
    @Provides
    @Singleton
    fun provideJson(): Json = Json {
        ignoreUnknownKeys = true
        coerceInputValues = true
        isLenient = true
    }
    
    @Provides
    @Singleton
    fun provideOkHttpClient(): OkHttpClient {
        return OkHttpClient.Builder()
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .writeTimeout(30, TimeUnit.SECONDS)
            .addInterceptor(HttpLoggingInterceptor().apply {
                level = HttpLoggingInterceptor.Level.BODY
            })
            // Auth + Platform headers interceptor
            .addInterceptor { chain ->
                val original = chain.request()
                val sessionToken = getTokenFromStorage()
                val refreshToken = getRefreshTokenFromStorage()
                val request = original.newBuilder().apply {
                    header("Content-Type", "application/json")
                    header("X-Platform", "android")  // Required for mobile token-in-body responses
                    if (sessionToken != null) {
                        header("Authorization", "Bearer $sessionToken")
                        header("x-roua-session", sessionToken)
                    }
                    if (refreshToken != null) {
                        header("x-roua-refresh", refreshToken)
                    }
                }.build()
                chain.proceed(request)
            }
            // Auto token refresh interceptor — on 401, try refresh then retry
            .authenticator { route, response ->
                val sessionToken = getTokenFromStorage() ?: return@authenticator null
                val refreshToken = getRefreshTokenFromStorage() ?: return@authenticator null
                
                // Don't try to refresh if this is already a refresh request
                if (response.request.url.encodedPath.contains("auth/refresh")) {
                    return@authenticator null
                }
                
                // Don't try more than once
                if (responseCount(response) >= 3) {
                    return@authenticator null
                }
                
                // Attempt refresh via the /api/auth/refresh endpoint
                try {
                    val refreshRequest = okhttp3.Request.Builder()
                        .url("${BASE_URL}auth/refresh")
                        .post(okhttp3.RequestBody.create(null, ByteArray(0)))
                        .header("Authorization", "Bearer $refreshToken")
                        .header("x-roua-refresh", refreshToken)
                        .header("x-roua-session", sessionToken)
                        .header("X-Platform", "android")
                        .build()
                    
                    val refreshResponse = response.request.newBuilder().build()
                    val client = response.call.client
                    val refreshCall = client.newCall(refreshRequest)
                    val refreshResult = refreshCall.execute()
                    
                    if (refreshResult.isSuccessful) {
                        val body = refreshResult.body?.string() ?: return@authenticator null
                        val json = kotlinx.serialization.json.Json { ignoreUnknownKeys = true }
                        val parsed = json.decodeFromString<RefreshResponse>(body)
                        
                        if (parsed.refreshed == true && parsed.data != null) {
                            // Save new tokens
                            saveTokensToStorage(parsed.data.token, parsed.data.refresh)
                            
                            // Retry original request with new token
                            return@authenticator response.request.newBuilder()
                                .header("Authorization", "Bearer ${parsed.data.token}")
                                .header("x-roua-session", parsed.data.token)
                                .build()
                        }
                    }
                    null
                } catch (e: Exception) {
                    null
                }
            }
            .build()
    }
    
    @Provides
    @Singleton
    fun provideRetrofit(okHttpClient: OkHttpClient, json: Json): Retrofit {
        return Retrofit.Builder()
            .baseUrl(BASE_URL)
            .client(okHttpClient)
            .addConverterFactory(json.asConverterFactory("application/json".toMediaType()))
            .build()
    }
    
    @Provides
    @Singleton
    fun provideApiService(retrofit: Retrofit): RouaApiService {
        return retrofit.create(RouaApiService::class.java)
    }
    
    private fun responseCount(response: okhttp3.Response): Int {
        var count = 1
        var prior = response.priorResponse
        while (prior != null) {
            count++
            prior = prior.priorResponse
        }
        return count
    }
    
    private fun getTokenFromStorage(): String? {
        return try {
            val context = dagger.hilt.android.EntryPointAccessors.fromApplication(
                android.app.Application::class.java,
                TokenProviderEntryPoint::class.java
            )
            context.tokenProvider().getSessionToken()
        } catch (e: Exception) {
            null
        }
    }
    
    private fun getRefreshTokenFromStorage(): String? {
        return try {
            val context = dagger.hilt.android.EntryPointAccessors.fromApplication(
                android.app.Application::class.java,
                TokenProviderEntryPoint::class.java
            )
            context.tokenProvider().getRefreshToken()
        } catch (e: Exception) {
            null
        }
    }
    
    private fun saveTokensToStorage(sessionToken: String, refreshToken: String) {
        try {
            val context = dagger.hilt.android.EntryPointAccessors.fromApplication(
                android.app.Application::class.java,
                TokenProviderEntryPoint::class.java
            )
            context.tokenProvider().saveTokens(sessionToken, refreshToken)
        } catch (_: Exception) {}
    }
    
    @dagger.hilt.EntryPoint
    @dagger.hilt.InstallIn(dagger.hilt.components.SingletonComponent::class)
    interface TokenProviderEntryPoint {
        fun tokenProvider(): TokenProvider
    }
    
    interface TokenProvider {
        fun getSessionToken(): String?
        fun getRefreshToken(): String?
        fun saveTokens(sessionToken: String, refreshToken: String)
    }
    
    // Models for refresh response parsing
    @kotlinx.serialization.Serializable
    data class RefreshResponse(
        val refreshed: Boolean? = null,
        val data: RefreshData? = null
    )
    
    @kotlinx.serialization.Serializable
    data class RefreshData(
        val token: String,
        val refresh: String
    )
}
