# Quran App (Al-Quran Terjemahan) - Project Overview

This is a comprehensive, feature-rich Islamic application built with Flutter. The app provides a digital Quran with translation, accurate prayer times, Qibla direction, daily prayers (Doa), and prayer guides. It is designed with a premium UI/UX, utilizing a Deep Emerald Green and Gold color palette.

## Technical Architecture

### Tech Stack
*   **Framework:** Flutter (Dart)
*   **Architecture:** Feature-first modular structure.
*   **State Management:** Currently utilizes `StatefulWidget` (`setState`) for local state. `flutter_bloc` is included in dependencies for potential future scalability.
*   **UI Framework:** Material 3 with custom theming (`AppTheme`).

### Key Libraries
*   **Core Logic:**
    *   `quran` (v1.2.0): Quran text and data.
    *   `adhan`: Prayer time calculations (high precision).
    *   `geolocator`: GPS coordinates for location-based services.
    *   `flutter_compass`: Compass sensor access for Qibla direction.
    *   `shared_preferences`: Local storage for settings (translation, qari, notifications).
*   **Media & UI:**
    *   `just_audio`: Audio streaming for Murottal.
    *   `google_fonts`: Typography (Poppins for Latin, Amiri for Arabic).
*   **Permissions:**
    *   `permission_handler`: Managing Android permissions (Location, Notifications).

### Project Structure
```
lib/
├── core/
│   ├── theme/          # AppTheme, Colors, Typography
│   └── widgets/        # Shared components (e.g., CustomLoadingWidget)
├── features/
│   ├── quran/          # Surah list, Detail view, Audio player
│   ├── prayer_times/   # Schedule calculations, UI display
│   ├── qibla/          # Compass logic (Manual calculation + Sensor stream)
│   ├── doa/            # Daily prayers list
│   ├── prayer_guide/   # Sholat step-by-step guide
│   └── settings/       # App preferences (Translation, Audio, Notif)
└── main.dart           # Entry point, Routing, Splash Screen
```

## Features

1.  **Al-Quran:**
    *   Full list of 114 Surahs.
    *   Detail view with Arabic text (Amiri font), translation (Indonesian/English), and audio playback.
    *   Custom "Basmalah" header and gradient styling.
2.  **Jadwal Sholat (Prayer Times):**
    *   Visual "Next Prayer" countdown.
    *   Daily schedule list based on current location.
3.  **Arah Kiblat (Qibla):**
    *   Custom implementation using `flutter_compass` and `geolocator`.
    *   Manual Qibla angle calculation (Haversine formula).
    *   Smooth animated compass UI.
4.  **Doa Harian:** Collection of daily prayers with Arabic and translation.
5.  **Tuntunan Sholat:** Step-by-step prayer guide.
6.  **Settings:**
    *   Toggle Notifications.
    *   Switch Translation (Indonesian / Saheeh International).
    *   Select Qari (Mishary, Sudais, Ghamdi).
    *   Volume Control.

## CI/CD Workflow (GitHub Actions)

The project uses a CI/CD pipeline defined in `.github/workflows/build.yml`.

1.  **Build & Release (`build.yml`):**
    *   Triggers on: Push to `main` or manual dispatch.
    *   Jobs:
        *   Installs dependencies (`flutter pub get`).
        *   Scaffolds platform support (`flutter create .`).
        *   Runs analysis (`flutter analyze`) and tests (`flutter test`).
        *   Builds Release APK (`flutter build apk --release`).
        *   Uploads the APK artifact.

## Setup & Development

### Prerequisites
*   Flutter SDK (Stable channel)
*   Dart SDK
*   Android SDK (for building APKs)

### Common Commands

**Install Dependencies:**
```bash
flutter pub get
```

**Run Development Mode:**
```bash
flutter run
```

**Run Tests:**
```bash
flutter test
```

**Analyze Code:**
```bash
flutter analyze
```

**Build Release APK:**
```bash
flutter build apk --release
```

## Configuration Details

*   **Android Manifest:** `android/app/src/main/AndroidManifest.xml` (Permissions: `INTERNET`, `ACCESS_FINE_LOCATION`, `POST_NOTIFICATIONS`).
*   **Assets:**
    *   `assets/`: Splash screen.
    *   `assets/illustrations/`: Prayer guide images.
    *   `assets/translations/`: JSON translation files.
