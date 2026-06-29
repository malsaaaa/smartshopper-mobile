# SmartShopper Mobile

A comprehensive, production-ready Flutter-based smart shopping assistant application. SmartShopper helps users make cost-effective grocery choices by comparing basket prices across major Malaysian retailers (Mydin, Lotus's, and myAEON2go), calculating distance-aware travel costs, tracking budgets, and providing real-time price alerts.

---

## 📱 Features

### 1. Smart Shopping Recommendations & Price Comparison
* **Basket-Level Comparison**: Evaluates a user's entire shopping list rather than individual items.
* **Cheaper-Alternative Fallbacks**: If a retailer does not carry a specific item on the list, the algorithm applies a fallback price (the cheapest available price from other stores) to calculate a realistic total comparison.
* **Stocking Ratios**: Displays a clear "X of Y items available" indicator so the user knows if a retailer carries the entire list.
* **Favored Product Management**: Easily add and remove items from favorites, with automated pruning of orphaned database records.

### 2. Geolocation & Net Savings Calculator
* **Distance Tracking**: Uses GPS coordinates and the Haversine formula to compute the exact distance from the user's location to the nearest branches in Melaka (Mydin Jasin, Lotus's Melaka, and AEON Melaka).
* **Fuel Cost Math**: Computes round-trip fuel cost dynamically based on:
  * **Current RON 95 Price**: RM 3.47 per liter
  * **Average Fuel Efficiency**: 12.0 km/liter (representing typical B-segment city cars like the Perodua Myvi or Proton Saga).
* **Net Savings Indicator**: Subtracts the estimated travel cost from grocery price savings, showing the user their true **Net Save** or **Loss** if they drive to a further store.

### 3. Automated Web Scraping Pipeline
* **API-Level Scraping**: Bypasses slow and fragile HTML rendering by querying direct REST API endpoints of the retailers (Lotus's O2O API, MyDin Magento API, and AEON React storefront payloads).
* **Codebase Unification**: Written entirely in Dart and compiled inside the application. No external Python servers, microservices, or headless browsers (Selenium/Puppeteer) are required to run the scraper.
* **Web Scraper Control Panel**: Admins can trigger and monitor live scraping directly within the mobile application.

### 4. Technical Resilience
* **Stable ID Mapping**: Implements a DJB2 hashing algorithm to convert alphanumeric string document IDs (common in scraped retail data) into unique, stable 31-bit Dart integers, avoiding ID collisions.
* **Robust Date Parser**: A dynamic wrapper parses both native Firestore `Timestamp` objects and ISO 8601 string dates, protecting the app against runtime `NoSuchMethodError` crashes.
* **Forgot Password Flow**: Fully integrated password reset flow backed by Firebase Authentication.

---

## 🏗️ Architecture

### Tech Stack
* **Framework**: Flutter (Dart)
* **State Management**: Riverpod 2.5.0 (reactive state, cart, budgets, auth, lists)
* **Backend**: Firebase (Authentication, Firestore Database, Storage)
* **Design System**: Custom app theme built on top of Material 3

### Project Structure
```
lib/
├── config/          # Central routes, Material 3 theme configurations, Firebase setup
├── data/            # Data models (Product, Price, Retailer, Budget, User) and mock data
├── providers/       # Riverpod state management and authentication providers
├── screens/         # UI screens (auth, home, admin scraper control, notifications, profile)
├── services/        # Business logic services (Firebase, Location, Notifications)
│   └── scrapers/    # Targeted API-level scrapers (Mydin, myAEON2go, Lotus)
├── utils/           # Helper scripts (stable ID hashing, dynamic date parsing, validators)
├── widgets/         # Reusable design components and UI cards
└── main.dart        # Main app entry point
```

---

## 🚀 Getting Started

### Prerequisites
* **Flutter SDK**: `^3.7.2`
* **Dart SDK**: `^3.7.2`
* **Android SDK**: API 21+ (Lollipop or higher)
* **Firebase Project**: Configured with Firestore, Storage, and Email/Google Auth enabled.

### Installation & Launch

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd smartshopper_mobile
   ```

2. **Install project dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Platform Credentials**:
   * Place your `google-services.json` inside the `android/app/` folder.
   * Add web-specific Firebase keys inside `lib/config/firebase_config.dart`.
   * Apply database rules from `firestore.rules`.

4. **Run the Application**:
   ```bash
   # To run on a connected Android/iOS device
   flutter run
   
   # To test on Chrome
   flutter run -d chrome
   ```

---

## 📋 Commands & Scripts

| Command | Purpose |
|---------|---------|
| `flutter pub get` | Fetch and update pub dependencies |
| `flutter run` | Run the application in debug mode |
| `flutter analyze` | Run static code analysis |
| `flutter test` | Run unit and widget test suite |
| `flutter build apk` | Package a production Android APK |
| `flutter build web` | Build optimized web application bundle |

---

## 🧪 Testing

The project includes unit and formatting tests to ensure calculation and alert logic remain stable:
* **Weekly Digest**: Tests digest creation and total savings formatting.
* **Budget Limits**: Asserts that notifications trigger precisely when limits are exceeded.
* **Price Drops**: Tests real-time alert thresholds when prices decrease.

Run the test suite using:
```bash
flutter test
```

---

## 📦 Admin Dashboard

A standalone companion web application is located in the `smartshopper_admin/` directory. It is built using HTML5, CSS3, and JavaScript, communicating directly with your Firebase backend:
* **Product Catalog**: Manage scraper outputs, pricing records, and product details.
* **Retailer Coordinates**: Adjust latitude and longitude values for geolocated stores.
* **Low-Cost Notifications**: Features a layout to copy JSON push notification payloads to your clipboard, allowing you to trigger FCM messages from the free Firebase Console without requiring paid Cloud Functions.
