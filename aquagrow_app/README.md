# AquaGrow - Smart Hydroponic System

**Student Name:** Youssef
**Project:** Smart Hydroponic Monitoring & Control App

## 📱 Project Overview
AquaGrow is a Flutter-based mobile application designed to monitor and control a hydroponic farming system. It integrates with **Firebase Realtime Database** for sensor data (pH, TDS, Temperature, Water Level) and **SQLite** for local logging and offline alerts.

### 🌟 Key Features
- **Real-time Monitoring:** Live dashboard for vital hydroponic sensors.
- **Control Panel:** Manual and scheduled control for Pump, Lights, and Fans.
- **Voice Commands:** Full voice control for checking status and toggling devices.
- **Alert System:** Local notifications for critical sensor thresholds.
- **Analytics:** Charts and historical data visualization.
- **Offline Support:** Local caching of sensor readings and logs.

---

## 🛠️ Setup & Installation
1.  **Prerequisites:**
    - Flutter SDK (3.x+)
    - Android Studio with Emulator or Physical Device
    - Firebase Project Configured (`google-services.json`)

2.  **Installation:**
    ```bash
    # Clone the repo
    git clone https://github.com/zeroslipk/Smart_hydroponic.git
    cd aquagrow_app

    # Install dependencies
    flutter pub get
    ```

3.  **Running the App:**
    ```bash
    flutter run
    ```

4.  **Running Tests:**
    ```powershell
    # Run the automated test suite
    .\test_script.ps1
    ```

---

## 🧪 Testing & Quality Assurance
The project includes a comprehensive test suite (Requirement #5):
- **Unit Tests:** `test/unit_test.dart` (Models & Logic)
- **Widget Tests:** `test/widget_test.dart` (UI Rendering)
- **Integration Tests:** `integration_test/app_test.dart` (End-to-End flows)

Run all tests with the provided PowerShell script: `.\test_script.ps1`

---

## 📝 Troubleshooting
- **Permission Errors (TTS/Voice):** Ensure you grant Microphone and "Access list of apps" permissions on MIUI devices.
- **Build Errors:** If you see `desugaring` errors, ensure your `minSdkVersion` is set to 21 or higher.

