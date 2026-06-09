package com.roua.trading.features.auth

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Email
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PaintingStyle
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.roua.trading.design.theme.RouaColors

// ──────────────────────────────────────────────────────────────────────
// Auth screen — login / OTP flow
// ──────────────────────────────────────────────────────────────────────

@Composable
fun AuthScreen(
    onAuthSuccess: (token: String, refreshToken: String?) -> Unit,
) {
    var authStep by remember { mutableStateOf(AuthStep.EMAIL_INPUT) }
    var email by remember { mutableStateOf("") }
    var otp by remember { mutableStateOf("") }
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(RouaColors.Background),
    ) {
        // ── Background layers ──
        GridOverlay()
        GradientOrbs()

        // ── Content ──
        Column(
            modifier = Modifier
                .fillMaxSize()
                .statusBarsPadding()
                .padding(horizontal = 28.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Spacer(Modifier.height(60.dp))

            // ── Brand logo with accent glow ──
            BrandLogo()

            Spacer(Modifier.height(8.dp))

            Text(
                text = "تداول ذكي بالذكاء الاصطناعي", // "Smart AI Trading" in Arabic
                color = RouaColors.TextSecondary,
                fontSize = 14.sp,
                fontWeight = FontWeight.Normal,
            )

            Spacer(Modifier.height(48.dp))

            // ── Step content ──
            AnimatedVisibility(
                visible = authStep == AuthStep.EMAIL_INPUT,
                enter = fadeIn() + slideInVertically(),
                exit = fadeOut() + slideOutVertically(),
            ) {
                EmailStep(
                    email = email,
                    onEmailChange = { email = it; errorMessage = null },
                    onSendOtp = {
                        if (email.isNotBlank()) {
                            isLoading = true
                            errorMessage = null
                            // Simulate OTP send — replace with real API call
                            authStep = AuthStep.OTP_INPUT
                            isLoading = false
                        } else {
                            errorMessage = "يرجى إدخال البريد الإلكتروني" // "Please enter email"
                        }
                    },
                    isLoading = isLoading,
                    errorMessage = errorMessage,
                    onGoogleSignIn = {
                        isLoading = true
                        // Simulate Google OAuth — replace with real implementation
                        onAuthSuccess("mock_google_token", null)
                    },
                    onAuthSuccess = onAuthSuccess,
                )
            }

            AnimatedVisibility(
                visible = authStep == AuthStep.OTP_INPUT,
                enter = fadeIn() + slideInVertically(),
                exit = fadeOut() + slideOutVertically(),
            ) {
                OtpStep(
                    email = email,
                    otp = otp,
                    onOtpChange = { otp = it; errorMessage = null },
                    onVerify = {
                        if (otp.length >= 4) {
                            isLoading = true
                            errorMessage = null
                            // Simulate OTP verification — replace with real API call
                            onAuthSuccess("mock_otp_token", "mock_refresh_token")
                            isLoading = false
                        } else {
                            errorMessage = "يرجى إدخال رمز التحقق" // "Please enter verification code"
                        }
                    },
                    onBack = {
                        authStep = AuthStep.EMAIL_INPUT
                        otp = ""
                        errorMessage = null
                    },
                    onResend = {
                        // Resend OTP — replace with real API call
                    },
                    isLoading = isLoading,
                    errorMessage = errorMessage,
                )
            }

            Spacer(Modifier.weight(1f))

            // ── Create account link ──
            if (authStep == AuthStep.EMAIL_INPUT) {
                CreateAccountLink(
                    onCreateAccount = {
                        // Navigate to sign-up — for now same flow
                    },
                )
                Spacer(Modifier.height(32.dp))
            }
        }
    }
}

// ──────────────────────────────────────────────────────────────────────
// Auth step enum
// ──────────────────────────────────────────────────────────────────────

private enum class AuthStep {
    EMAIL_INPUT,
    OTP_INPUT,
}

// ──────────────────────────────────────────────────────────────────────
// Brand logo — "ROUA" with accent glow
// ──────────────────────────────────────────────────────────────────────

@Composable
private fun BrandLogo() {
    Box(
        contentAlignment = Alignment.Center,
    ) {
        // Glow behind the text
        Box(
            modifier = Modifier
                .size(120.dp)
                .drawBehind {
                    drawCircle(
                        brush = Brush.radialGradient(
                            colors = listOf(
                                RouaColors.Accent.copy(alpha = 0.3f),
                                RouaColors.Accent.copy(alpha = 0.08f),
                                Color.Transparent,
                            ),
                            center = center,
                            radius = size.minDimension / 2f,
                        ),
                    )
                },
        )

        // Text
        Text(
            text = "ROUA",
            fontSize = 48.sp,
            fontWeight = FontWeight.Black,
            fontFamily = FontFamily.SansSerif,
            color = RouaColors.TextPrimary,
            letterSpacing = 8.sp,
            modifier = Modifier.drawBehind {
                // Subtle accent underline glow
                drawRoundRect(
                    color = RouaColors.Accent.copy(alpha = 0.25f),
                    cornerRadius = CornerRadius(4.dp.toPx()),
                    topLeft = Offset(0f, size.height - 3.dp.toPx()),
                    size = Size(size.width, 3.dp.toPx()),
                )
            },
        )
    }
}

// ──────────────────────────────────────────────────────────────────────
// Email step — email input + Google OAuth + send OTP
// ──────────────────────────────────────────────────────────────────────

@Composable
private fun EmailStep(
    email: String,
    onEmailChange: (String) -> Unit,
    onSendOtp: () -> Unit,
    isLoading: Boolean,
    errorMessage: String?,
    onGoogleSignIn: () -> Unit,
    onAuthSuccess: (token: String, refreshToken: String?) -> Unit,
) {
    val focusManager = LocalFocusManager.current

    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            text = "تسجيل الدخول", // "Sign In" in Arabic
            style = MaterialTheme.typography.headlineMedium,
            color = RouaColors.TextPrimary,
            fontWeight = FontWeight.Bold,
        )

        Spacer(Modifier.height(8.dp))

        Text(
            text = "أدخل بريدك الإلكتروني للمتابعة", // "Enter your email to continue"
            color = RouaColors.TextSecondary,
            fontSize = 14.sp,
            textAlign = TextAlign.Center,
        )

        Spacer(Modifier.height(28.dp))

        // ── Google OAuth button ──
        GoogleSignInButton(onClick = onGoogleSignIn)

        Spacer(Modifier.height(20.dp))

        // ── Divider ──
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(
                modifier = Modifier
                    .weight(1f)
                    .height(1.dp)
                    .background(RouaColors.CardBorder),
            )
            Text(
                text = "أو", // "or" in Arabic
                color = RouaColors.TextTertiary,
                fontSize = 12.sp,
                modifier = Modifier.padding(horizontal = 16.dp),
            )
            Box(
                modifier = Modifier
                    .weight(1f)
                    .height(1.dp)
                    .background(RouaColors.CardBorder),
            )
        }

        Spacer(Modifier.height(20.dp))

        // ── Email input ──
        OutlinedTextField(
            value = email,
            onValueChange = onEmailChange,
            label = {
                Text(
                    "البريد الإلكتروني", // "Email" in Arabic
                    color = RouaColors.TextTertiary,
                )
            },
            leadingIcon = {
                Icon(
                    Icons.Filled.Email,
                    contentDescription = null,
                    tint = RouaColors.TextSecondary,
                )
            },
            singleLine = true,
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Email,
                imeAction = ImeAction.Done,
            ),
            keyboardActions = KeyboardActions(
                onDone = { focusManager.clearFocus(); onSendOtp() },
            ),
            modifier = Modifier.fillMaxWidth(),
            colors = OutlinedTextFieldDefaults.colors(
                focusedContainerColor = RouaColors.SurfaceElevated,
                unfocusedContainerColor = RouaColors.SurfaceElevated,
                focusedTextColor = RouaColors.TextPrimary,
                unfocusedTextColor = RouaColors.TextPrimary,
                focusedBorderColor = RouaColors.Accent,
                unfocusedBorderColor = RouaColors.CardBorder,
                cursorColor = RouaColors.Accent,
            ),
            shape = RoundedCornerShape(10.dp),
        )

        // Error message
        errorMessage?.let {
            Spacer(Modifier.height(8.dp))
            Text(
                text = it,
                color = RouaColors.Danger,
                fontSize = 12.sp,
            )
        }

        Spacer(Modifier.height(20.dp))

        // ── Send OTP button ──
        Button(
            onClick = onSendOtp,
            enabled = !isLoading && email.isNotBlank(),
            modifier = Modifier
                .fillMaxWidth()
                .height(50.dp),
            colors = ButtonDefaults.buttonColors(
                containerColor = RouaColors.Accent,
                disabledContainerColor = RouaColors.Accent.copy(alpha = 0.4f),
            ),
            shape = RoundedCornerShape(10.dp),
        ) {
            if (isLoading) {
                CircularProgressIndicator(
                    modifier = Modifier.size(20.dp),
                    color = Color.White,
                    strokeWidth = 2.dp,
                )
            } else {
                Text(
                    text = "إرسال رمز التحقق", // "Send verification code" in Arabic
                    color = Color.White,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 15.sp,
                )
            }
        }
    }
}

// ──────────────────────────────────────────────────────────────────────
// OTP verification step
// ──────────────────────────────────────────────────────────────────────

@Composable
private fun OtpStep(
    email: String,
    otp: String,
    onOtpChange: (String) -> Unit,
    onVerify: () -> Unit,
    onBack: () -> Unit,
    onResend: () -> Unit,
    isLoading: Boolean,
    errorMessage: String?,
) {
    val focusManager = LocalFocusManager.current

    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        // Back button
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clickable(
                    interactionSource = remember { MutableInteractionSource() },
                    indication = null,
                    onClick = onBack,
                ),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = "← رجوع", // "← Back" in Arabic
                color = RouaColors.Accent,
                fontSize = 14.sp,
                fontWeight = FontWeight.Medium,
            )
        }

        Spacer(Modifier.height(16.dp))

        Text(
            text = "تحقق من البريد الإلكتروني", // "Verify your email" in Arabic
            style = MaterialTheme.typography.headlineMedium,
            color = RouaColors.TextPrimary,
            fontWeight = FontWeight.Bold,
        )

        Spacer(Modifier.height(8.dp))

        Text(
            text = buildAnnotatedString {
                append("أدخل الرمز المرسل إلى ") // "Enter the code sent to "
                withStyle(SpanStyle(color = RouaColors.TextPrimary, fontWeight = FontWeight.SemiBold)) {
                    append(email)
                }
            },
            color = RouaColors.TextSecondary,
            fontSize = 14.sp,
            textAlign = TextAlign.Center,
        )

        Spacer(Modifier.height(32.dp))

        // ── OTP input boxes ──
        OtpInputField(
            otp = otp,
            onOtpChange = onOtpChange,
            otpLength = 6,
            onFilled = { focusManager.clearFocus(); onVerify() },
        )

        // Error message
        errorMessage?.let {
            Spacer(Modifier.height(8.dp))
            Text(
                text = it,
                color = RouaColors.Danger,
                fontSize = 12.sp,
            )
        }

        Spacer(Modifier.height(28.dp))

        // ── Verify button ──
        Button(
            onClick = onVerify,
            enabled = !isLoading && otp.length >= 4,
            modifier = Modifier
                .fillMaxWidth()
                .height(50.dp),
            colors = ButtonDefaults.buttonColors(
                containerColor = RouaColors.Accent,
                disabledContainerColor = RouaColors.Accent.copy(alpha = 0.4f),
            ),
            shape = RoundedCornerShape(10.dp),
        ) {
            if (isLoading) {
                CircularProgressIndicator(
                    modifier = Modifier.size(20.dp),
                    color = Color.White,
                    strokeWidth = 2.dp,
                )
            } else {
                Text(
                    text = "تحقق", // "Verify" in Arabic
                    color = Color.White,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 15.sp,
                )
            }
        }

        Spacer(Modifier.height(16.dp))

        // ── Resend OTP ──
        Text(
            text = "لم تستلم الرمز؟ ", // "Didn't receive the code? "
            color = RouaColors.TextTertiary,
            fontSize = 13.sp,
        )
        Spacer(Modifier.height(4.dp))
        Text(
            text = "إعادة إرسال", // "Resend" in Arabic
            color = RouaColors.Accent,
            fontSize = 13.sp,
            fontWeight = FontWeight.SemiBold,
            modifier = Modifier.clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
                onClick = onResend,
            ),
        )
    }
}

// ──────────────────────────────────────────────────────────────────────
// OTP digit input field — individual boxes
// ──────────────────────────────────────────────────────────────────────

@Composable
private fun OtpInputField(
    otp: String,
    onOtpChange: (String) -> Unit,
    otpLength: Int,
    onFilled: () -> Unit,
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.Center,
    ) {
        repeat(otpLength) { index ->
            val char = otp.getOrNull(index)?.toString() ?: ""
            val isFocused = otp.length == index

            Box(
                modifier = Modifier
                    .size(44.dp)
                    .padding(horizontal = 3.dp)
                    .background(
                        color = if (isFocused) RouaColors.Accent.copy(alpha = 0.12f) else RouaColors.SurfaceElevated,
                        shape = RoundedCornerShape(8.dp),
                    )
                    .drawBehind {
                        if (isFocused) {
                            drawRoundRect(
                                color = RouaColors.Accent.copy(alpha = 0.5f),
                                cornerRadius = CornerRadius(8.dp.toPx()),
                                style = PaintingStyle.Stroke,
                                strokeWidth = 1.5.dp.toPx(),
                            )
                        } else {
                            drawRoundRect(
                                color = RouaColors.CardBorder,
                                cornerRadius = CornerRadius(8.dp.toPx()),
                                style = PaintingStyle.Stroke,
                                strokeWidth = 1.dp.toPx(),
                            )
                        }
                    }
                    .clickable(
                        interactionSource = remember { MutableInteractionSource() },
                        indication = null,
                        onClick = {
                            // Focus this field — for simplicity, we use a single
                            // hidden text field approach via the outer composable
                        },
                    ),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text = char,
                    color = RouaColors.TextPrimary,
                    fontSize = 20.sp,
                    fontWeight = FontWeight.SemiBold,
                    fontFamily = FontFamily.Monospace,
                )
            }
        }
    }

    // Hidden text field that captures input for the OTP boxes
    // This is a common pattern — a single invisible text field drives all boxes
    OutlinedTextField(
        value = otp,
        onValueChange = { newValue ->
            val filtered = newValue.filter { it.isDigit() }.take(otpLength)
            onOtpChange(filtered)
            if (filtered.length == otpLength) {
                onFilled()
            }
        },
        modifier = Modifier
            .fillMaxWidth()
            .height(0.dp)
            .alpha(0f), // Invisible but captures keyboard input
        keyboardOptions = KeyboardOptions(
            keyboardType = KeyboardType.Number,
            imeAction = ImeAction.Done,
        ),
        colors = OutlinedTextFieldDefaults.colors(
            focusedContainerColor = Color.Transparent,
            unfocusedContainerColor = Color.Transparent,
        ),
    )
}

// ──────────────────────────────────────────────────────────────────────
// Google Sign-In button
// ──────────────────────────────────────────────────────────────────────

@Composable
private fun GoogleSignInButton(onClick: () -> Unit) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .height(50.dp)
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
                onClick = onClick,
            ),
        shape = RoundedCornerShape(10.dp),
        color = RouaColors.SurfaceElevated,
    ) {
        Row(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.Center,
        ) {
            // Google "G" icon — drawn with Canvas since we don't have a drawable
            GoogleIcon()

            Spacer(Modifier.width(12.dp))

            Text(
                text = "تسجيل الدخول بحساب Google", // "Sign in with Google" in Arabic
                color = RouaColors.TextPrimary,
                fontWeight = FontWeight.Medium,
                fontSize = 15.sp,
            )
        }
    }
}

// ──────────────────────────────────────────────────────────────────────
// Simplified Google "G" icon drawn with Canvas
// ──────────────────────────────────────────────────────────────────────

@Composable
private fun GoogleIcon() {
    Canvas(modifier = Modifier.size(20.dp)) {
        val r = size.minDimension / 2f
        val strokeWidth = 2.5.dp.toPx()

        // Draw a stylized "G" using arcs
        // Blue arc (top-right)
        drawArc(
            color = Color(0xFF4285F4),
            startAngle = -90f,
            sweepAngle = 120f,
            useCenter = false,
            strokeWidth = strokeWidth,
        )
        // Red arc (top-left)
        drawArc(
            color = Color(0xFFEA4335),
            startAngle = 30f,
            sweepAngle = 120f,
            useCenter = false,
            strokeWidth = strokeWidth,
        )
        // Yellow arc (bottom-left)
        drawArc(
            color = Color(0xFFFBBC05),
            startAngle = 150f,
            sweepAngle = 60f,
            useCenter = false,
            strokeWidth = strokeWidth,
        )
        // Green arc (bottom-right)
        drawArc(
            color = Color(0xFF34A853),
            startAngle = 210f,
            sweepAngle = 60f,
            useCenter = false,
            strokeWidth = strokeWidth,
        )
        // Horizontal bar (the crossbar of G)
        drawLine(
            color = Color(0xFF4285F4),
            start = Offset(center.x, center.y),
            end = Offset(r, center.y),
            strokeWidth = strokeWidth,
        )
    }
}

// ──────────────────────────────────────────────────────────────────────
// Grid overlay for background texture
// ──────────────────────────────────────────────────────────────────────

@Composable
private fun GridOverlay() {
    Canvas(
        modifier = Modifier
            .fillMaxSize()
            .graphicsLayer { alpha = 0.04f },
    ) {
        val gridSpacing = 40.dp.toPx()
        val dashEffect = PathEffect.dashPathEffect(floatArrayOf(4.dp.toPx(), 8.dp.toPx()))

        // Vertical lines
        var x = 0f
        while (x < size.width) {
            drawLine(
                color = Color.White.copy(alpha = 0.08f),
                start = Offset(x, 0f),
                end = Offset(x, size.height),
                strokeWidth = 0.5.dp.toPx(),
                pathEffect = dashEffect,
            )
            x += gridSpacing
        }

        // Horizontal lines
        var y = 0f
        while (y < size.height) {
            drawLine(
                color = Color.White.copy(alpha = 0.08f),
                start = Offset(0f, y),
                end = Offset(size.width, y),
                strokeWidth = 0.5.dp.toPx(),
                pathEffect = dashEffect,
            )
            y += gridSpacing
        }
    }
}

// ──────────────────────────────────────────────────────────────────────
// Gradient orbs — soft colored glows for depth
// ──────────────────────────────────────────────────────────────────────

@Composable
private fun GradientOrbs() {
    Box(modifier = Modifier.fillMaxSize()) {
        // Top-right — accent glow
        Box(
            modifier = Modifier
                .align(Alignment.TopEnd)
                .offset(x = 60.dp, y = (-40).dp)
                .size(280.dp)
                .drawBehind {
                    drawCircle(
                        brush = Brush.radialGradient(
                            colors = listOf(
                                RouaColors.Accent.copy(alpha = 0.12f),
                                RouaColors.Accent.copy(alpha = 0.03f),
                                Color.Transparent,
                            ),
                            center = center,
                            radius = size.minDimension / 2f,
                        ),
                    )
                },
        )

        // Bottom-left — brand purple glow
        Box(
            modifier = Modifier
                .align(Alignment.BottomStart)
                .offset(x = (-80).dp, y = 60.dp)
                .size(300.dp)
                .drawBehind {
                    drawCircle(
                        brush = Brush.radialGradient(
                            colors = listOf(
                                RouaColors.Brand.copy(alpha = 0.08f),
                                RouaColors.Brand.copy(alpha = 0.02f),
                                Color.Transparent,
                            ),
                            center = center,
                            radius = size.minDimension / 2f,
                        ),
                    )
                },
        )

        // Center — subtle cyan glow
        Box(
            modifier = Modifier
                .align(Alignment.Center)
                .offset(y = 80.dp)
                .size(200.dp)
                .drawBehind {
                    drawCircle(
                        brush = Brush.radialGradient(
                            colors = listOf(
                                RouaColors.Cyan.copy(alpha = 0.06f),
                                Color.Transparent,
                            ),
                            center = center,
                            radius = size.minDimension / 2f,
                        ),
                    )
                },
        )
    }
}

// ──────────────────────────────────────────────────────────────────────
// "Create account" link
// ──────────────────────────────────────────────────────────────────────

@Composable
private fun CreateAccountLink(onCreateAccount: () -> Unit) {
    Row(
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = "ليس لديك حساب؟ ", // "Don't have an account? "
            color = RouaColors.TextTertiary,
            fontSize = 13.sp,
        )
        Text(
            text = "إنشاء حساب", // "Create account" in Arabic
            color = RouaColors.Accent,
            fontSize = 13.sp,
            fontWeight = FontWeight.SemiBold,
            modifier = Modifier.clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
                onClick = onCreateAccount,
            ),
        )
    }
}


