# How to Run App in Android Studio

## ✅ Current Status

- ✅ Android Emulator is running (Android 13, API 33)
- ✅ Flutter setup is complete
- ✅ SQLite database integrated
- ✅ Firebase configured

## 🚀 Running in Android Studio

### Method 1: Using Android Studio UI (Recommended)

1. **Open the Project in Android Studio**
   - File → Open → Select `aquagrow_app` folder
   - Wait for Gradle sync to complete

2. **Select the Emulator**
   - Look at the top toolbar
   - Click the device dropdown (should show "sdk gphone64 x86 64")
   - If not visible, go to **Run → Select Device**

3. **Run the App**
   - Click the **Run** button (green play icon ▶️) in the toolbar
   - Or press **Shift + F10**
   - Or go to **Run → Run 'main.dart'**

4. **Wait for Build**
   - First build may take 2-5 minutes
   - You'll see build progress in the bottom status bar
   - The app will launch automatically when ready

### Method 2: Using Terminal in Android Studio

1. **Open Terminal in Android Studio**
   - View → Tool Windows → Terminal
   - Or press `Alt + F12`

2. **Run Flutter Command**
   ```bash
   flutter run
   ```
   - Or specify device:
   ```bash
   flutter run -d emulator-5554
   ```

### Method 3: Using Run Configuration

1. **Create Run Configuration**
   - Run → Edit Configurations
   - Click **+** → **Flutter**
   - Name: "Run App"
   - Dart entrypoint: `lib/main.dart`
   - Click **OK**

2. **Run**
   - Select the configuration from dropdown
   - Click Run button

## 📱 What to Expect

1. **Build Process:**
   - Gradle build (first time: 2-5 minutes)
   - Flutter build
   - App installation on emulator

2. **App Launch:**
   - Splash screen with animations
   - Authentication screen
   - Dashboard with sensor data

3. **Features Available:**
   - Real-time sensor monitoring (from Firebase)
   - SQLite database storing all data locally
   - Navigation between all screens
   - Sensor readings, alerts, control panel, analytics

## 🔧 Troubleshooting

### If Build Fails:

1. **Clean Build:**
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Invalidate Caches:**
   - File → Invalidate Caches → Invalidate and Restart

3. **Check Gradle:**
   - File → Settings → Build → Gradle
   - Ensure Gradle is properly configured

### If Emulator Not Detected:

1. **Restart Emulator:**
   - Close emulator
   - Start from Device Manager

2. **Check ADB:**
   ```bash
   adb devices
   ```

### If App Crashes:

1. **Check Logs:**
   - View → Tool Windows → Logcat
   - Look for error messages

2. **Check Firebase:**
   - Ensure Firebase is properly configured
   - Check `google-services.json` is in place

## ✅ Current Emulator Status

- **Device:** sdk gphone64 x86 64
- **ID:** emulator-5554
- **Android Version:** Android 13 (API 33)
- **Status:** ✅ Running

## 🎯 Quick Run Command

If you prefer command line, the app is already building/running via:
```bash
flutter run -d emulator-5554
```

## 📝 Notes

- First build takes longer (2-5 minutes)
- Subsequent builds are faster (30 seconds - 2 minutes)
- Hot reload is available (press `r` in terminal after app runs)
- Hot restart: press `R` in terminal






