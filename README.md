# SmartShopper Mobile

A comprehensive Flutter-based shopping assistant application that helps users manage their shopping efficiently with budget tracking, price comparison, location-based retailer discovery, and smart shopping list management.

## 📱 Features

- **User Authentication**: Firebase Auth with Google Sign-in support
- **Budget Management**: Track spending with budget alerts and history
- **Shopping Lists**: Create and manage shopping lists with items
- **Product Search**: Search and compare products across retailers
- **Price Comparison**: View prices from different retailers in your area
- **Location Services**: Find nearby retailers with geolocation
- **Image Management**: Upload and manage product/receipt images via Firebase Storage
- **Notifications**: Real-time shopping and budget alerts
- **Dark Mode Support**: Full light and dark theme support
- **User Profiles**: Manage account settings and preferences

## 🏗️ Architecture

### Tech Stack

- **Framework**: Flutter 3.7.2
- **State Management**: Riverpod 2.5.0
- **Backend**: Firebase (Authentication, Firestore, Storage)
- **Additional Libraries**:
  - `google_sign_in` - Social authentication
  - `geolocator` - Location services
  - `image_picker` - Device image selection
  - `permission_handler` - Runtime permissions
  - `url_launcher` - External link handling

### Project Structure

```
lib/
├── config/          # App configuration, theme, routes, Firebase setup
├── screens/         # UI screens (auth, home, products, profile, shopping)
├── providers/       # Riverpod state management providers
├── services/        # Firebase and business logic services
├── widgets/         # Reusable UI components
├── data/            # Mock data and data models
├── utils/           # Utility functions and helpers
└── main.dart        # Application entry point
```

### Key Components

| Component | Purpose |
|-----------|---------|
| **Providers** | Manage app state reactively with Riverpod (cart, auth, budget, shopping lists, products, etc.) |
| **Services** | Handle Firebase operations and business logic |
| **Screens** | Authentication, home dashboard, product browsing, shopping, profile management |
| **Widgets** | Reusable UI components for consistent design |
| **Config** | App theme, routing, and Firebase initialization |

## 🔐 Security

- Firestore security rules enforce user data isolation
- Each user can only access their own data (profile, budgets, shopping lists)
- Default deny policy for unauthorized access
- Secure Firebase authentication with sign-in verification

## 🚀 Getting Started

### Prerequisites

- Flutter SDK: ^3.7.2
- Dart SDK: ^3.7.2
- Android SDK: API 21+
- Firebase project configured
- Google Cloud project with OAuth credentials

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd smartshopper_mobile
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Ensure `google-services.json` is placed in `android/app/`
   - Firebase credentials should be configured in `lib/config/firebase_config.dart`
   - Update Firestore security rules from `firestore.rules`

4. **Generate launchers icons**
   ```bash
   flutter pub run flutter_launcher_icons:main
   ```

5. **Run the application**
   ```bash
   flutter run
   ```

## 📋 Available Scripts

| Command | Purpose |
|---------|---------|
| `flutter pub get` | Fetch all dependencies |
| `flutter run` | Run app in development mode |
| `flutter build apk` | Build Android APK release |
| `flutter build appbundle` | Build Android App Bundle for Play Store |
| `flutter analyze` | Run static analysis with lints |
| `flutter test` | Run unit and widget tests |

## 🔧 Configuration

### Theme Configuration
Located in `lib/config/app_theme.dart` - Customize colors, fonts, and material design tokens.

### Routing
Located in `lib/config/routes.dart` - All app routes are centrally configured here.

### Firebase Setup
Located in `lib/config/firebase_config.dart` - Initialize and configure Firebase services.

## 📦 Admin Dashboard

A companion web admin dashboard is available in the `smartshopper_admin/` directory for:
- User management
- Product catalog administration
- Retailer management
- System analytics
- Notification payload composition for Firebase Console or external backends

Build and deploy separately as a web application.

## 💸 Low-Cost Deployment

The lowest-cost setup for this repo is:
- Firestore rules
- Hosting for the admin dashboard

The dashboard notification page is intentionally usable without Cloud Functions. It copies FCM payloads to your clipboard so you can paste them into Firebase Console and avoid Blaze billing.

Deploy with:
```bash
firebase deploy --only firestore:rules,hosting
```

## 🧪 Testing

```bash
flutter test
```

Widget tests are located in the `test/` directory.

## 📄 Firestore Schema

### Users Collection
```
users/{userId}
├── userProfile data
├── budgets/{budgetId}
│   ├── budget details
│   └── history/{historyId}
└── shoppingLists/{listId}
    └── items/{itemId}
```

## 🤝 Contributing

1. Create a feature branch (`git checkout -b feature/amazing-feature`)
2. Commit your changes (`git commit -m 'Add amazing feature'`)
3. Push to the branch (`git push origin feature/amazing-feature`)
4. Open a Pull Request

## 📜 License

This project is private and not for public distribution.

## 📚 Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [Firebase Flutter Guide](https://firebase.flutter.dev/)
- [Material Design](https://m3.material.io/)

## 📞 Support

For issues and questions, please contact the development team or create an issue in the project repository.
