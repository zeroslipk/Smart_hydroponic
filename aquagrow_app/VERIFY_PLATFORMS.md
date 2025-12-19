# Platform Verification Guide

## 🎯 Quick Verification Steps

Run these commands to verify everything is set up correctly:

### 1. Check Flutter Setup

```bash
flutter doctor -v
```

**Expected:** No critical issues, all tools installed

---

### 2. Verify Dependencies

```bash
flutter pub get
flutter analyze
```

**Expected:** No errors, all dependencies resolved

---

### 3. Check Android Configuration

```bash
# Verify Android SDK versions
cd android
cat local.properties 2>/dev/null | grep sdk.dir || echo "Run: flutter doctor to check Android SDK"
cd ..
```

**Requirements:**
- Android SDK installed
- Android SDK Platform 33+ (for notification permission)
- Android Emulator or device connected

---

### 4. Check iOS Configuration

```bash
# Verify iOS setup
cd ios
pod --version  # Should show CocoaPods version
ls Pods 2>/dev/null || echo "Run: pod install"
cd ..
```

**Requirements:**
- Xcode installed (Mac only)
- CocoaPods installed
- iOS device connected (for testing)

---

### 5. Verify Permissions

#### Android Permissions
**File:** `android/app/src/main/AndroidManifest.xml`

**Should contain:**
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

#### iOS Permissions
**File:** `ios/Runner/Info.plist`

**Should contain:**
- `NSMicrophoneUsageDescription`
- `NSSpeechRecognitionUsageDescription`
- `UIBackgroundModes` (array with `fetch` and `remote-notification`)

---

## 🚀 Testing on Each Platform

### Android Emulator

**Prerequisites:**
- Android Studio installed
- Android Emulator created (Android 8.0+ recommended)

**Steps:**
```bash
# 1. Start emulator from Android Studio
# OR
emulator -avd <your_avd_name>

# 2. Verify device is connected
flutter devices

# 3. Run app
flutter run
```

**What to Test:**
- ✅ App launches
- ✅ Firebase connects (sensors show data)
- ✅ Notifications permission requested (Android 13+)
- ✅ Speech permission requested (when using voice)
- ✅ All features work

---

### Android Physical Device

**Prerequisites:**
- Android device (any version, but Android 13+ for notification testing)
- USB debugging enabled
- Developer options enabled

**Steps:**
```bash
# 1. Connect device via USB
# 2. Enable USB debugging on device
# 3. Verify device is connected
flutter devices

# 4. Run app
flutter run
```

**What to Test:**
- ✅ App installs
- ✅ App launches
- ✅ Firebase connects
- ✅ Permissions requested correctly
- ✅ Notifications work (especially background)
- ✅ Performance is smooth
- ✅ All features work

**Android 13+ Specific:**
- Notification permission dialog appears
- Can grant/deny permission
- Notifications work after granting

---

### iOS Physical Device

**Prerequisites:**
- Mac computer
- Xcode installed
- iOS device (iPhone/iPad)
- Apple Developer account (free account works for device testing)

**Steps:**
```bash
# 1. Connect iOS device to Mac
# 2. Trust computer on device
# 3. Open Xcode
open ios/Runner.xcworkspace

# 4. In Xcode:
#    - Select your device (top bar)
#    - Select "Runner" scheme
#    - Click Run button (or Cmd+R)

# OR use Flutter CLI:
flutter run
```

**What to Test:**
- ✅ App builds successfully
- ✅ App installs on device
- ✅ App launches
- ✅ Firebase connects
- ✅ Permissions requested correctly
- ✅ Notifications work (test on device, not simulator)
- ✅ Speech recognition works
- ✅ Performance is smooth
- ✅ All features work

**Important Notes:**
- ⚠️ iOS Simulator doesn't show local notifications reliably
- ✅ Must test notifications on physical device
- ✅ First build may take longer (code signing)

---

## ✅ Configuration Checklist

### Android

- [ ] `minSdkVersion` is 21+ (Android 5.0)
- [ ] `targetSdkVersion` is 33+ (Android 13)
- [ ] `compileSdkVersion` is 33+
- [ ] `POST_NOTIFICATIONS` permission in AndroidManifest.xml
- [ ] `RECORD_AUDIO` permission in AndroidManifest.xml
- [ ] `INTERNET` permission in AndroidManifest.xml
- [ ] Google Services plugin configured (for Firebase)

### iOS

- [ ] Minimum iOS version is 11.0+ (for speech_to_text)
- [ ] Podfile platform is `:ios, '11.0'` or higher
- [ ] CocoaPods installed and pods installed (`pod install`)
- [ ] Info.plist has microphone permission description
- [ ] Info.plist has speech recognition permission description
- [ ] Info.plist has UIBackgroundModes configured
- [ ] Xcode project opens without errors

### Both Platforms

- [ ] All dependencies in pubspec.yaml
- [ ] `flutter pub get` runs successfully
- [ ] `flutter analyze` shows no errors
- [ ] Firebase configured (google-services.json / GoogleService-Info.plist)

---

## 🔧 Quick Fix Commands

### If Android Build Fails

```bash
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
flutter run
```

### If iOS Build Fails

```bash
flutter clean
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter run
```

### If Dependencies Fail

```bash
flutter clean
flutter pub cache repair
flutter pub get
```

---

## 📱 Platform-Specific Requirements Summary

| Requirement | Android Emulator | Android Device | iOS Device |
|------------|------------------|----------------|------------|
| **Minimum OS** | Android 8.0+ | Android 5.0+ | iOS 12.0+ |
| **Permissions** | Auto/Manual | Runtime (13+) | Runtime |
| **Notifications** | ✅ Works | ✅ Works | ✅ Works (device only) |
| **Speech** | ✅ Works | ✅ Works | ✅ Works |
| **Firebase** | ✅ Works | ✅ Works | ✅ Works |
| **File Export** | ✅ Works | ✅ Works | ✅ Works |
| **Background** | ✅ Limited | ✅ Full | ✅ Full |

---

## 🎯 Success Criteria

The app is ready when:

- ✅ Runs on Android emulator without crashes
- ✅ Runs on Android physical device without crashes
- ✅ Runs on iOS physical device without crashes
- ✅ All permissions requested correctly
- ✅ All features work on each platform
- ✅ No console errors during normal use
- ✅ Performance is acceptable on all platforms

---

## 🆘 Troubleshooting

### "No devices found"

**Android:**
- Enable USB debugging
- Run `adb devices` to check connection
- Restart adb: `adb kill-server && adb start-server`

**iOS:**
- Trust computer on device
- Check Xcode → Window → Devices and Simulators
- Restart Xcode

### "Permission denied" errors

- Grant permissions when app requests them
- Check Settings → Apps → Permissions
- Restart app after granting permissions

### Build errors

- Run `flutter clean`
- Run `flutter pub get`
- Check `flutter doctor` for configuration issues
- Verify platform-specific setup (Android SDK, Xcode, etc.)

---

## 📝 Next Steps

1. ✅ Run verification commands above
2. ✅ Test on Android emulator first (quickest)
3. ✅ Test on Android physical device (full features)
4. ✅ Test on iOS physical device (full features)
5. ✅ Document any platform-specific issues found
