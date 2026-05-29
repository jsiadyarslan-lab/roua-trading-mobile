# Roua Trading — Mobile App

تطبيق جوال كامل لمنصة روعة للتداول، مبني بـ Swift + Kotlin + KMP

## 📁 هيكل المشروع

```
roua-mobile/
├── ios/RouaTrading/          # تطبيق iOS (Swift + SwiftUI)
│   ├── App/                  # نقطة الدخول
│   ├── Core/                 # طبقة أساسية
│   │   ├── Network/          # APIClient, WebSocket, Endpoints, Models
│   │   ├── Storage/          # Keychain, Biometric
│   │   └── Extensions/       # Extensions
│   ├── Design/               # نظام التصميم
│   │   ├── Theme/            # ألوان، خطوط
│   │   └── Components/       # مكونات مشتركة
│   ├── Features/             # الشاشات
│   │   ├── Auth/             # المصادقة (WebAuthn + Biometric)
│   │   ├── Dashboard/        # لوحة التحكم
│   │   ├── Trading/          # شاشة التداول
│   │   ├── AI/               # مساعد الذكاء الاصطناعي
│   │   ├── Portfolio/        # المحفظة
│   │   ├── Scanner/          # ماسح السوق
│   │   ├── Notifications/    # الإشعارات
│   │   ├── Agent/            # المتداول المستقل
│   │   ├── Settings/         # الإعدادات (35 لغة)
│   │   └── ...               # Neural, News, Signals, etc.
│   └── Navigation/           # تنقل + TabBar
│
├── android/app/              # تطبيق Android (Kotlin + Compose)
│   └── src/main/java/com/roua/trading/
│       ├── core/network/     # Retrofit API, Models, DI
│       ├── design/theme/     # ألوان، خطوط، ثيم
│       ├── features/         # الشاشات + ViewModels
│       └── navigation/       # NavHost + BottomNav
│
└── shared/                   # KMP Shared Module
    └── src/commonMain/kotlin/com/roua/shared/
        ├── api/              # نماذج مشتركة
        └── repository/       # طبقة الأعمال المشتركة
```

## 🛠️ التقنيات

| المكوّن | iOS | Android | مشترك |
|---------|-----|---------|-------|
| اللغة | Swift 5.9 | Kotlin 1.9 | KMP |
| UI | SwiftUI | Jetpack Compose | — |
| Architecture | MVVM + Clean | MVI + Clean | — |
| Network | URLSession + Socket.IO | Retrofit + OkHttp | Ktor |
| DI | — | Hilt | — |
| Storage | Keychain | Encrypted Prefs | — |
| Auth | WebAuthn + Face ID | WebAuthn + Biometric | — |
| Charts | Canvas | Charts Lib | — |
| Min OS | iOS 17 | Android 8.0 (API 26) | — |

## 🔗 ربط API

- **Base URL**: `https://roua-trading-production.up.railway.app/api`
- **Auth**: `x-roua-session` header أو `Authorization: Bearer <token>`
- **WebSocket**: Socket.IO على `/exchange` و `/notifications`
- **85+ نقطة نهاية** متصلة بالكامل

## 🚀 كيف تبني المشروع

### iOS (يتطلب macOS + Xcode 15+)
1. افتح مجلد `ios/RouaTrading/` في Xcode
2. أضف SPM dependencies: Socket.IO-Client-Swift, KeychainAccess
3. اختر جهاز iPhone أو Simulator
4. Build & Run (⌘R)

### Android (أي كمبيوتر + Android Studio)
1. افتح مجلد `android/` في Android Studio
2. Gradle Sync
3. اختر جهاز أو Emulator
4. Build & Run (▶)

## ⚠️ ملاحظات مهمة

- **ملف .ipa**: يتطلب macOS + Xcode + حساب Apple Developer ($99/سنة)
- **ملف .apk**: يمكن بناؤه مباشرة على أي كمبيوتر
- **شهادة التوقيع**: تحتاج لتكوين Apple Developer Certificate للـ iOS
- **Google OAuth**: يحتاج لتكوين OAuth Client ID من Google Cloud Console
