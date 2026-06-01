package com.roua.trading.features.scanner

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.roua.trading.core.network.RouaApiService
import com.roua.trading.core.network.model.ScanResult
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class ScannerUiState(
    val results: List<ScanResult> = emptyList(),
    val selectedCategory: String = "ALL",
    val isLoading: Boolean = false
)

@HiltViewModel
class ScannerViewModel @Inject constructor(
    private val api: RouaApiService
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(ScannerUiState())
    val uiState: StateFlow<ScannerUiState> = _uiState
    
    init { runScan() }
    
    fun selectCategory(category: String) {
        _uiState.value = _uiState.value.copy(selectedCategory = category)
        runScan()
    }
    
    fun runScan() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true)
            try {
                val cat = _uiState.value.selectedCategory
                val results = api.scan(category = if (cat == "ALL") null else cat)
                _uiState.value = _uiState.value.copy(results = results, isLoading = false)
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(isLoading = false)
            }
        }
    }
}
