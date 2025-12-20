# Testing Strategy & Regression Test Cases

## 1. Testing Overview
The **HydroPulse** project employs a multi-layered testing strategy to ensure reliability, stability, and UI correctness.
- **Unit Tests**: Verify business logic, data models, and utility functions.
- **Widget Tests**: Verify individual UI components and screen rendering.
- **Integration Tests**: Verify complete user flows on a real device/emulator.

## 2. Regression Test Cases

### 2.1 Unit Tests (Logic & Models)
| ID | Test Case | Description | Expected Result | Status |
|----|-----------|-------------|-----------------|--------|
| U-01 | **Actuator Model Parsing** | Parse `ActuatorData` from JSON. | Object fields match JSON values. | ✅ PASS |
| U-02 | **Sensor Model Parsing** | Parse `SensorReading` from JSON. | Object matches; timestamp is valid. | ✅ PASS |
| U-03 | **Validation Logic** | Test `Validators.validateEmail`. | Reject invalid emails; accept valid ones. | ✅ PASS |
| U-04 | **Password Strength** | Test `Validators.validateStrongPassword`. | Require 8 chars, 1 upper, 1 number. | ✅ PASS |

### 2.2 Widget Tests (UI Components)
| ID | Test Case | Description | Expected Result | Status |
|----|-----------|-------------|-----------------|--------|
| W-01 | **Dashboard Loading** | Pump `DashboardScreen`. | Title "HydroPulse System" is visible. | ✅ PASS |
| W-02 | **Theme Provider** | Toggle Dark Mode. | `Theme.of(context).cardColor` updates. | ✅ PASS |
| W-03 | **Sensor Cards** | Render `SensorCard`. | Icon and Value are displayed correctly. | ✅ PASS |

### 2.3 Integration Tests (End-to-End)
| ID | Test Case | Description | Expected Result | Status |
|----|-----------|-------------|-----------------|--------|
| I-01 | **App Launch** | Launch app from cold state. | Splash Screen appears, then Auth/Dashboard. | ✅ PASS |
| I-02 | **Dashboard Navigation** | Navigate to Dashboard (Skipping Auth if logged in). | "HydroPulse System" text is found. | ✅ PASS |
| I-03 | **Pump Actuation** | Tap "Pump" quick action button. | Button toggles state (UI feedback). | ✅ PASS |
| I-04 | **Navigation Bar** | Tap "Analytics" tab. | Navigation switches to Analytics Screen. | ✅ PASS |

### 2.4 ADB Automation Tests (Device Interaction)
| ID | Test Case | Description | Expected Result | Status |
|----|-----------|-------------|-----------------|--------|
| A-01 | **ADB Availability** | Check if ADB is installed and accessible. | ADB command executes successfully. | ✅ PASS |
| A-02 | **Device Connection** | Verify at least one device/emulator is connected. | Device list shows connected device(s). | ✅ PASS |
| A-03 | **APK Build** | Build debug APK for testing. | APK file generated successfully. | ✅ PASS |
| A-04 | **APK Installation** | Install APK on connected device. | App installed without errors. | ✅ PASS |
| A-05 | **App Launch (ADB)** | Launch app using ADB command. | App starts and MainActivity is active. | ✅ PASS |
| A-06 | **Process Check** | Verify app process is running. | App package found in process list. | ✅ PASS |
| A-07 | **Back Button** | Test hardware back button functionality. | Back button event sent successfully. | ✅ PASS |
| A-08 | **Home Button** | Test home button navigation. | App moves to background. | ✅ PASS |
| A-09 | **Screen Info** | Get device screen dimensions. | Screen size retrieved (width x height). | ✅ PASS |
| A-10 | **App Info** | Retrieve app version information. | Version name and code retrieved. | ✅ PASS |
| A-11 | **Screen Rotation** | Test screen rotation settings. | Rotation setting updated. | ✅ PASS |

## 3. How to Execute Tests

### 3.1 Automated Test Script (Recommended)
The project includes a comprehensive PowerShell test script that automates all test phases using ADB commands.

**Prerequisites:**
- Android SDK installed (ADB in PATH or ANDROID_HOME set)
- At least one Android device connected via USB or emulator running
- Flutter SDK installed and in PATH

**Run the Auto-Test Script:**
```powershell
cd aquagrow_app
.\test_script.ps1
```

**What the script does:**
1. **Phase 1: Unit & Widget Tests**
   - Runs unit tests (`test/unit_test.dart`)
   - Runs widget tests (`test/widget_test.dart`)

2. **Phase 2: Build and Install**
   - Builds debug APK
   - Installs APK on connected device

3. **Phase 3: ADB UI Automation**
   - Checks ADB availability
   - Verifies device connection
   - Launches app
   - Tests app process
   - Tests hardware buttons (back, home)
   - Retrieves device and app information

4. **Phase 4: Integration Tests**
   - Runs Flutter integration tests (`integration_test/app_test.dart`)

**Output:**
- Test results displayed in console with color coding
- Detailed log saved to `test_results.log`
- Summary report with pass/fail counts

### 3.2 Manual Test Execution

#### Run All Tests
```powershell
flutter test
```

#### Run Integration Tests
*Note: Requires a connected device or emulator.*
```powershell
flutter test integration_test/app_test.dart
```

#### Run Unit/Widget Tests Only
```powershell
flutter test test/unit_test.dart
flutter test test/widget_test.dart
```

### 3.3 ADB Commands for Manual Testing

**Check connected devices:**
```powershell
adb devices
```

**Install APK:**
```powershell
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

**Launch app:**
```powershell
adb shell am start -n com.example.aquagrow_app/.MainActivity
```

**Get app info:**
```powershell
adb shell dumpsys package com.example.aquagrow_app | grep versionName
```

**Get screen size:**
```powershell
adb shell wm size
```

**Send tap event:**
```powershell
adb shell input tap <x> <y>
```

**Send text input:**
```powershell
adb shell input text "your_text_here"
```

**Send back button:**
```powershell
adb shell input keyevent KEYCODE_BACK
```

**Send home button:**
```powershell
adb shell input keyevent KEYCODE_HOME
```

## 4. Test Environment
- **SDK**: Flutter 3.35.6
- **Database**: `sqflite_common_ffi` (Windows/Linux), `sqflite` (Android/iOS)
- **Mocking**: `mockito` used for Firebase services in unit tests.
- **ADB**: Android Debug Bridge for device automation
- **Platform**: Windows PowerShell (test script), Linux bash (alternative script available)

## 5. Test Coverage Summary

### Unit Tests
- ✅ Model parsing and serialization
- ✅ Validation logic (email, password, name, phone, date, time)
- ✅ Business logic functions

### Widget Tests
- ✅ Screen rendering
- ✅ Theme switching
- ✅ Component display

### Integration Tests
- ✅ App launch flow
- ✅ Navigation between screens
- ✅ User interactions (button taps, form inputs)

### ADB Automation Tests
- ✅ Device connectivity
- ✅ APK installation
- ✅ App launch and process management
- ✅ Hardware button simulation
- ✅ Device information retrieval

## 6. Troubleshooting

### ADB Not Found
- Ensure Android SDK is installed
- Add `platform-tools` to PATH: `$env:Path += ";$env:ANDROID_HOME\platform-tools"`
- Or set `ANDROID_HOME` environment variable

### No Devices Connected
- Connect device via USB with USB debugging enabled
- Or start an Android emulator
- Verify with: `adb devices`

### Test Script Fails
- Check Flutter is in PATH: `flutter --version`
- Verify device is connected: `adb devices`
- Check app package name matches in script: `com.example.aquagrow_app`
- Review `test_results.log` for detailed error messages
