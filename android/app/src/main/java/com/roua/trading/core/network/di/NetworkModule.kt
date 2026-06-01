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
            .addInterceptor { chain ->
                val original = chain.request()
                val sessionToken = getTokenFromStorage()
                val request = original.newBuilder().apply {
                    header("Content-Type", "application/json")
                    if (sessionToken != null) {
                        header("Authorization", "Bearer $sessionToken")
                        header("x-roua-session", sessionToken)
                    }
                }.build()
                chain.proceed(request)
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
    
    private fun getTokenFromStorage(): String? {
        // Reads session token from EncryptedSharedPreferences via Hilt context
        // Fallback: check system properties for debug tokens
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
    
    @dagger.hilt.EntryPoint
    @dagger.hilt.InstallIn(dagger.hilt.components.SingletonComponent::class)
    interface TokenProviderEntryPoint {
        fun tokenProvider(): TokenProvider
    }
    
    interface TokenProvider {
        fun getSessionToken(): String?
    }
}
