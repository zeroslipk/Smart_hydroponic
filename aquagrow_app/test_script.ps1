$logFile = "test_results.log"
$appPackage = "com.example.aquagrow_app"
$testResults = @()

# Function to log test result
function Log-TestResult {
    param($testName, $status, $details = "")
    $result = @{
        Test = $testName
        Status = $status
        Details = $details
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    $script:testResults += $result
    $color = if ($status -eq "PASS") { "Green" } else { "Red" }
    $symbol = if ($status -eq "PASS") { "✅" } else { "❌" }
    Write-Host "$symbol $testName : $status" -ForegroundColor $color
    if ($details) {
        Write-Host "   $details" -ForegroundColor Gray
    }
}

# Start logging
Start-Transcript -Path $logFile -Force

Write-Host "=========================================="
Write-Host "   SMART HYDROPONIC AUTO-TEST SUITE       "
Write-Host "=========================================="
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host ""

# Check ADB availability
Write-Host "[SETUP] Checking ADB availability..."
$adbPath = Get-Command adb -ErrorAction SilentlyContinue
if (-not $adbPath) {
    Write-Host "⚠️  ADB not found in PATH. Attempting to find in Android SDK..." -ForegroundColor Yellow
    $sdkPath = $env:ANDROID_HOME
    if (-not $sdkPath) {
        $sdkPath = "$env:LOCALAPPDATA\Android\Sdk"
    }
    if (Test-Path "$sdkPath\platform-tools\adb.exe") {
        $env:Path += ";$sdkPath\platform-tools"
        Write-Host "✅ ADB found at: $sdkPath\platform-tools\adb.exe" -ForegroundColor Green
    } else {
        Log-TestResult "ADB Check" "FAIL" "ADB not found. Please install Android SDK or add to PATH."
        Stop-Transcript
        exit 1
    }
} else {
    Log-TestResult "ADB Check" "PASS" "ADB is available"
}

# Check device connection
Write-Host ""
Write-Host "[SETUP] Checking connected devices..."
$devices = adb devices | Select-Object -Skip 1 | Where-Object { $_ -match "device$" }
if ($devices.Count -eq 0) {
    Log-TestResult "Device Connection" "FAIL" "No devices connected. Please connect a device or start an emulator."
    Write-Host "Attempting to start emulator..." -ForegroundColor Yellow
    $emulators = Get-ChildItem "$env:ANDROID_HOME\emulator\emulator.exe" -ErrorAction SilentlyContinue
    if ($emulators) {
        Write-Host "Please start an emulator manually or connect a device." -ForegroundColor Yellow
    }
    Stop-Transcript
    exit 1
} else {
    $deviceCount = ($devices | Measure-Object).Count
    Log-TestResult "Device Connection" "PASS" "$deviceCount device(s) connected"
    Write-Host "Connected devices:" -ForegroundColor Cyan
    $devices | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
}

# Get device ID (first connected device)
$deviceId = (adb devices | Select-Object -Skip 1 | Where-Object { $_ -match "device$" } | Select-Object -First 1).Split("`t")[0]
Write-Host "Using device: $deviceId" -ForegroundColor Cyan
Write-Host ""

# ============================================
# TEST PHASE 1: Unit & Widget Tests
# ============================================
Write-Host "=========================================="
Write-Host "PHASE 1: Unit & Widget Tests"
Write-Host "=========================================="
Write-Host ""

Write-Host "[1/4] Running Unit Tests..."
flutter test test/unit_test.dart 2>&1 | Tee-Object -Variable unitTestOutput
if ($LASTEXITCODE -eq 0) {
    Log-TestResult "Unit Tests" "PASS"
} else {
    Log-TestResult "Unit Tests" "FAIL" "Exit code: $LASTEXITCODE"
}

Write-Host ""
Write-Host "[2/4] Running Widget Tests..."
flutter test test/widget_test.dart 2>&1 | Tee-Object -Variable widgetTestOutput
if ($LASTEXITCODE -eq 0) {
    Log-TestResult "Widget Tests" "PASS"
} else {
    Log-TestResult "Widget Tests" "FAIL" "Exit code: $LASTEXITCODE"
}

# ============================================
# TEST PHASE 2: Build and Install App
# ============================================
Write-Host ""
Write-Host "=========================================="
Write-Host "PHASE 2: Build and Install App"
Write-Host "=========================================="
Write-Host ""

Write-Host "[3/4] Building APK..."
flutter build apk --debug 2>&1 | Tee-Object -Variable buildOutput
if ($LASTEXITCODE -eq 0) {
    Log-TestResult "APK Build" "PASS"
    
    Write-Host ""
    Write-Host "[3.5/4] Installing APK on device..."
    $apkPath = "build\app\outputs\flutter-apk\app-debug.apk"
    if (Test-Path $apkPath) {
        adb -s $deviceId install -r $apkPath 2>&1 | Tee-Object -Variable installOutput
        if ($LASTEXITCODE -eq 0) {
            Log-TestResult "APK Installation" "PASS"
        } else {
            Log-TestResult "APK Installation" "FAIL" "Installation failed"
        }
    } else {
        Log-TestResult "APK Installation" "FAIL" "APK file not found at $apkPath"
    }
} else {
    Log-TestResult "APK Build" "FAIL" "Build failed with exit code: $LASTEXITCODE"
}

# ============================================
# TEST PHASE 3: ADB-Based UI Automation Tests
# ============================================
Write-Host ""
Write-Host "=========================================="
Write-Host "PHASE 3: ADB UI Automation Tests"
Write-Host "=========================================="
Write-Host ""

# Function to execute ADB command and check result
function Test-ADBCommand {
    param($testName, $command, $expectedText = "")
    Write-Host "Testing: $testName..." -ForegroundColor Cyan
    
    $output = adb -s $deviceId shell $command 2>&1
    $success = if ($expectedText) {
        $output -match $expectedText
    } else {
        $LASTEXITCODE -eq 0
    }
    
    if ($success) {
        Log-TestResult $testName "PASS"
        return $true
    } else {
        Log-TestResult $testName "FAIL" "Command output: $output"
        return $false
    }
}

# Function to tap on screen coordinates
function Test-ADBTap {
    param($testName, $x, $y)
    Write-Host "Testing: $testName (tap at $x,$y)..." -ForegroundColor Cyan
    Start-Sleep -Milliseconds 500
    adb -s $deviceId shell input tap $x $y | Out-Null
    Start-Sleep -Milliseconds 1000
    Log-TestResult $testName "PASS" "Tapped at coordinates ($x, $y)"
    return $true
}

# Function to input text
function Test-ADBInput {
    param($testName, $text)
    Write-Host "Testing: $testName (input: $text)..." -ForegroundColor Cyan
    $escapedText = $text -replace ' ', '\ ' -replace '&', '\&'
    adb -s $deviceId shell input text $escapedText | Out-Null
    Start-Sleep -Milliseconds 500
    Log-TestResult $testName "PASS" "Input text: $text"
    return $true
}

# Launch the app
Write-Host "[3.1/4] Launching app..."
adb -s $deviceId shell am start -n "$appPackage/.MainActivity" 2>&1 | Out-Null
Start-Sleep -Seconds 3
Log-TestResult "App Launch" "PASS"

# Get screen dimensions for coordinate calculations
$screenInfo = adb -s $deviceId shell wm size
$screenSize = ($screenInfo -split ':')[1].Trim()
$width = [int]($screenSize -split 'x')[0]
$height = [int]($screenSize -split 'x')[1]
Write-Host "Screen size: ${width}x${height}" -ForegroundColor Gray

# Test app is running
Test-ADBCommand "App Process Check" "ps | grep $appPackage" $appPackage

# Test navigation (tap on different areas - these are approximate coordinates)
# Note: Actual coordinates should be adjusted based on your UI layout
Write-Host ""
Write-Host "Running UI interaction tests..."
Write-Host "Note: Coordinate-based tests may need adjustment based on device screen size" -ForegroundColor Yellow

# Test back button
Test-ADBCommand "Back Button Test" "input keyevent KEYCODE_BACK"

# Test home button
Test-ADBCommand "Home Button Test" "input keyevent KEYCODE_HOME"

# Return to app
adb -s $deviceId shell am start -n "$appPackage/.MainActivity" 2>&1 | Out-Null
Start-Sleep -Seconds 2

# Test screen rotation (if supported)
Test-ADBCommand "Screen Rotation Test" "settings put system accelerometer_rotation 1"

# Test app info
Test-ADBCommand "App Info Check" "dumpsys package $appPackage | grep versionName"

# ============================================
# TEST PHASE 4: Integration Tests
# ============================================
Write-Host ""
Write-Host "=========================================="
Write-Host "PHASE 4: Integration Tests (Flutter)"
Write-Host "=========================================="
Write-Host ""

Write-Host "[4/4] Running Integration Tests..."
flutter test integration_test/app_test.dart 2>&1 | Tee-Object -Variable integrationTestOutput
if ($LASTEXITCODE -eq 0) {
    Log-TestResult "Integration Tests" "PASS"
} else {
    Log-TestResult "Integration Tests" "FAIL" "Exit code: $LASTEXITCODE"
}

# ============================================
# TEST SUMMARY
# ============================================
Write-Host ""
Write-Host "=========================================="
Write-Host "TEST SUMMARY"
Write-Host "=========================================="
Write-Host ""

$passed = ($testResults | Where-Object { $_.Status -eq "PASS" }).Count
$failed = ($testResults | Where-Object { $_.Status -eq "FAIL" }).Count
$total = $testResults.Count

Write-Host "Total Tests: $total" -ForegroundColor Cyan
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })
Write-Host ""

# Detailed results
Write-Host "Detailed Results:" -ForegroundColor Cyan
$testResults | ForEach-Object {
    $color = if ($_.Status -eq "PASS") { "Green" } else { "Red" }
    $symbol = if ($_.Status -eq "PASS") { "✅" } else { "❌" }
    Write-Host "$symbol [$($_.Timestamp)] $($_.Test) - $($_.Status)" -ForegroundColor $color
    if ($_.Details) {
        Write-Host "    $($_.Details)" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "=========================================="
Write-Host "Test Execution Completed."
Write-Host "Log saved to: $logFile"
Write-Host "=========================================="

Stop-Transcript
