# How to Run Tests - Quick Guide

## Method 1: Automated Test Script (Recommended) ⭐

This is the easiest way to run all tests automatically with ADB commands.

### Prerequisites
1. **Android SDK installed** (comes with Android Studio)
2. **Device connected** OR **Emulator running**
3. **USB Debugging enabled** on your device

### Step-by-Step Instructions

#### Step 1: Connect Your Device
- **Option A (Physical Device):**
  - Connect Android phone via USB
  - Enable USB Debugging in Developer Options
  - Verify connection: `adb devices`

- **Option B (Emulator):**
  - Open Android Studio
  - Start an Android Virtual Device (AVD)
  - Verify it's running: `adb devices`

#### Step 2: Navigate to Project Directory
```powershell
cd "D:\mobile project\Smart_hydroponic\aquagrow_app"
```

#### Step 3: Run the Test Script
```powershell
.\test_script.ps1
```

#### Step 4: View Results
- **Console Output:** Real-time test progress with color coding
- **Log File:** Detailed results saved to `test_results.log`
- **Summary:** Pass/fail counts at the end

### What Gets Tested
✅ Unit Tests  
✅ Widget Tests  
✅ APK Build  
✅ APK Installation  
✅ App Launch  
✅ ADB Automation Tests  
✅ Integration Tests  

---

## Method 2: Manual Test Execution

### Run All Tests
```powershell
cd aquagrow_app
flutter test
```

### Run Specific Test Types

#### Unit Tests Only
```powershell
flutter test test/unit_test.dart
```

#### Widget Tests Only
```powershell
flutter test test/widget_test.dart
```

#### Integration Tests Only
```powershell
# Requires device/emulator
flutter test integration_test/app_test.dart
```

#### Run Tests with Coverage
```powershell
flutter test --coverage
```

---

## Method 3: Run from Android Studio

1. **Open Project** in Android Studio
2. **Right-click** on `test/` folder
3. Select **"Run 'Tests in test'"**
4. Or click the green play button next to test functions

---

## Quick Verification Commands

### Check ADB Connection
```powershell
adb devices
```
**Expected Output:**
```
List of devices attached
emulator-5554    device
```

### Check Flutter Installation
```powershell
flutter doctor
```

### Check Test Files Exist
```powershell
# Windows PowerShell
Test-Path test\unit_test.dart
Test-Path test\widget_test.dart
Test-Path integration_test\app_test.dart
Test-Path test_script.ps1
```

---

## Troubleshooting

### ❌ "ADB not found"
**Solution:**
```powershell
# Add Android SDK to PATH
$env:Path += ";$env:ANDROID_HOME\platform-tools"

# Or set ANDROID_HOME if not set
$env:ANDROID_HOME = "C:\Users\YourName\AppData\Local\Android\Sdk"
```

### ❌ "No devices connected"
**Solution:**
1. Check USB cable connection
2. Enable USB Debugging on device
3. Accept USB debugging prompt on device
4. Verify: `adb devices`

### ❌ "Flutter not found"
**Solution:**
1. Ensure Flutter is installed
2. Add Flutter to PATH
3. Restart terminal/PowerShell
4. Verify: `flutter --version`

### ❌ "Test script execution policy error"
**Solution:**
```powershell
# Allow script execution (run as Administrator)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### ❌ "APK build fails"
**Solution:**
```powershell
flutter clean
flutter pub get
flutter build apk --debug
```

---

## Test Output Examples

### Successful Test Run
```
==========================================
   SMART HYDROPONIC AUTO-TEST SUITE       
==========================================
Date: 2024-01-15 14:30:00

✅ ADB Check : PASS
✅ Device Connection : PASS
✅ Unit Tests : PASS
✅ Widget Tests : PASS
✅ APK Build : PASS
✅ APK Installation : PASS
✅ App Launch : PASS
✅ Integration Tests : PASS

==========================================
TEST SUMMARY
==========================================
Total Tests: 12
Passed: 12
Failed: 0
```

### Failed Test Example
```
❌ Unit Tests : FAIL
   Exit code: 1
   Details: Test failed at line 45
```

---

## Test Files Location

- **Unit Tests:** `test/unit_test.dart`
- **Widget Tests:** `test/widget_test.dart`
- **Integration Tests:** `integration_test/app_test.dart`
- **Test Script:** `test_script.ps1`
- **Test Log:** `test_results.log` (generated after running script)

---

## Next Steps After Running Tests

1. **Review Results:**
   - Check console output
   - Open `test_results.log` for details

2. **Fix Failures:**
   - Read error messages in log
   - Fix code issues
   - Re-run tests

3. **Update Documentation:**
   - Update `TESTING.md` if needed
   - Document any new test cases

---

## Need Help?

- Check `TESTING.md` for detailed documentation
- Review `test_results.log` for error details
- Verify all prerequisites are met
- Ensure device/emulator is properly connected

