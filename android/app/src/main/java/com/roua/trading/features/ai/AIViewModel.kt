package com.roua.trading.features.ai

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.roua.trading.core.network.RouaApiService
import com.roua.trading.core.network.model.AIAnalyzeRequest
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class ChatMessage(val content: String, val isUser: Boolean, val model: String? = null)

data class AIUiState(
    val messages: List<ChatMessage> = emptyList(),
    val inputText: String = "",
    val isLoading: Boolean = false
)

@HiltViewModel
class AIViewModel @Inject constructor(
    private val api: RouaApiService
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(AIUiState())
    val uiState: StateFlow<AIUiState> = _uiState
    
    fun onInputChanged(text: String) {
        _uiState.value = _uiState.value.copy(inputText = text)
    }
    
    fun sendMessage() {
        val text = _uiState.value.inputText
        if (text.isBlank()) return
        
        _uiState.value = _uiState.value.copy(
            messages = _uiState.value.messages + ChatMessage(content = text, isUser = true),
            inputText = "",
            isLoading = true
        )
        
        viewModelScope.launch {
            try {
                val response = api.analyzeAI(AIAnalyzeRequest(prompt = text, language = "ar"))
                _uiState.value = _uiState.value.copy(
                    messages = _uiState.value.messages + ChatMessage(
                        content = response.analysis,
                        isUser = false,
                        model = response.model
                    ),
                    isLoading = false
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    messages = _uiState.value.messages + ChatMessage(content = "Error: ${e.message}", isUser = false),
                    isLoading = false
                )
            }
        }
    }
}
