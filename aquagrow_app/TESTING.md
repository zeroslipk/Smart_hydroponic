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

## 3. How to Execute Tests

### Run All Tests
```powershell
flutter test
```

### Run Integration Tests
*Note: Requires a connected device or emulator.*
```powershell
flutter test integration_test/app_test.dart
```

### Run Unit/Widget Tests Only
```powershell
flutter test test/unit_test.dart
flutter test test/widget_test.dart
```

## 4. Test Environment
- **SDK**: Flutter 3.35.6
- **Database**: `sqflite_common_ffi` (Windows/Linux), `sqflite` (Android/iOS)
- **Mocking**: `mockito` used for Firebase services in unit tests.
