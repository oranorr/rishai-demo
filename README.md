# Pivot — Fitness & Nutrition App

Portfolio preview of a Flutter app for health, nutrition, and workout tracking with an AI assistant and WHOOP integration.

> **This is a portfolio demo repository.**  
> All secrets, API keys, and production backend URLs have been replaced with placeholder values.  
> The app **will not work fully** without configuring your own services.

---

## Overview

Pivot is a mobile app for a personalized wellness experience:

- **AI Chat** — consultations and recommendations via an LLM proxy
- **Food Diary** — meal logging, wellness screen, calendar
- **Week Plan** — weekly meal and activity planning
- **WHOOP Integration** — sync with WHOOP (recovery, strain, sleep)
- **Onboarding & Auth** — Google / Apple Sign-In via Firebase
- **Subscriptions** — Adapty (in-app purchases)
- **Push & Analytics** — Firebase Messaging, Analytics, Sentry

The UI follows **Apple Human Interface Guidelines**: clean typography, minimal screens, smooth transitions, and a native feel on iOS.

---

## Tech Stack

| Category | Technologies |
|----------|--------------|
| Framework | Flutter 3.4+, Dart 3.4+ |
| State | BLoC, Freezed |
| DI | get_it, injectable |
| Routing | go_router |
| Local storage | Hive, SharedPreferences |
| Backend | REST (User Service), LLM Proxy |
| Auth | Firebase Auth, OAuth |
| Monetization | Adapty, Google Mobile Ads |
| Monitoring | Sentry |
| Deep links | Branch SDK |

---

## Architecture

Feature-first **Clean Architecture**:

```
lib/
├── core/              # DI, themes, routing, shared services and widgets
├── features/
│   ├── chat/          # AI chat
│   ├── food_diary/    # Food diary
│   ├── home/          # Home screen
│   ├── login/         # Authentication
│   ├── onboard/       # Onboarding
│   ├── settings/      # Settings
│   ├── user/          # User profile
│   ├── week_plan/     # Weekly plan
│   └── whoop/         # WHOOP integration
└── main.dart
```

Each feature module is split into `data` → `domain` → `presentation` layers.

---

## Quick Start

### 1. Clone and install dependencies

```bash
git clone git@github.com:oranorr/pivot-demo.git
cd pivot-demo
flutter pub get
```

### 2. Environment variables

```bash
cp .env.example .env
# Fill in .env with your keys (or leave placeholders to browse the code)
dart run build_runner build --delete-conflicting-outputs
```

### 3. Firebase (optional)

1. Create a project in [Firebase Console](https://console.firebase.google.com/)
2. Add iOS and Android apps
3. Replace the placeholder files:
   - `lib/firebase_options.dart`
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
4. Or use the FlutterFire CLI:

```bash
flutterfire configure
```

### 4. Run

```bash
flutter run
```

---

## Environment Variables

| Variable | Description |
|----------|-------------|
| `OPEN_AI_API_KEY` | OpenAI API key |
| `WHOOP_CLIENT_ID` | WHOOP OAuth client ID |
| `WHOOP_CLIENT_SECRET` | WHOOP OAuth secret |
| `GPT_ASSISTANT_ID` | GPT assistant ID |
| `GOOGLE_CLIENT_ID` | Google OAuth client ID |
| `ADAPTY_SDK_KEY` | Adapty SDK key |
| `AUTH_HEADER_KEY` | Backend auth header |

See [`.env.example`](.env.example) for the full list.

---

## Platforms

- iOS
- Android

Web, macOS, Windows, and Linux are not the primary focus.

---

## About This Demo Repository

This repository exists **for code showcase purposes only**:

- No real API keys, DSNs, or Firebase credentials
- Backend URLs replaced with `your-backend.example.com`
- AdMob uses Google [test ad unit IDs](https://developers.google.com/admob/android/test-ads)
- Internal admin scripts and ops documentation removed

If you are a recruiter or developer and would like to see the app in action — contact the repository author.

---

## License

The code belongs to the rights holders of the original project. This demo repository is published solely as a **code preview** for portfolio purposes.
