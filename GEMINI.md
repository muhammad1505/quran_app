# GEMINI.md

## Project Overview

This is a Flutter project for a Quran reading application. It follows a feature-driven architecture that shares similarities with the Clean Architecture pattern, with code organized into `core` and `features` directories.

The project is structured as follows:

-   `lib/`: Contains the main source code of the application.
    -   `core/`: Core components like dependency injection (`di`), services, settings, themes, and shared widgets.
    -   `features/`: Contains the different features of the application, such as `quran`, `prayer_times`, `qibla`, etc. Each feature directory contains its own presentation layer, including pages and Blocs/Cubits.

## Building and Running

The following commands can be used to build and run the project, based on the `README.md` and GitHub Actions workflows (`.github/workflows/`):

-   **Install dependencies:**
    ```bash
    flutter pub get
    ```

-   **Analyze project:**
    ```bash
    flutter analyze
    ```

-   **Run tests:**
    ```bash
    flutter test
    ```

-   **Build Release APK:**
    ```bash
    flutter build apk --release
    ```

## Development Conventions

-   **Architecture**: The project is structured by features. A `core` directory holds shared logic like services, settings, and theme data. The `features` directory contains individual modules of the app (e.g., `quran`, `prayer_times`, `home`).
-   **State Management**: The project uses the BLoC pattern, specifically `Cubit`, for state management. For example, `QuranAudioCubit` (`lib/features/quran/presentation/bloc/audio/quran_audio_cubit.dart`) manages the state for the Quran audio player.
-   **Dependency Injection**: The project uses `get_it` and `injectable` for managing dependencies. The setup is configured in `lib/core/di/injection.dart`.
-   **Data Persistence**: Simple data persistence, such as bookmarks and user settings, is handled using the `shared_preferences` package, as seen in `lib/core/services/bookmark_service.dart`.
-   **UI Structure**: The UI is built with Flutter widgets. Each feature typically has a `presentation/pages` directory containing the main screens for that feature. Reusable UI components are likely found within a feature's `widgets` directory or the global `lib/core/widgets` directory.
-   **Asynchronous Operations**: Asynchronous operations are handled using `Future` and `async/await`, with state changes managed through Cubits.
