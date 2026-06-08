// =============================================================================
// AuthView.swift — Roua Trading · Authentication Screen
// =============================================================================
// Beautiful dark glassmorphism auth screen with:
//   • Gradient "ROUA" brand logo
//   • Arabic subtitle
//   • Google OAuth sign-in (primary)
//   • Passkey sign-in with email field (secondary)
//   • Create account (ghost)
//   • Loading shimmer states
//   • Error banner
//   • Animated fade-in for elements
//   • Terms footer
// =============================================================================

import SwiftUI

struct AuthView: View {

    @EnvironmentObject private var authViewModel: AuthViewModel

    // MARK: - State

    @State private var showContent = false
    @State private var showEmailField = false
    @State private var email = ""
    @State private var otpCode = ""
    @State private var brandingOffset: CGFloat = 30

    @FocusState private var isEmailFocused: Bool

    // MARK: - Body

    var body: some View {
        ZStack {
            // ── Background ──
            backgroundLayer

            // ── Content ──
            ScrollView(showsIndicators: false) {
                VStack(spacing: RouaSpacing.xxl) {
                    Spacer(minLength: 0)

                    // Brand
                    brandingSection
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : brandingOffset)

                    // Auth Methods
                    authMethodsSection
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : brandingOffset)

                    // Terms
                    termsFooter
                        .opacity(showContent ? 1 : 0)

                    Spacer(minLength: RouaSpacing.xxxl)
                }
                .padding(.horizontal, RouaSpacing.screenPadding)
            }
            .scrollDismissesKeyboard(.interactively)

            // ── Error Banner ──
            if let errorMessage = authViewModel.errorMessage {
                VStack {
                    ErrorBanner(
                        message: errorMessage,
                        onRetry: {
                            // Retry depends on which method was last used
                        },
                        onDismiss: {
                            authViewModel.errorMessage = nil
                        }
                    )
                    .padding(.horizontal, RouaSpacing.screenPadding)
                    .padding(.top, RouaSpacing.xl)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // ── Loading Overlay ──
            if authViewModel.isLoading {
                LoadingView(message: "جاري تسجيل الدخول…")
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: RouaSpacing.animationDuration), value: authViewModel.errorMessage)
        .animation(.easeOut(duration: RouaSpacing.animationDuration), value: authViewModel.isLoading)
        .onAppear {
            performEntranceAnimation()
        }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            // Base dark gradient
            LinearGradient(
                colors: [
                    Color.rouaBackground,
                    Color(hex: "0D1220"),
                    Color(hex: "0A0E17")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Accent glow orbs
            Circle()
                .fill(Color.rouaPrimary.opacity(0.08))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -80, y: -200)

            Circle()
                .fill(Color.rouaAccent.opacity(0.06))
                .frame(width: 250, height: 250)
                .blur(radius: 60)
                .offset(x: 100, y: 100)

            // Subtle grid overlay
            gridOverlay
        }
    }

    private var gridOverlay: some View {
        Canvas { context, size in
            let gridSpacing: CGFloat = 60
            context.opacity = 0.03

            for x in stride(from: 0, through: size.width, by: gridSpacing) {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(.white), lineWidth: 0.5)
            }
            for y in stride(from: 0, through: size.height, by: gridSpacing) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(.white), lineWidth: 0.5)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Branding Section

    private var brandingSection: some View {
        VStack(spacing: RouaSpacing.lg) {
            // Logo mark
            ZStack {
                // Glow ring
                Circle()
                    .stroke(Color.rouaPrimary.opacity(0.3), lineWidth: 2)
                    .frame(width: 100, height: 100)
                    .blur(radius: 4)

                Circle()
                    .fill(Color.rouaGradientPrimary)
                    .frame(width: 88, height: 88)
                    .overlay(
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundStyle(.white)
                    )
                    .shadow(color: .rouaPrimary.opacity(0.4), radius: RouaSpacing.glowRadius)
            }

            // Brand text
            Text("ROUA")
                .font(.system(size: 42, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.rouaPrimary, Color.rouaSecondary, Color.rouaAccent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .tracking(6)
                .accessibilityLabel("روا")

            // Subtitle
            Text("منصة التداول الذكية")
                .rouaFont(.title3, color: .rouaTextSecondary)
        }
    }

    // MARK: - Auth Methods

    private var authMethodsSection: some View {
        VStack(spacing: RouaSpacing.lg) {
            // ── Google Sign-In (Primary) ──
            RouaButton(
                "تسجيل الدخول بـ Google",
                variant: .primary,
                size: .large,
                icon: "globe",
                isLoading: false,
                action: { authViewModel.googleSignIn() }
            )

            // ── Email + OTP Sign-In (Secondary) ──
            RouaButton(
                "تسجيل الدخول بالبريد الإلكتروني",
                variant: .secondary,
                size: .large,
                icon: "envelope.fill",
                action: { toggleEmailField() }
            )

            // ── Email Field (expands when email login is selected) ──
            if showEmailField {
                emailFieldSection
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            // ── OTP Field (appears after OTP is sent) ──
            if authViewModel.isOtpSent {
                otpFieldSection
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            // ── Create Account (Ghost) — also uses OTP flow ──
            RouaButton(
                "إنشاء حساب جديد",
                variant: .ghost,
                size: .medium,
                icon: "person.badge.plus",
                action: {
                    if !showEmailField {
                        toggleEmailField()
                    } else if email.isValidEmail {
                        // Reuse OTP flow for registration (backend creates user if not exists)
                        authViewModel.sendOtp(email: email)
                    } else {
                        authViewModel.errorMessage = "يرجى إدخال بريد إلكتروني صحيح"
                    }
                }
            )

            // ── Guest Access — try the app without signing up ──
            RouaButton(
                "تجربة التطبيق كزائر",
                variant: .ghost,
                size: .medium,
                icon: "person.crop.circle.badge.questionmark",
                action: { authViewModel.guestSignIn() }
            )
        }
        .animation(
            .spring(response: 0.4, dampingFraction: 0.8),
            value: showEmailField
        )
        .animation(
            .spring(response: 0.4, dampingFraction: 0.8),
            value: authViewModel.isOtpSent
        )
    }

    // MARK: - Email Field

    private var emailFieldSection: some View {
        VStack(spacing: RouaSpacing.md) {
            HStack(spacing: RouaSpacing.sm) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: RouaSpacing.iconMedium))
                    .foregroundStyle(.rouaTextTertiary)

                TextField("البريد الإلكتروني", text: $email)
                    .rouaFont(.callout, color: .rouaTextPrimary)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .focused($isEmailFocused)
                    .submitLabel(.go)
                    .onSubmit {
                        if email.isValidEmail && !authViewModel.isOtpSent {
                            authViewModel.sendOtp(email: email)
                        }
                    }
                    .accessibilityLabel("البريد الإلكتروني")
                    .accessibilityHint("أدخل بريدك الإلكتروني لإرسال رمز التحقق")
            }
            .padding(.horizontal, RouaSpacing.lg)
            .padding(.vertical, RouaSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: RouaSpacing.buttonCornerRadius, style: .continuous)
                    .fill(Color.rouaGlassStrong)
            )
            .overlay(
                RoundedRectangle(cornerRadius: RouaSpacing.buttonCornerRadius, style: .continuous)
                    .stroke(
                        isEmailFocused ? Color.rouaPrimary.opacity(0.5) : Color.rouaGlassBorder,
                        lineWidth: isEmailFocused ? 1.5 : 1
                    )
            )
            .animation(.easeOut(duration: RouaSpacing.animationFast), value: isEmailFocused)

            // Send OTP button
            if email.isNotEmpty && !authViewModel.isOtpSent {
                RouaButton(
                    "إرسال رمز التحقق",
                    variant: .primary,
                    size: .medium,
                    icon: "paperplane.fill",
                    iconPosition: .trailing,
                    isLoading: authViewModel.isLoading,
                    isDisabled: !email.isValidEmail,
                    action: { authViewModel.sendOtp(email: email) }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - OTP Field

    private var otpFieldSection: some View {
        VStack(spacing: RouaSpacing.md) {
            Text("تم إرسال رمز التحقق إلى \(email)")
                .rouaFont(.caption, color: .rouaTextSecondary)

            HStack(spacing: RouaSpacing.sm) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: RouaSpacing.iconMedium))
                    .foregroundStyle(.rouaTextTertiary)

                TextField("رمز التحقق", text: $otpCode)
                    .rouaFont(.callout, color: .rouaTextPrimary)
                    .keyboardType(.numberPad)
                    .autocorrectionDisabled()
                    .submitLabel(.go)
                    .onSubmit {
                        if otpCode.count == 6 {
                            authViewModel.verifyOtp(otp: otpCode)
                        }
                    }
                    .accessibilityLabel("رمز التحقق")
                    .accessibilityHint("أدخل رمز التحقق المكوّن من 6 أرقام")
            }
            .padding(.horizontal, RouaSpacing.lg)
            .padding(.vertical, RouaSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: RouaSpacing.buttonCornerRadius, style: .continuous)
                    .fill(Color.rouaGlassStrong)
            )
            .overlay(
                RoundedRectangle(cornerRadius: RouaSpacing.buttonCornerRadius, style: .continuous)
                    .stroke(Color.rouaPrimary.opacity(0.3), lineWidth: 1)
            )

            // Verify OTP button
            RouaButton(
                "تسجيل الدخول",
                variant: .primary,
                size: .medium,
                icon: "checkmark.shield.fill",
                iconPosition: .trailing,
                isLoading: authViewModel.isLoading,
                isDisabled: otpCode.count != 6,
                action: { authViewModel.verifyOtp(otp: otpCode) }
            )
        }
    }

    // MARK: - Terms Footer

    private var termsFooter: some View {
        VStack(spacing: RouaSpacing.xs) {
            Text("بتسجيل الدخول، أنت توافق على")
                .rouaFont(.footnote, color: .rouaTextTertiary)

            HStack(spacing: RouaSpacing.xs) {
                Button {
                    if let url = URL(string: AppConfig.webBaseURL + "/terms") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("شروط الاستخدام")
                        .rouaFont(.footnoteBold, color: .rouaPrimary)
                }

                Text("و")
                    .rouaFont(.footnote, color: .rouaTextTertiary)

                Button {
                    if let url = URL(string: AppConfig.webBaseURL + "/privacy") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("سياسة الخصوصية")
                        .rouaFont(.footnoteBold, color: .rouaPrimary)
                }
            }
        }
        .padding(.top, RouaSpacing.md)
    }

    // MARK: - Helpers

    private func toggleEmailField() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showEmailField.toggle()
        }
        if showEmailField {
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                isEmailFocused = true
            }
        }
    }

    private func performEntranceAnimation() {
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
        }
    }
}

// MARK: - Preview

#Preview("AuthView") {
    ZStack {
        Color.rouaBackground.ignoresSafeArea()
        AuthView()
            .environmentObject(AuthViewModel())
    }
    .preferredColorScheme(.dark)
}
