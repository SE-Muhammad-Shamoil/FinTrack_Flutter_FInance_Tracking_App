# 🛡️ FinGuard AI

> **A privacy-first, offline personal finance assistant built with Flutter.**

FinGuard AI helps you take full control of your finances — tracking transactions, managing budgets, monitoring investments, and auto-reading SMS bank alerts — all without ever sending your data to the cloud.

---

## ✨ Features

| Feature | Description |
|---|---|
| 📊 **Dashboard** | At-a-glance overview of income, expenses, and net balance |
| 💳 **Transaction Tracking** | Log and categorize income & expenses manually or via SMS auto-detection |
| 📩 **SMS Auto-Read** | Automatically parses bank SMS messages to detect transactions |
| 🎯 **Budget Management** | Set monthly budgets per category with live progress tracking |
| 📈 **Investments** | Track investment portfolios and performance |
| 🔔 **Smart Notifications** | Local reminders and budget-limit alerts |
| 🔒 **Biometric Auth** | Secure app access with fingerprint / face unlock |
| 📤 **CSV Export** | Export your transaction history as a CSV file |
| 🌙 **Dark Mode** | Full dark-mode support with a custom design system |
| 📴 **100% Offline** | All data stored locally using SQLite — no account required |

---

## 🏗️ Architecture

The project follows a clean, layered architecture:

```
lib/
├── core/             # App-wide utilities, constants, and error handling
├── data/             # SQLite data sources and repository implementations
├── domain/           # Entities, repository interfaces, and use cases
├── presentation/
│   ├── design_system/  # Tokens, themes, and shared UI components
│   ├── features/       # Feature-based screens & controllers
│   │   ├── auth/
│   │   ├── dashboard/
│   │   ├── transactions/
│   │   ├── budgets/
│   │   ├── investments/
│   │   └── settings/
│   ├── providers/      # Riverpod state providers
│   └── router/         # GoRouter navigation setup
└── services/           # Platform services (notifications, SMS, auth)
```

**State Management:** [Riverpod](https://riverpod.dev/)  
**Navigation:** [GoRouter](https://pub.dev/packages/go_router)  
**Local DB:** [sqflite](https://pub.dev/packages/sqflite)  
**Charts:** [fl_chart](https://pub.dev/packages/fl_chart)

---

## 📦 Tech Stack

- **Framework:** Flutter (Dart ≥ 3.2)
- **State:** `flutter_riverpod`
- **Routing:** `go_router`
- **Database:** `sqflite` + `path_provider`
- **Auth:** `local_auth` + `flutter_secure_storage`
- **Charts:** `fl_chart`
- **SMS:** `telephony`
- **Notifications:** `flutter_local_notifications`
- **Fonts:** `google_fonts`
- **Animations:** `flutter_animate`

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.2.0
- Android Studio / VS Code with Flutter extension
- A physical Android device or emulator (SMS reading requires real device)

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/SE-Muhammad-Shamoil/FinTrack_Flutter_FInance_Tracking_App.git
cd finguard_ai

# 2. Install dependencies
flutter pub get

# 3. Generate app icons
dart run flutter_launcher_icons

# 4. Run the app
flutter run
```

### Android Permissions

The following permissions are used (declared in `AndroidManifest.xml`):

- `RECEIVE_SMS` / `READ_SMS` — for automatic transaction detection
- `USE_BIOMETRIC` / `USE_FINGERPRINT` — for biometric lock
- `POST_NOTIFICATIONS` — for budget alerts

---

## 📸 Screenshots

> _Coming soon — run the app locally to see it in action!_

---

## 🗺️ Roadmap

- [ ] Recurring transaction support
- [ ] Multi-currency support
- [ ] Spending insights with AI summaries
- [ ] Widget (home screen balance widget)
- [ ] iOS SMS parsing support
- [ ] Cloud backup (opt-in)

---

## 🤝 Contributing

Contributions are welcome! Please open an issue first to discuss what you'd like to change.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Commit your changes (`git commit -m 'Add some feature'`)
4. Push to the branch (`git push origin feature/your-feature`)
5. Open a Pull Request

---

## 📄 License

This project is for educational purposes as part of a Mobile Application Development course (SEM-6).

---

<div align="center">
  Made with ❤️ using Flutter
</div>
