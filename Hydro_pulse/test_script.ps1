$logFile = "test_results.log"
Start-Transcript -Path $logFile -Force

Write-Host "=========================================="
Write-Host "      SMART HYDROPONIC AUTO-TEST          "
Write-Host "=========================================="
Write-Host "Date: $(Get-Date)"
Write-Host ""

# 1. Unit & Widget Tests
Write-Host "[1/2] Running Unit and Widget Tests..."
flutter test test/unit_test.dart test/widget_test.dart
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Unit/Widget Tests PASSED" -ForegroundColor Green
} else {
    Write-Host "❌ Unit/Widget Tests FAILED" -ForegroundColor Red
}

Write-Host ""

# 2. Integration Tests (Requires Emulator/Device)
Write-Host "[2/2] Running Integration Tests (E2E)..."
Write-Host "Note: This requires a connected device or emulator."
flutter test integration_test/app_test.dart
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Integration Tests PASSED" -ForegroundColor Green
} else {
    Write-Host "❌ Integration Tests FAILED" -ForegroundColor Red
}

Write-Host ""
Write-Host "=========================================="
Write-Host "Test Execution Completed."
Write-Host "Log saved to: $logFile"
Stop-Transcript
