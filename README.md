# 📖 Quran App - Premium Islamic Companion

![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0%2B-0175C2?logo=dart)
![License](https://img.shields.io/badge/License-MIT-green)
![Build Status](https://github.com/muhammad1505/quran_app/actions/workflows/test.yml/badge.svg)
![Build Release](https://github.com/muhammad1505/quran_app/actions/workflows/build.yml/badge.svg)

A modern, aesthetically pleasing, and feature-rich Islamic application built with Flutter. Designed to provide a premium user experience with smooth animations, accurate prayer times, and a beautiful reading interface.

## ✨ Key Features

### 📖 Al-Quran Digital
*   **Beautiful Typography**: Uses **Amiri** font for Arabic script and **Poppins** for translations, ensuring readability and aesthetic appeal.
*   **Audio Murottal**: Integrated streaming/playback for Surahs using `just_audio`.
*   **Detail View**: Interactive verse list with "Basmalah" headers, gradient styling, and **Saheeh International** English translation.
*   **Custom Animations**: Bespoke loading indicators (pulsing Quran icon) and page transitions.

### 🕌 Prayer Times (Jadwal Sholat)
*   **Accurate Calculation**: Powered by the `adhan` library for precise timings based on location (Default: Jakarta, extensible to GPS).
*   **Next Prayer Highlight**: visually distinct card showing the countdown/time for the upcoming prayer.
*   **Dynamic UI**: Auto-highlighting of the current/next prayer time.

### 🧭 Qibla Compass (Refactored)
*   **High Precision**: Manually calculates Qibla direction using the **Haversine formula** (via `adhan` library) and GPS coordinates.
*   **Smooth UI**: Powered by `smooth_compass` for a jitter-free, fluid compass experience.
*   **Reliable**: Replaced legacy plugins with robust `geolocator` and `permission_handler` implementation.

### 🎨 Premium UI/UX
*   **Theming**: **Deep Emerald Green** & **Gold** palette for a luxurious Islamic feel.
*   **Dark Mode**: Fully supported system-wide Dark Mode.
*   **Modern Navigation**: Intuitive `NavigationBar` with custom icons.

## 🛠️ Tech Stack

*   **Framework**: Flutter (Dart)
*   **State Management**: `SetState` (Prototype)
*   **Audio**: `just_audio`
*   **Calculations**: `adhan` (Prayer Times & Qibla Math)
*   **Location & Sensors**: `geolocator`, `smooth_compass`, `permission_handler`
*   **Fonts**: `google_fonts` (Poppins & Amiri)
*   **Database**: `sqflite` (Ready for bookmarks/history)

## 🚀 Getting Started

1.  **Clone the repository**
    ```bash
    git clone https://github.com/muhammad1505/quran_app.git
    cd quran_app
    ```

2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

3.  **Run the App**
    ```bash
    flutter run
    ```

## 🤖 CI/CD (GitHub Actions)

This project includes a robust CI/CD pipeline:
*   **Testing**: Automatically runs `flutter analyze` and `flutter test` on every push.
*   **Building**: Automatically builds a Release APK (`split-per-abi`) when a tag (e.g., `v1.0.0`) is pushed.

## 📸 Screenshots

| Dashboard | Surah List | Detail & Audio | Qibla |
|-----------|------------|----------------|-------|
| *(Screenshot)* | *(Screenshot)* | *(Screenshot)* | *(Screenshot)* |

---
**Created with ❤️ by [Muhammad Yusuf Abdurrohman](https://github.com/muhammad1505)**