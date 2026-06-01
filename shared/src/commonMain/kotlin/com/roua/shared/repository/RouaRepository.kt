package com.roua.shared.repository

import com.roua.shared.api.*
import io.ktor.client.*
import io.ktor.client.call.*
import io.ktor.client.engine.*
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.client.request.*
import io.ktor.client.statement.*
import io.ktor.http.*
import io.ktor.serialization.kotlinx.json.*
import kotlinx.serialization.json.Json

expect class HttpClientEngineFactory() {
    fun create(): HttpClientEngine
}

class RouaRepository(engineFactory: HttpClientEngineFactory) {
    
    private val client = HttpClient(engineFactory.create()) {
        install(ContentNegotiation) {
            json(Json {
                ignoreUnknownKeys = true
                isLenient = true
            })
        }
    }
    
    private var sessionToken: String? = null
    
    fun setSessionToken(token: String?) {
        sessionToken = token
    }
    
    // MARK: - Auth
    suspend fun getSession(): ApiResult<AuthUser> = safeRequest {
        client.get("${RouaConfig.BASE_URL}/auth/session").body()
    }
    
    suspend fun verify(credential: String, email: String): ApiResult<AuthUser> = safeRequest {
        client.post("${RouaConfig.BASE_URL}/auth/verify") {
            contentType(ContentType.Application.Json)
            setBody(mapOf("credential" to credential, "email" to email))
        }.body()
    }
    
    // MARK: - Trading
    suspend fun getPortfolio(): ApiResult<PortfolioSummary> = safeRequest {
        client.get("${RouaConfig.BASE_URL}/trading/v2/portfolio") { authHeader() }.body()
    }
    
    suspend fun getPositions(): ApiResult<List<Position>> = safeRequest {
        client.get("${RouaConfig.BASE_URL}/trading/v2/positions") { authHeader() }.body()
    }
    
    suspend fun getQuote(symbol: String): ApiResult<Quote> = safeRequest {
        client.get("${RouaConfig.BASE_URL}/exchange/quote/$symbol") { authHeader() }.body()
    }
    
    suspend fun placeOrder(request: Map<String, Any?>): ApiResult<OrderResponse> = safeRequest {
        client.post("${RouaConfig.BASE_URL}/trading/v2/orders") {
            authHeader()
            contentType(ContentType.Application.Json)
            setBody(request)
        }.body()
    }
    
    // MARK: - AI
    suspend fun analyzeAI(prompt: String, language: String = "ar"): ApiResult<Map<String, Any?>> = safeRequest {
        client.post("${RouaConfig.BASE_URL}/ai/analyze") {
            authHeader()
            contentType(ContentType.Application.Json)
            setBody(mapOf("prompt" to prompt, "language" to language))
        }.body()
    }
    
    // MARK: - Scanner
    suspend fun scanMarket(category: String? = null): ApiResult<List<Map<String, Any?>>> = safeRequest {
        client.get("${RouaConfig.BASE_URL}/scanner/scan") {
            authHeader()
            category?.let { parameter("category", it) }
        }.body()
    }
    
    // MARK: - Agent
    suspend fun startAgent(strategy: String): ApiResult<AgentStatus> = safeRequest {
        client.post("${RouaConfig.BASE_URL}/agent/trader/start") {
            authHeader()
            contentType(ContentType.Application.Json)
            setBody(mapOf("strategy" to strategy))
        }.body()
    }
    
    suspend fun stopAgent(): ApiResult<AgentStatus> = safeRequest {
        client.post("${RouaConfig.BASE_URL}/agent/trader/stop") { authHeader() }.body()
    }
    
    // MARK: - Helpers
    private fun HttpRequestBuilder.authHeader() {
        sessionToken?.let {
            header("Authorization", "Bearer $it")
            header(RouaConfig.SESSION_HEADER, it)
        }
    }
    
    private inline fun <reified T> safeRequest(block: () -> T): ApiResult<T> {
        return try {
            ApiResult.Success(block())
        } catch (e: ClientRequestException) {
            if (e.response.status == HttpStatusCode.Unauthorized) ApiResult.Unauthorized
            else ApiResult.Error(e.response.status.value, e.message)
        } catch (_: Exception) {
            ApiResult.NetworkError
        }
    }
}
