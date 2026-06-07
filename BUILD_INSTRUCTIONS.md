# IPTV Garden — Build Instructions

## Prerequisites

Install these tools before building:

| Tool | Version | Download |
|------|---------|----------|
| Flutter SDK | 3.22+ | https://docs.flutter.dev/get-started/install |
| Android Studio | Latest | https://developer.android.com/studio |
| Java JDK | 17+ | https://adoptium.net |
| Git | Any | https://git-scm.com |

Verify your setup:
```bash
flutter doctor -v
```
All checkmarks should be green before proceeding.

---

## 1. Open the Project

Open the `iptv_garden_app/` folder in Android Studio or VS Code.

---

## 2. Install Dependencies

```bash
cd iptv_garden_app
flutter pub get
```

---

## 3. Run in Development (Debug)

### On a connected Android phone/tablet:
```bash
flutter run
```

### On Android TV emulator:
1. Open Android Studio → AVD Manager
2. Create device → TV → Android TV (1080p)
3. Select Android API 30+ system image
4. Then run:
```bash
flutter run -d <tv-device-id>
```

List available devices:
```bash
flutter devices
```

---

## 4. Build the APK (Release)

### Quick unsigned APK (for sideloading):
```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Split APKs by architecture (smaller file sizes):
```bash
flutter build apk --split-per-abi --release
```

Outputs:
- `app-armeabi-v7a-release.apk` — 32-bit ARM (older devices)
- `app-arm64-v8a-release.apk`  — 64-bit ARM (most modern phones)
- `app-x86_64-release.apk`     — x86_64 (emulators)

> **Tip:** For most modern Android phones, use `app-arm64-v8a-release.apk`

### Android App Bundle (for smaller installs, but needs Play Store):
```bash
flutter build appbundle --release
```

---

## 5. Sign the APK (Optional but Recommended)

Unsigned APKs install fine for personal use. To sign for distribution:

### Generate a keystore:
```bash
keytool -genkey -v \
  -keystore iptv_garden.jks \
  -alias iptv_garden \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

### Create `android/key.properties`:
```
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=iptv_garden
storeFile=../iptv_garden.jks
```

### Update `android/app/build.gradle` — add before `android {`:
```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

Add inside `android { ... }`:
```groovy
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}
buildTypes {
    release {
        signingConfig signingConfigs.release
        minifyEnabled false
    }
}
```

Then build:
```bash
flutter build apk --release
```

---

## 6. Install on Device

### Via ADB (USB cable):
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Manually on device:
1. Copy the APK to your phone
2. Enable "Install unknown apps" in Settings → Security
3. Open the APK file and install

### On Android TV:
```bash
adb connect <TV-IP-ADDRESS>:5555
adb install app-release.apk
```

Find your TV's IP in: Settings → Network → About

---

## 7. Build for Android TV Specifically

The app already includes `leanback` support in the manifest. To target TV:

```bash
flutter build apk --release --target-platform android-arm64
```

Enable developer mode on Android TV:
- Settings → Device Preferences → About → Build (click 7 times)
- Settings → Device Preferences → Developer Options → USB Debugging ON
- Settings → Device Preferences → Developer Options → Unknown Sources ON

---

## 8. Chromecast Setup

The app includes the Google Cast SDK. To use with your own Cast Receiver:

1. Register your receiver app at https://cast.google.com/publish
2. Replace `"CC1AD845"` in `android/app/src/main/java/com/iptvgarden/app/CastOptionsProvider.kt` with your App ID
3. For testing, use the default receiver `CC1AD845` (works with most Chromecast devices)

---

## 9. Custom IPTV Source

To add your own M3U playlist URL:
- Launch the app → Settings → "Add Custom M3U URL"
- Or hardcode your source in `lib/models/playlist_source.dart`

Default sources used:
- `https://iptv-org.github.io/iptv/index.m3u` — 8,000+ free channels
- Per-category URLs from iptv-org GitHub

---

## 10. Project Structure

```
iptv_garden_app/
├── android/                     # Android-specific config
│   ├── app/
│   │   ├── build.gradle         # App-level Gradle config
│   │   └── src/main/
│   │       ├── AndroidManifest.xml
│   │       ├── java/com/iptvgarden/app/
│   │       │   ├── MainActivity.kt
│   │       │   └── CastOptionsProvider.kt   # Chromecast config
│   │       └── res/
│   │           ├── values/styles.xml
│   │           └── xml/network_security_config.xml
│   └── build.gradle             # Project-level Gradle
│
├── lib/
│   ├── main.dart                # App entry point
│   ├── theme/
│   │   └── app_theme.dart       # Dark Netflix-style theme
│   ├── models/
│   │   ├── channel.dart         # Channel data model
│   │   ├── category.dart        # Category definitions
│   │   └── playlist_source.dart # IPTV Garden source URLs
│   ├── services/
│   │   ├── iptv_service.dart    # Fetch + cache channels
│   │   └── m3u_parser.dart      # M3U playlist parser
│   ├── providers/               # State management
│   │   ├── channel_provider.dart
│   │   ├── favorites_provider.dart
│   │   ├── recent_provider.dart
│   │   ├── settings_provider.dart
│   │   └── cast_provider.dart
│   ├── screens/
│   │   ├── home/home_screen.dart         # Main browsing screen
│   │   ├── player/player_screen.dart     # Full-screen video player
│   │   ├── search/search_screen.dart     # Channel search
│   │   ├── favorites/favorites_screen.dart
│   │   ├── recent/recent_screen.dart
│   │   ├── country/country_screen.dart   # Browse by country
│   │   └── settings/settings_screen.dart
│   ├── widgets/
│   │   ├── channel_card.dart      # Netflix-style card
│   │   ├── channel_list_tile.dart # List row with logo
│   │   ├── channel_logo.dart      # Cached logo widget
│   │   ├── channel_grid.dart      # Category rows grid
│   │   ├── category_bar.dart      # Horizontal category chips
│   │   ├── featured_banner.dart   # Hero banner carousel
│   │   └── section_header.dart    # Row section title
│   └── utils/
│       └── format_utils.dart
│
├── pubspec.yaml                 # Dependencies
└── BUILD_INSTRUCTIONS.md        # This file
```

---

## 11. Common Errors & Fixes

| Error | Fix |
|-------|-----|
| `SDK location not found` | Add `sdk.dir` to `android/local.properties` |
| `compileSdkVersion not found` | Run `flutter doctor`, install Android SDK 34 |
| `Gradle build failed` | Run `cd android && ./gradlew clean`, then `flutter build apk` |
| `JAVA_HOME not set` | Set `JAVA_HOME` to your JDK 17 path |
| `flutter: command not found` | Add Flutter `bin/` to your `PATH` |
| `Minimum SDK version` error | Already set to `minSdk 21` (Android 5.0+) |
| Streams not loading | Check internet permission in Manifest (already added) |

---

## 12. Performance Tips

- Use `--release` flag for all real-device testing
- The default playlist has 8,000+ channels — first load takes ~15s on slow connections
- Cache expires every 6 hours automatically
- Use "Split per ABI" builds for smallest APK size
- Enable R8/ProGuard for production builds (already configured in `proguard-rules.pro`)

---

## Minimum Requirements

| Spec | Minimum |
|------|---------|
| Android version | 5.0 (API 21) |
| RAM | 1 GB |
| Storage | 50 MB |
| Internet | Required (streaming) |
| Architecture | ARM or x86_64 |
