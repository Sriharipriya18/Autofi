<div align="left" style="position: relative;">
  <img src="https://raw.githubusercontent.com/PKief/vscode-material-icon-theme/ec559a9f6bfd399b82bb44393651661b08aaf7ba/icons/folder-markdown-open.svg" align="right" width="30%" style="margin: -20px 0 0 20px;">
  <h1>AUTOFI</h1>
  <p align="left">
    <em><code>? Local-first expense manager with offline AI insights.</code></em>
  </p>
  <p align="left">
    <img src="https://img.shields.io/github/license/Sriharipriya18/Autofi?style=default&logo=opensourceinitiative&logoColor=white&color=0080ff" alt="license">
    <img src="https://img.shields.io/github/last-commit/Sriharipriya18/Autofi?style=default&logo=git&logoColor=white&color=0080ff" alt="last-commit">
    <img src="https://img.shields.io/github/languages/top/Sriharipriya18/Autofi?style=default&color=0080ff" alt="repo-top-language">
    <img src="https://img.shields.io/github/languages/count/Sriharipriya18/Autofi?style=default&color=0080ff" alt="repo-language-count">
  </p>
</div>
<br clear="right">

## Overview
AutoFi is a Flutter-based personal expense manager focused on privacy and speed. It keeps data on-device, supports demo mode for quick onboarding, and generates offline AI insights without sending data to the cloud.

## Features
- Local PIN protection with optional biometrics
- Demo mode onboarding
- JSON backup and restore
- Offline AI insights: anomaly detection, month-over-month spikes, recurring payments
- AI tuning screen for thresholds

## Getting Started
### Prerequisites
- Flutter SDK
- Android Studio / Xcode (for platform builds)

### Install
```sh
flutter pub get
```

### Run
```sh
flutter run
```

### Build APK
```sh
flutter build apk --debug
flutter build apk --release
```

## Project Structure
```sh
lib/        # UI + business logic
android/    # Android native
ios/        # iOS native
assets/     # Images & icons
```

## License
See LICENSE.
