package com.roua.trading.features.scanner

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.roua.trading.core.network.RouaApiService
import com.roua.trading.core.network.model.HeatmapItem
import com.roua.trading.core.network.model.NewsArticle
import com.roua.trading.core.network.model.ScanResult
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

enum class ScannerTab(val label: String) {
    SCANNER("Scanner"),
    HEATMAP("Heatmap"),
    NEWS("News")
}

enum class SentimentFilter(val label: String) {
    ALL("All"),
    POSITIVE("Positive"),
    NEGATIVE("Negative"),
    NEUTRAL("Neutral")
}

data class ScannerUiState(
    val selectedTab: ScannerTab = ScannerTab.SCANNER,
    val isLoading: Boolean = false,
    val error: String? = null,

    // Scanner
    val results: List<ScanResult> = emptyList(),
    val selectedCategory: String = "ALL",
    val selectedTimeframe: String = "1h",

    // Heatmap
    val heatmapItems: List<HeatmapItem> = emptyList(),
    val heatmapCategory: String = "ALL",

    // News
    val news: List<NewsArticle> = emptyList(),
    val sentimentFilter: SentimentFilter = SentimentFilter.ALL
)

@HiltViewModel
class ScannerViewModel @Inject constructor(
    private val api: RouaApiService
) : ViewModel() {

    private val _uiState = MutableStateFlow(ScannerUiState())
    val uiState: StateFlow<ScannerUiState> = _uiState

    init {
        loadAll()
    }

    fun selectTab(tab: ScannerTab) {
        _uiState.value = _uiState.value.copy(selectedTab = tab)
    }

    private fun loadAll() {
        runScan()
        loadHeatmap()
        loadNews()
    }

    // ── Scanner ──
    fun selectCategory(category: String) {
        _uiState.value = _uiState.value.copy(selectedCategory = category)
        runScan()
    }

    fun selectTimeframe(timeframe: String) {
        _uiState.value = _uiState.value.copy(selectedTimeframe = timeframe)
        runScan()
    }

    fun runScan() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true)
            try {
                val cat = _uiState.value.selectedCategory
                val tf = _uiState.value.selectedTimeframe
                val results = api.scan(
                    timeframe = if (tf == "1h") null else tf,
                    category = if (cat == "ALL") null else cat
                )
                _uiState.value = _uiState.value.copy(results = results, isLoading = false)
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(isLoading = false, error = e.message)
            }
        }
    }

    // ── Heatmap ──
    fun loadHeatmap() {
        viewModelScope.launch {
            try {
                val cat = _uiState.value.heatmapCategory
                val items = api.getHeatmap(category = if (cat == "ALL") null else cat)
                _uiState.value = _uiState.value.copy(heatmapItems = items)
            } catch (_: Exception) { }
        }
    }

    fun setHeatmapCategory(category: String) {
        _uiState.value = _uiState.value.copy(heatmapCategory = category)
        loadHeatmap()
    }

    // ── News ──
    fun loadNews() {
        viewModelScope.launch {
            try {
                val news = api.getLatestNews(limit = 30)
                _uiState.value = _uiState.value.copy(news = news)
            } catch (_: Exception) { }
        }
    }

    fun setSentimentFilter(filter: SentimentFilter) {
        _uiState.value = _uiState.value.copy(sentimentFilter = filter)
    }

    fun filteredNews(): List<NewsArticle> {
        val all = _uiState.value.news
        return when (_uiState.value.sentimentFilter) {
            SentimentFilter.ALL -> all
            SentimentFilter.POSITIVE -> all.filter { it.sentiment?.lowercase() == "positive" }
            SentimentFilter.NEGATIVE -> all.filter { it.sentiment?.lowercase() == "negative" }
            SentimentFilter.NEUTRAL -> all.filter { it.sentiment?.lowercase() == "neutral" }
        }
    }
}
