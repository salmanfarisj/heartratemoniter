# PulseX — Heart Rate Monitor & Activity Tracker

A Flutter app that streams heart-rate data from a Bluetooth Low Energy (BLE) chest strap or watch, classifies each BPM into a training zone (Rest / Fat Burn / Cardio / Peak), logs it to a local SQLite database, and lets you review weekly trends, activities, and settings — with one-tap CSV export.

> Rebranded from the original `heartratemoniter` Flutter starter. The app id, bundle, and UI strings now all read **PulseX**.

<p align="left">
  <img src="assets/icons/pulsex_app_icon.png" width="96" alt="PulseX app icon">
</p>

---

## Features

- **Live BLE streaming** — `flutter_blue_plus` discovers nearby GATT Heart Rate Service devices (`0x180D`), subscribes to the Heart Rate Measurement characteristic (`0x2A37`), and pushes BPM into a `HeartRateBloc` in real time.
- **Heart-rate zones** — every reading is bucketed into Rest / Fat Burn / Cardio / Peak based on the user's max HR (auto-promoted from observed peaks). Falls back to a Tanaka-style 180 BPM default when max HR is unknown so readings never go unclassified.
- **Activity tracking** — manual activity log (type, duration, notes) persisted alongside HR samples; today's activities and today's stats are the home tab's primary surfaces.
- **History & trends** — `fl_chart` line/bar charts for weekly BPM trend, weekly aggregated stats, and HR zone distribution.
- **CSV export** — `share_plus` writes a session CSV to a temp file and hands it off to the system share sheet from the Settings page.
- **Local-first persistence** — `sqflite` for readings, activities, and settings. No accounts, no cloud.
- **Permission-aware** — `permission_handler` for Bluetooth + Local Network (iOS) / `BLUETOOTH_SCAN` + `BLUETOOTH_CONNECT` (Android 12+) prompts, with a graceful empty-state until both are granted.
- **Material 3 + branded** — single light theme, cyan → blue `pulsexBlue` accent, `pulsex_logo` widget (heart + ECG mark) rendered in the header.

---

## Tech Stack

| Layer | Library |
|---|---|
| Framework | Flutter 3.48+ / Dart `^3.13.0` |
| State management | `flutter_bloc` + `equatable` |
| Navigation | `go_router` |
| Local DB | `sqflite` + `path` |
| Charts | `fl_chart` |
| Typography | `google_fonts` |
| Bluetooth | `flutter_blue_plus` |
| Permissions | `permission_handler` |
| Sharing / files | `share_plus`, `path_provider`, `uuid`, `intl` |

Lints: `flutter_lints: ^5.0.0`.

---

## Architecture

Feature-first clean-lite layout under `lib/`:

```
lib/
├── main.dart                     # Composes repos, blocs, and MaterialApp.router
├── core/
│   ├── constants/               # AppColors, AppTypography, AppSpacing, AppRadius
│   ├── database/database_helper.dart   # sqflite init + schema migrations
│   ├── router/app_router.dart     # go_router config (shell + tab routes)
│   ├── theme/app_theme.dart      # Material 3 ThemeData
│   └── widgets/                  # pulsex_logo, wahoo_header
└── features/
    ├── home/                     # Live HR + device picker
    │   ├── data/                 # BluetoothService, repositories
    │   ├── domain/               # HeartRateReading, HeartRateZone, HeartRateStats, HeartRateDevice, DeviceTelemetry
    │   └── presentation/         # HomePage, DeviceBottomSheet, HeartRateBloc
    ├── activities/               # Activity log + types
    ├── history/                  # Weekly trends + aggregations
    ├── settings/                 # Max HR, CSV export
    └── shell/                    # Bottom-nav shell page
```

Each feature follows `data / domain / presentation` separation; repositories own the DB, blocs own the state, widgets stay thin. `SettingsBloc` is constructed eagerly in `main.dart` so `HeartRateBloc` can dispatch auto-promote events back into it.

---

## Prerequisites

- Flutter 3.48 or newer (`flutter --version`).
- Dart `^3.13.0` (bundled with Flutter).
- For iOS builds: Xcode 26+, CocoaPods 1.17+, an Apple ID signed into Xcode (free tier works — see `docs/physical-install-guide.md`).
- For Android builds: Android Studio with the Flutter + Android SDKs installed, an Android device or emulator.
- A BLE heart-rate device (or any GATT peripheral exposing the standard Heart Rate Service `0x180D`) for live streaming. The app still runs without one — you can review history and add activities offline.

---

## Run It

```bash
flutter pub get
flutter run                      # auto-picks attached device / emulator
```

Useful variants:

```bash
flutter run -d ios              # iPhone / iPad
flutter run -d android         # Android device / emulator
flutter run -d linux           # desktop (Linux only — macOS/Windows/web not configured)
flutter run --release          # release-mode on the default device
```

Hot reload: press <kbd>r</kbd> in the terminal. Hot restart: <kbd>R</kbd>. Quit: <kbd>q</kbd>.

---

## Build & Install

### Android

```bash
flutter build apk --release
# or: flutter build appbundle --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### iOS (development export — works on a free Apple ID)

The full walkthrough lives in [`docs/physical-install-guide.md`](docs/physical-install-guide.md). TL;DR:

```bash
# One-time: replace the placeholder bundle id
sed -i '' 's/com\.example\.heartratemoniter/com.<your-bundle-id>/g' \
  ios/Runner.xcodeproj/project.pbxproj

# Build a development-signed .ipa
flutter build ipa --release --export-method=development

# Install + launch on a paired iPhone
UDID="<your-device-udid>"
xcrun devicectl device install app --device "$UDID" build/ios/ipa/pulsex.ipa
xcrun devicectl device process launch --device "$UDID" com.<your-bundle-id>
```

> The free Apple ID tier signs with a **development** profile that's valid for ~7 days. Re-running it is harmless (see the guide for renewal + paid-team upgrade paths).

### Linux

```bash
flutter build linux --release
./build/linux/x64/release/bundle/pulsex
```

---

## Permissions

| Permission | Why |
|---|---|
| Bluetooth (iOS Local Network + Android 12+ `BLUETOOTH_SCAN`/`BLUETOOTH_CONNECT`) | Discover and subscribe to BLE heart-rate devices. |
| Android ≤11: `ACCESS_FINE_LOCATION` | Legacy BLE scan requirement. |
| Storage / share intent | CSV export uses the system share sheet, not file picker. |

On first launch, grant both BLE prompts. If you decline, the device list will stay empty — re-enable in **Settings → Privacy & Security → Bluetooth** / **Local Network**.

---

## Project Status & Notes

- This is the **PulseX** codebase. The on-disk directory name (`heartratemoniter/`) and iOS Xcode project name still reflect the original starter; renaming those is intentional under-scope.
- The CocoaPods integration warning Flutter prints at the end of every iOS build is unrelated to success and is tracked in `docs/physical-install-guide.md`.

---

## References

- [Flutter docs](https://docs.flutter.dev/)
- [`flutter_blue_plus`](https://pub.dev/packages/flutter_blue_plus)
- [`flutter_bloc`](https://pub.dev/packages/flutter_bloc) · [`go_router`](https://pub.dev/packages/go_router)
- [`fl_chart`](https://pub.dev/packages/fl_chart) · [`sqflite`](https://pub.dev/packages/sqflite)
- [Bluetooth GATT Heart Rate Service (`0x180D`)](https://www.bluetooth.com/specifications/specs/heart-rate-service-1-0/)
- [iOS Local Network privacy](https://developer.apple.com/documentation/bundleresources/information_property_list/nsbonjourdescription) · [Android 12 Bluetooth permissions](https://developer.android.com/guide/topics/connectivity/bluetooth/permissions)

---

## License

Add your license of choice (MIT, BSD-3-Clause, Apache-2.0, …) before public release — none is currently checked in.