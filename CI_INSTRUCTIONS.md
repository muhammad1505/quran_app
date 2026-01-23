# CI/CD Setup Instruction

The automated build workflow could not be pushed to `.github/workflows/` directly due to GitHub Token permission restrictions (missing `workflow` scope).

To enable the CI/CD pipeline for testing and building the APK:

1.  Go to your repository on GitHub.
2.  Create a new file at `.github/workflows/main.yml`.
3.  Paste the content below:

```yaml
name: Flutter CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
      - name: Install dependencies
        run: flutter pub get
      - name: Scaffold Platform Support
        run: flutter create .
      - name: Analyze
        run: flutter analyze
      - name: Test
        run: flutter test
      - name: Build APK
        run: flutter build apk --debug
      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: app-debug
          path: build/app/outputs/flutter-apk/app-debug.apk
```
