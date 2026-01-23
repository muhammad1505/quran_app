# 📖 Quran App - Premium Islamic Companion

![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0%2B-0175C2?logo=dart)
![License](https://img.shields.io/badge/License-MIT-green)
![Build Status](https://github.com/muhammad1505/quran_app/actions/workflows/test.yml/badge.svg)

A modern, aesthetically pleasing, and feature-rich Islamic application built with Flutter. Designed to provide a premium user experience with smooth animations, accurate prayer times, and a beautiful reading interface.

## ✨ Key Features

### 📖 Al-Quran Digital
*   **Beautiful Typography**: Uses **Amiri** font for Arabic script and **Poppins** for translations, ensuring readability and aesthetic appeal.
*   **Audio Murottal**: Integrated streaming/playback for Surahs using `just_audio`.
*   **Detail View**: Interactive verse list with "Basmalah" headers and gradient styling.
*   **Translation**: Complete Indonesian translation (Kemenag).

### 🕌 Prayer Times (Jadwal Sholat)
*   **Accurate Calculation**: Powered by the `adhan` library for precise timings based on location (Default: Jakarta, extensible to GPS).
*   **Next Prayer Highlight**: visually distinct card showing the countdown/time for the upcoming prayer.
*   **Dynamic UI**: Auto-highlighting of the current/next prayer time.

### 🧭 Qibla Compass
*   **Real-time Sensor**: Uses device accelerometer and magnetometer via `flutter_qiblah`.
*   **Visual Feedback**: Large, clear degree indicators with a modern compass UI.
*   **Animation**: Smooth rotation and calibration alerts.

### 🎨 Premium UI/UX
*   **Theming**: **Deep Emerald Green** & **Gold** palette for a luxurious Islamic feel.
*   **Dark Mode**: Fully supported system-wide Dark Mode.
*   **Custom Animations**: Bespoke loading indicators (pulsing Quran icon) and page transitions.
*   **Modern Navigation**: Intuitive `NavigationBar` with custom icons.

## 🛠️ Tech Stack

*   **Framework**: Flutter (Dart)
*   **State Management**: `SetState` (Prototype) / structured for Bloc/Provider.
*   **Audio**: `just_audio`
*   **Calculations**: `adhan` (Prayer Times), `flutter_qiblah` (Compass)
*   **Fonts**: `google_fonts` (Poppins & Amiri)
*   **Icons**: `cupertino_icons` & Material Symbols

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

This project includes a CI/CD pipeline setup for:
*   **Testing**: Automatically runs `flutter analyze` and `flutter test` on every push.
*   **Building**: Automatically builds a Release APK when a tag is pushed or manually triggered.

## 📸 Screenshots

| Dashboard | Surah List | Detail & Audio | Qibla |
|-----------|------------|----------------|-------|
| *(Screenshot)* | *(Screenshot)* | *(Screenshot)* | *(Screenshot)* |

---
**Created with ❤️ by [Muhammad Yusuf Abdurrohman](https://github.com/muhammad1505)**
