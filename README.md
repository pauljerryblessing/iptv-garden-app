# IPTV Garden 📺

A modern IPTV streaming app powered by the iptv-org public channel database (8,000+ free channels).

## Features

- 🌍 8,000+ free IPTV channels from iptv-org
- 📺 HD video playback with full controls (Chewie)
- 📅 EPG / programme guide
- ⭐ Favourites and recently watched
- 🎯 Cast to Chromecast devices
- 🌐 Filter by country and category
- 🔍 Live channel search
- 🌙 Dark theme

## Build the APK

### Via GitHub Actions (recommended)

1. Fork or push this repo to GitHub
2. Go to **Actions → Build APK → Run workflow**
3. Wait ~5 minutes for the build to complete
4. Download the APK from the **Releases** tab or the **Artifacts** of the workflow run

### Locally

Requirements: Flutter 3.22+, Android SDK, JDK 17

```bash
flutter pub get
flutter build apk --release
# APK: build/app/outputs/flutter-apk/app-release.apk
```

## Install

1. Enable **Settings → Security → Install unknown apps** on your Android device
2. Transfer the APK and tap to install
