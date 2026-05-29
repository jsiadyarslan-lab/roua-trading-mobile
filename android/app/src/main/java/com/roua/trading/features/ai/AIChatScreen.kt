package com.roua.trading.features.ai

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.roua.trading.design.theme.RouaColors

@Composable
fun AIChatScreen(viewModel: AIViewModel = hiltViewModel()) {
    val uiState by viewModel.uiState.collectAsState()
    
    Column(modifier = Modifier.fillMaxSize()) {
        // Messages
        LazyColumn(
            modifier = Modifier.weight(1f).padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            items(uiState.messages) { message ->
                Card(
                    colors = CardDefaults.cardColors(
                        containerColor = if (message.isUser) RouaColors.Accent else RouaColors.SurfaceElevated
                    ),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(
                        message.content,
                        modifier = Modifier.padding(12.dp),
                        color = if (message.isUser) androidx.compose.ui.graphics.Color.White else RouaColors.TextPrimary
                    )
                }
            }
            
            if (uiState.isLoading) {
                item {
                    Text("AI is thinking...", color = RouaColors.TextTertiary, modifier = Modifier.padding(12.dp))
                }
            }
        }
        
        // Input Bar
        Row(
            modifier = Modifier.fillMaxWidth().padding(16.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            OutlinedTextField(
                value = uiState.inputText,
                onValueChange = { viewModel.onInputChanged(it) },
                placeholder = { Text("Ask AI about markets...") },
                modifier = Modifier.weight(1f),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedContainerColor = RouaColors.SurfaceElevated,
                    unfocusedContainerColor = RouaColors.SurfaceElevated,
                    focusedTextColor = RouaColors.TextPrimary,
                    unfocusedTextColor = RouaColors.TextPrimary
                )
            )
            Button(
                onClick = { viewModel.sendMessage() },
                enabled = uiState.inputText.isNotBlank() && !uiState.isLoading,
                colors = ButtonDefaults.buttonColors(containerColor = RouaColors.Accent)
            ) {
                Text("Send")
            }
        }
    }
}
