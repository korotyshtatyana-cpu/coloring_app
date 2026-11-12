# Firebase Crashlytics Setup & Deployment Guide

This document describes how to configure, build, and deploy **Firebase Crashlytics** crash reporting for the "Раскраска PRO" application.

---

## 1. Firebase Console Setup

1. Log in to [Firebase Console](https://console.firebase.google.com/).
2. Create **two separate Firebase projects**:
   - `coloring-pro-dev` (for `dev` flavor testing)
   - `coloring-pro-prod` (for `prod` production builds)
3. In each Firebase project:
   - Add an **Android app** with package name `com.korotysh.tatyana.coloringpro`.
   - Add an **iOS app** with bundle identifier `com.korotysh.tatyana.coloringpro`.
   - Enable **Firebase Crashlytics** under *Build -> Crashlytics*.

---

## 2. FlutterFire Configuration & Placement

### Automated CLI Setup
Install and run the FlutterFire CLI:

```bash
# Install FlutterFire CLI globally
dart pub global activate flutterfire_cli

# Configure dev flavor
flutterfire configure \
  --project=coloring-pro-dev \
  --out=lib/firebase_options_dev.dart \
  --ios-bundle-id=com.korotysh.tatyana.coloringpro \
  --android-package-name=com.korotysh.tatyana.coloringpro

# Configure prod flavor
flutterfire configure \
  --project=coloring-pro-prod \
  --out=lib/firebase_options_prod.dart \
  --ios-bundle-id=com.korotysh.tatyana.coloringpro \
  --android-package-name=com.korotysh.tatyana.coloringpro
```

### Configuration Files Placement
Place the generated Google configuration files into flavor directories:

- **Android:**
  - `android/app/src/dev/google-services.json`
  - `android/app/src/prod/google-services.json`
- **iOS:**
  - `ios/config/dev/GoogleService-Info.plist`
  - `ios/config/prod/GoogleService-Info.plist`

---

## 3. Environment Variables Configuration (.env)

Populate the corresponding keys in `.env.dev` and `.env.prod`:

```env
FIREBASE_PROJECT_ID=coloring-pro-dev
FIREBASE_MESSAGING_SENDER_ID=1080576463832
FIREBASE_STORAGE_BUCKET=coloring-pro-dev.appspot.com
FIREBASE_API_KEY_ANDROID=AIzaSy...
FIREBASE_APP_ID_ANDROID=1:1080576463832:android:abcdef
FIREBASE_API_KEY_IOS=AIzaSy...
FIREBASE_APP_ID_IOS=1:1080576463832:ios:abcdef
```

If keys are omitted or empty, `DataDI` automatically falls back to `NoopCrashReporter` without throwing an exception or breaking the app.

---

## 4. Release Builds & Symbol Upload

To produce release builds with code obfuscation and automatic Crashlytics mapping upload:

```bash
# Build Android App Bundle for prod flavor with obfuscation
flutter build appbundle \
  --flavor prod \
  --target lib/main_prod.dart \
  --obfuscate \
  --split-debug-info=build/symbols
```

The Crashlytics Gradle plugin (`com.google.firebase.crashlytics`) automatically uploads `mapping.txt` and native symbols during release builds when configured in `android/app/build.gradle.kts`.

---

## 5. Google Play Data Safety & Privacy Policy Updates

### Google Play Data Safety Section
In Google Play Console under **Policy -> App content -> Data safety**:

- **Data Collected:**
  - **App info and performance:** *Crash logs*, *Diagnostics*.
  - **Identifiers:** *User IDs* (if authenticated).
- **Data Usage:** *App functionality*, *Analytics*, *Developer communications*.
- **Data Security:** *Encrypted in transit* (HTTPS/TLS).

### Privacy Policy
Update your Privacy Policy to state:
> "We use Firebase Crashlytics to collect anonymized crash reports and performance diagnostics to improve app stability. Collected diagnostic data includes device state, stack traces, and anonymized identifiers. No personal content or payment tokens are logged or shared."

---

## 6. Verification Checklist

1. [ ] Create `coloring-pro-dev` and `coloring-pro-prod` Firebase projects.
2. [ ] Download and place `google-services.json` in `android/app/src/dev/` and `android/app/src/prod/`.
3. [ ] Fill out `FIREBASE_*` environment keys in `.env.dev` and `.env.prod`.
4. [ ] Run `flutter run --flavor dev -t lib/main_dev.dart`.
5. [ ] Open Profile / Settings in Debug mode and tap **"Debug: Test Crashlytics Error"**.
6. [ ] Verify that the test exception appears in the Firebase Crashlytics dashboard within 5 minutes.
