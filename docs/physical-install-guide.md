# Physical Device Installation Guide

End-to-end walkthrough of how this Flutter app was installed on a physical iPhone, from "fresh checkout" to "launches from home screen without the Mac attached".

## Environment

| Tool | Version |
|---|---|
| macOS | 26.6.2 (Darwin) |
| Flutter | 3.48.0-1.0.pre-75 (stable) |
| Dart | 3.13.3 |
| Xcode | 27.0 |
| CocoaPods | 1.17.0 |
| Target device | iPhone 13 (iPhone14,5), iOS 18 |
| Bundle ID | `com.salmanfaris.pulsex` |
| Apple ID | Personal (no paid enrollment — `$99/yr` not required for this path) |

The exact commands shown are reproducible on any macOS machine with Xcode installed. The free Apple ID tier works because we sign with a **development** certificate + **development** provisioning profile, not App Store distribution.

---

## TL;DR

```bash
# 1. Configure bundle ID once (Apple refuses "com.example.*")
sed -i '' 's/com\.example\.heartratemoniter/com.salmanfaris.pulsex/g' \
  ios/Runner.xcodeproj/project.pbxproj

# 2. Build the .ipa (development export method — works on free Apple ID)
flutter build ipa --release --export-method=development

# 3. Find your iPhone
xcrun devicectl list devices

# 4. Install + launch
UDID="00008110-000C6851213A401E"
xcrun devicectl device install app --device "$UDID" build/ios/ipa/pulsex.ipa
xcrun devicectl device process launch --device "$UDID" com.salmanfaris.pulsex
```

That's the whole journey. The rest of this document explains every obstacle encountered and how each was resolved.

---

## Why a normal `flutter build ipa` doesn't work on a free Apple ID

When you run `flutter build ipa --release` (no `--export-method`), Flutter asks Xcode to create an **App Store distribution** provisioning profile. Apple rejects this on a free-tier team:

```
error: exportArchive Team "Salman Faris" does not have permission
       to create "iOS App Store" provisioning profiles.
error: exportArchive No signing certificate "iOS Distribution" found
```

Two changes fix it:
1. **Bundle ID**: Apple's placeholder `com.example.*` is reserved; replace with your own.
2. **Export method**: `--export-method=development` signs with the dev certificate that's already on your Mac.

---

## Step 1 — Bundle ID rename

The default `flutter create` produces `com.example.<appname>`. Apple's servers will refuse to issue any provisioning profile for `com.example.*`. Rename to something globally unique:

```bash
cd ios
sed -i '' 's/com\.example\.heartratemoniter/com.salmanfaris.pulsex/g' \
  Runner.xcodeproj/project.pbxproj
```

Verify all references updated:

```bash
grep PRODUCT_BUNDLE_IDENTIFIER Runner.xcodeproj/project.pbxproj
```

Expected (note the parallel `.RunnerTests` targets are renamed too):

```
PRODUCT_BUNDLE_IDENTIFIER = com.salmanfaris.pulsex;
PRODUCT_BUNDLE_IDENTIFIER = com.salmanfaris.pulsex.RunnerTests;
```

---

## Step 2 — Authorize Xcode with your Apple ID

One-time setup. Without it, signing fails silently with `Unable to log in with account '<apple-id>'`.

1. Open the workspace:
   ```bash
   open ios/Runner.xcworkspace
   ```
2. **Xcode → Settings → Accounts → `+` → Apple ID** → sign in with your Apple ID.
3. Complete the 2FA prompt on your iPhone.
5. Select **Runner** target → **Signing & Capabilities** → set **Team** to your Apple ID; **Bundle Identifier** should auto-match the rename in Step 1.
6. Click the **refresh/triangle** icon next to the Team dropdown. This forces Xcode to create the **iOS App Development** provisioning profile for the new bundle ID.

If Xcode shows `Your team has no devices registered`, plug your iPhone in over USB once — Xcode will detect it and register the UDID with your free team.

---

## Step 3 — Build the release `.ipa`

```bash
cd "/Users/salman/HR ACTIVE/pulsex"
flutter build ipa --release --export-method=development
```

What this does:

1. `flutter pub get` → resolves Dart dependencies.
2. `pod install` → installs iOS native pods.
3. `xcodebuild archive` → compiles a release-mode binary, writes `build/ios/archive/Runner.xcarchive`.
4. `xcodebuild -exportArchive` → packages the archive as `build/ios/ipa/pulsex.ipa`, signed with your **development** certificate.

Expected output (last few lines):

```
Xcode archive done.                                         18.8s
✓ Built build/ios/archive/Runner.xcarchive (176.7MB)
Building debugging IPA...                                           7.5s
✓ Built IPA to build/ios/ipa (7.5MB)
```

Final artifact:

```
build/ios/ipa/pulsex.ipa    # ~7 MB
```

> ⚠️ Flutter prints this warning every build, it's unrelated to success:
>
> ```
> All plugins found for ios are Swift Packages, but your project still has
> CocoaPods integration. ... Migrate to Swift Package Manager manually.
> ```
>
> Ignored — does not block build or install. Address separately if/when
> the Flutter community migrates `flutter_blue_plus` plugins off CocoaPods.

---

## Step 4 — Install on the physical device

### Find the device UDID

```bash
xcrun devicectl list devices
```

Output (truncated):

```
Name              Identifier                                    State       Model
Salman (2)        00008110-000C6851213A401E (UDID)              connected   iPhone 13 (iPhone14,5)
```

State must be `connected`. If your phone shows `unavailable` or `shutdown`, plug it in over USB once — the Mac needs to pair the device's UDID with the dev cert.

### Install the IPA

```bash
UDID="00008110-000C6851213A401E"
xcrun devicectl device install app --device "$UDID" \
  build/ios/ipa/pulsex.ipa
```

Success output:

```
App installed:
• bundleID: com.salmanfaris.pulsex
• installationURL: file:///private/var/containers/Bundle/Application/.../Runner.app/
```

### Launch

```bash
xcrun devicectl device process launch --device "$UDID" \
  com.salmanfaris.pulsex
```

Success output:

```
Launched application with com.salmanfaris.pulsex bundle identifier.
```

The Flutter placeholder icon (yellow ship in blue square) appears on the home screen and the app foregrounds within ~1 second.

---

## Step 5 — Grant permissions on first launch

iOS 16+ requires explicit consent for both **Bluetooth** and **Local Network** before any BLE scan can begin. On first launch:

1. App shows an empty screen with the title bar.
2. iOS pops a **"Heartratemoniter Would Like to Use Bluetooth"** dialog → tap **Allow**.
3. iOS pops a **"Heartratemoniter Would Like to Find and Connect to Devices on Your Local Network"** dialog → tap **Allow**.

If you miss either prompt:

**Settings → Privacy & Security → Local Network → Heartratemoniter → ON**
**Settings → Privacy & Security → Bluetooth → Heartratemoniter → ON**

For Android migration later (different OS-level rules):

- Android 12+ → `BLUETOOTH_SCAN` + `BLUETOOTH_CONNECT` runtime permissions.
- Android ≤11 → also requires `ACCESS_FINE_LOCATION` for BLE scan (legacy requirement).

---

## Why the home screen launches now (and didn't before)

A debug build (`flutter run`) is signed with the **development** certificate tied to your Mac. Apple's iOS device daemon verifies the embedded provisioning profile when the app launches; without the paired Mac reachable on the network, it silently refuses. That's the error you saw: *"build in profile or release modes to enable launching from the homescreen"*.

A release build signed with a **development** profile sidesteps this — the dev profile just registers a set of allowed device UDIDs, not a specific Mac. Once installed, iOS only checks the certificate's expiry date, which is what makes this work.

---

## Re-signing before the 7-day expiry

Apple's free-tier **development provisioning profiles** expire after **7 days** from issuance. When that happens, the app refuses to launch with:

> "This app cannot be opened because the developer cannot be verified."

You have two options:

### Option A — Re-install the same `.ipa`

The provisioning profile is reissued on every install. Re-running the install command from Step 4 extends the app by another 7 days:

```bash
xcrun devicectl device install app --device "$UDID" \
  build/ios/ipa/pulsex.ipa
```

You can keep doing this indefinitely until the **certificate** itself expires (~1 year from creation). Then:

**Xcode → Settings → Accounts → select your Apple ID → Manage Certificates → `+` → Apple Development**

This regenerates the dev cert, after which re-running the install command extends the app for another year.

### Option B — Paid Apple Developer Program ($99/year)

Pays for itself only if you're shipping to actual users. Benefits:

- **1-year** provisioning profile validity (vs 7 days).
- **Apple Distribution** certificate → can produce App Store / Ad-hoc `.ipa` files.
- **TestFlight** for beta distribution.
- 100 registered device UUIDs (vs 3 on free tier).

To upgrade: https://developer.apple.com/programs/enroll. After enrolling, regenerate the provisioning profile in Xcode → Signing & Capabilities → Team → refresh icon, then `flutter build ipa --release` (drop `--export-method=development`).

---

## Files modified during this process

| Path | Change |
|---|---|
| `ios/Runner.xcodeproj/project.pbxproj` | `com.salmanfaris.pulsex` → `com.salmanfaris.pulsex` (and `.RunnerTests`) |

No source code or `Info.plist` was edited. The only persistent change is the bundle ID; everything else (cert, profile, `.ipa`) is regenerated per build.

---

## Reproducibility checklist

To rebuild from scratch on a new Mac:

- [ ] Xcode 26+ installed.
- [ ] `flutter --version` → 3.48+.
- [ ] `pod --version` → 1.17+.
- [ ] Apple ID signed in: **Xcode → Settings → Accounts**.
- [ ] Bundle ID replaced with a globally unique string.
- [ ] iPhone paired at least once over USB.
- [ ] Phone's **Settings → Privacy & Security → Developer Mode → ON**.

Then run the build from Step 3 onward. Total wall-clock: ~35 seconds for the build, ~5 seconds for the install.

---

## References

- [`flutter build ipa`](https://docs.flutter.dev/deployment/ios) — Flutter docs.
- [`xcrun devicectl`](https://developer.apple.com/documentation/devicectl) — Apple command-line device control.
- [Apple Developer Program enrollment](https://developer.apple.com/programs/enroll/) — for paid team.
- [Apple: Switching from CocoaPods to Swift Package Manager](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app) — the CocoaPods warning noted above.