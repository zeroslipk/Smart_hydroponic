# HydroPulse - Smart Hydroponic System

## Overview
**HydroPulse** (formerly AquaGrow) is a comprehensive mobile application for monitoring and controlling smart hydroponic systems. It integrates real-time sensor data, remote actuator control, and intelligent alerts to ensure optimal plant growth.

## Features

### 🖥️ UI & UX
*   **Modern Dashboard**: Real-time visualization of sensors (pH, Temperature, Water Level).
*   **Dark Mode**: Fully supported, dynamic dark mode for all screens.
*   **Liquid Animations**: Custom "blob" and "wave" animations for a premium feel.
*   **Rebranding**: Fresh "HydroPulse" identity with custom assets.

### 🔥 Mobile Tech
*   **Firebase Integration**: Real-time database for syncing sensor readings and actuator states.
*   **Hardware Control**: Toggle Pumps, Lights, and Fans directly from the app.
*   **Notifications**: Local push notifications for critical alerts (e.g., "Water Level Critical").

### 💾 Data & Logic
*   **SQLite Database**: Local storage for logs, history, and offline capabilities.
*   **MVVM Architecture**: Clean separation of UI (Screens) and Logic (ViewModels).
*   **Validation**: Robust input validation for all forms (Auth, Settings).

### 🤖 Smart Features
*   **Text-to-Speech (TTS)**: Voice announcements for system status.
*   **Speech Recognition**: Voice command support (experimental).

## Tech Stack
*   **Framework**: Flutter (Dart)
*   **Backend**: Firebase (Auth, Realtime Database)
*   **Local DB**: SQLite (`sqflite`)
*   **State Management**: `Provider`

## Testing
Comprehensive testing suite covering all layers:
*   **Unit Tests**: Business logic and parsing.
*   **Widget Tests**: UI rendering and interactions.
*   **Integration Tests**: Full end-to-end user flows on physical devices.

See [TESTING.md](TESTING.md) for detailed regression test cases.

## Setup & Running

1.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```

2.  **Run Application**:
    ```bash
    flutter run
    ```

3.  **Run Tests**:
    ```bash
    flutter test
    ```
