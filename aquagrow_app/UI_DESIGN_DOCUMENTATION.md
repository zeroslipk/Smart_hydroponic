# UI Design Documentation
## SMART Hydroponic System - AquaGrow App

---

## Table of Contents
1. [Design Overview](#design-overview)
2. [Color Scheme & Theme](#color-scheme--theme)
3. [Screen Descriptions](#screen-descriptions)
4. [Navigation Flow](#navigation-flow)
5. [Missing Screenshots](#missing-screenshots)

---

## Design Overview

The AquaGrow Smart Hydroponic System app features a modern, clean interface with a teal and white color scheme. The design utilizes glassmorphism effects, smooth animations, and intuitive navigation to provide an optimal user experience for managing a hydroponic system.

### Design Principles
- **Clean & Modern**: Minimalist design with clear visual hierarchy
- **Intuitive Navigation**: Bottom navigation bar with 5 main sections
- **Real-time Updates**: Live data indicators and status updates
- **Accessibility**: Clear icons, readable fonts, and color-coded status indicators
- **Responsive**: Adapts to different screen sizes

---

## Color Scheme & Theme

### Primary Colors
- **Teal/Cyan**: `#00BCD4` - Primary action color, headers, active states
- **Dark Teal**: `#006064` - Headers, gradients
- **White**: `#FFFFFF` - Background, text on dark backgrounds
- **Light Gray**: `#F5F5F5` - Card backgrounds, inactive states

### Status Colors
- **Green**: `#66BB6A` - Active/Running status, optimal conditions
- **Red**: `#EF5350` - Critical alerts, emergency stops
- **Orange/Yellow**: `#FFA726` - Warnings, medium priority alerts
- **Gray**: `#9E9E9E` - Inactive/Stopped status

### Typography
- **Headers**: Bold, 20-24px
- **Body Text**: Regular, 14-16px
- **Labels**: Medium weight, 12-14px
- **Values**: Bold, 18-32px for sensor readings

---

## Screen Descriptions

### 1. Splash Screen ⚠️ **SCREENSHOT NEEDED**

**Purpose**: First screen users see when launching the app. Displays app branding with loading animation.

**Key Features**:
- App logo with animated loading indicator
- Smooth transition animation (water waves, bubbles)
- Auto-navigation to Auth or Dashboard after 4 seconds
- Plant growth animation effect

**UI Elements**:
- Centered app logo/icon
- Animated water wave background
- Floating bubble animations
- Loading indicator
- App name: "AquaGrow" or "HydroPulse"

**Navigation**:
- Automatically navigates to:
  - `AuthScreen` if user not logged in
  - `DashboardScreen` if user is authenticated

**Screenshot Status**: ❌ **MISSING - Please take screenshot**

---

### 2. Authentication Screen ⚠️ **SCREENSHOT NEEDED**

**Purpose**: User login and registration with password recovery option.

**Key Features**:
- Toggle between Login and Registration modes
- Email and password input fields with validation
- Name field (registration only)
- "Forgot Password?" link (login mode)
- Form validation with error messages
- Loading state during authentication

**UI Elements**:
- App logo/header
- Toggle button: "Login" / "Sign Up"
- Email input field with validation
- Password input field with validation
- Name input field (registration only)
- "Forgot Password?" link (login only)
- Submit button: "Sign In" or "Create Account"
- Error messages displayed below fields

**Form Validation**:
- Email format validation
- Password strength validation (min 6 chars for login, 8+ with uppercase, lowercase, number for registration)
- Required field validation
- Real-time error feedback

**Navigation**:
- On successful login/registration → `DashboardScreen`
- "Forgot Password?" → Password recovery flow

**Screenshot Status**: ❌ **MISSING - Please take screenshot**

---

### 3. Dashboard Screen ✅ **SCREENSHOT PROVIDED**

**Purpose**: Main hub displaying system status, real-time sensor data, quick controls, and recent alerts.

**Screenshots Available**: 
- ✅ Dashboard view 1 (with Water Level card, Quick Controls)
- ✅ Dashboard view 2 (with System Status, 3D View, Environmental Data)

#### Dashboard View 1 Description:

**Header Section**:
- **App Title**: "AquaGrow" in large white text
- **Subtitle**: "Smart Hydroponic System"
- **Notification Icon**: Bell icon with red badge showing "1" (unread notifications)
- **Settings Icon**: Gear icon in top right

**Main Content**:

1. **Water Level Card** (Large, prominent):
   - Light blue water drop icon
   - Label: "Water Level"
   - Current value: "47 %" in large bold text
   - Visual water level indicator (wavy blue line at bottom)

2. **Quick Control Section**:
   - Heading: "Quick Control"
   - Three circular buttons arranged horizontally:
     - **Pump**: Light blue circle, white water drop icon, "Pump" label
     - **Lights**: Light gray circle, white light bulb icon, "Lights" label
     - **Fan**: Light green circle, white fan icon, "Fan" label
   - Right arrow indicating navigation
   - Floating microphone button (voice command) partially visible

4. **Recent Alerts Section**:
   - Heading: "Recent Alerts" with "View All" link
   - Alert card showing:
     - Red circular icon with exclamation mark
     - Alert title: "Temperature Critical High"
     - Details: "Temperature reached 39.6°C. 2m ago"

**Bottom Navigation Bar**:
- 5 tabs: Home (active), Sensors, Control, Analytics, Settings

#### Dashboard View 2 Description:

**System Status Card**:
- Teal background
- Green dot + "System Active" text
- Speaker icon + "Auto" text + Toggle switch (ON/green)

**3D System View Card**:
- Large light blue card
- Teal water droplet icon at top center
- "3D System View" text
- "Tap to rotate & explore" instruction
- Wavy lines and blue dots background (water effect)

**Environmental Data Section**:
- Heading: "Environmental Data"
- "Live • 1m ago" indicator with green checkmark
- Two sensor cards:
  - **TDS/EC Card**: Yellow lightning icon, "1161 pp" value
  - **Light Card**: Yellow sun icon, "2327" value
- Additional sensor cards partially visible (pH, Temperature)

**Floating Action Button**:
- Large teal circular button with white microphone icon
- Positioned bottom right, overlapping sensor cards

**Screenshot Status**: ✅ **PROVIDED**

---

### 4. Sensor Monitoring Screen ✅ **SCREENSHOT PROVIDED**

**Purpose**: Detailed view of individual sensor readings with status indicators, refresh options, and calibration settings.

**Header**:
- **Title**: "Sensor Monitoring" in white text
- **Subtitle**: "Real-time data stream • 2m ago" (shows data recency)
- **Back Button**: Left arrow icon
- **Refresh Button**: Circular refresh icon
- **Auto Button**: "Auto" with refresh icon (auto-update toggle)

**Main Sensor Card** (Primary Focus):
- **Current Reading**: "1161 ppm" in large bold black text
- **Circular Gauge**: Right side, 51% filled with orange, showing "51%"
- **24-Hour Trend Graph**: Small line graph with wavy orange line
- **Summary Statistics**:
  - "Min: 800ppm"
  - "Avg: 1161ppm"
  - "Max: 1500ppm"
- **Action Buttons**:
  - "History" button with clock icon
  - "Calibrate" button with settings/equalizer icon

**Secondary Sensor Card** (Light Sensor):
- **Title**: "Light" with sun icon
- **Status**: "Live Data" with green dot + "Optimal" pill badge (light green)
- **Current Reading**: "23223" (partially visible)
- **Circular Gauge**: "23%" (partially visible)

**Key Features**:
- Individual sensor readings with status indicators
- Refresh/auto-update toggle
- Calibration settings access
- Historical data visualization (24-hour trend)
- Min/Avg/Max statistics
- Status badges (Optimal, Warning, Critical)

**Screenshot Status**: ✅ **PROVIDED**

---

### 5. Control Panel Screen ✅ **SCREENSHOT PROVIDED**

**Purpose**: Manual actuator control, scheduling, emergency stops, and control history logs.

**Screenshots Available**:
- ✅ Control Panel view 1 (with actuator cards: Water Pump, LED Grow Lights, Cooling Fan)
- ✅ Control Panel view 2 (with Scheduled Tasks and Control History sections)

#### Control Panel View 1 Description:

**Header**:
- **Title**: "Control Panel" in white text
- **Subtitle**: "Manage your actuators"
- **Back Button**: Left arrow icon

**Actuator Control Cards** (Three cards):

1. **Water Pump Card**:
   - Light blue circular icon with white water droplet
   - "Water Pump" label
   - Green dot + "Running" status
   - Clock icon + "4h 23m" (running duration)
   - Blue toggle switch (ON position)
   - "Schedule Water Pump" button with light blue clock icon

2. **LED Grow Lights Card**:
   - Light gray circular icon with white light bulb
   - "LED Grow Lights" label
   - Gray dot + "Stopped" status
   - Clock icon + "12h 45m" (stopped duration)
   - Gray toggle switch (OFF position)
   - "Schedule LED Grow Lights" button with orange clock icon

3. **Cooling Fan Card**:
   - Green circular icon with white fan/wind lines
   - "Cooling Fan" label
   - Green dot + "Running" status
   - Clock icon + "0h 0m" (just started)
   - Green toggle switch (ON position)
   - "Schedule Cooling Fan" button with green clock icon

**Scheduled Tasks Section**:
- Heading: "Scheduled Tasks"
- Empty state card:
  - Large gray clock icon (centered)
  - "No schedules yet" text
  - "+ Add New Schedule" button at bottom

#### Control Panel View 2 Description:

**Scheduled Tasks Section**:
- Heading: "Scheduled Tasks"
- Empty state card with clock icon
- "No schedules yet" message
- "+ Add New Schedule" button

**Control History Section**:
- Heading: "Control History"
- Empty state card:
  - Gray refresh/history clock icon
  - "No activity yet" message
  - "Control actions will appear here" hint text

**Emergency Stop Button**:
- Large red rectangular button at bottom
- White stop icon (square)
- Bold white text: "EMERGENCY STOP ALL"

**Key Features**:
- Manual actuator control (toggle switches)
- Real-time status indicators (Running/Stopped)
- Duration tracking (how long running/stopped)
- Scheduling functionality
- Control history logging
- Emergency stop all actuators

**Screenshot Status**: ✅ **PROVIDED**

---

### 6. Analytics & History Screen ⚠️ **SCREENSHOT NEEDED**

**Purpose**: Charts, historical data visualization, export options, and trend analysis.

**Expected UI Elements**:
- **Header**: "Analytics" title with back button
- **Time Range Selector**: Buttons for "24h", "7d", "30d", "Custom"
- **Chart Section**: 
  - Line charts for sensor trends
  - Bar charts for actuator usage
  - Pie charts for status distribution
- **Data Cards**:
  - Average values
  - Peak values
  - Trend indicators (up/down arrows)
- **Export Options**:
  - "Export CSV" button
  - "Export PDF" button
  - "Share" button
- **Filter Options**:
  - Sensor type filter
  - Date range picker
  - Status filter

**Key Features**:
- Interactive charts (fl_chart library)
- Historical data visualization
- Export to CSV/PDF
- Trend analysis with indicators
- Custom date range selection
- Multiple chart types (line, bar, pie)

**Screenshot Status**: ❌ **MISSING - Please take screenshot**

---

### 7. Settings Screen ⚠️ **SCREENSHOT NEEDED**

**Purpose**: Manage sensor thresholds, notifications, system calibration, and user profiles.

**Expected UI Elements**:
- **Header**: "Settings" title with back button
- **User Profile Section**:
  - Profile picture/avatar
  - Name and email
  - "Edit Profile" button
- **Sensor Thresholds Section**:
  - Temperature: Min/Max sliders
  - pH: Min/Max sliders
  - Water Level: Min/Max sliders
  - TDS/EC: Min/Max sliders
  - Light: Min/Max sliders
- **Notifications Section**:
  - Toggle switches for:
    - Critical alerts
    - Warning alerts
    - System updates
    - Email notifications
- **System Calibration Section**:
  - "Calibrate Sensors" button
  - "Reset to Defaults" button
- **App Settings**:
  - Dark mode toggle
  - Language selector
  - Units (Metric/Imperial)
- **About Section**:
  - App version
  - "Terms & Conditions" link
  - "Privacy Policy" link

**Key Features**:
- Sensor threshold management
- Notification preferences
- System calibration tools
- User profile editing
- Theme customization
- App information

**Screenshot Status**: ❌ **MISSING - Please take screenshot**

---

### 8. Alerts & Notifications Screen ⚠️ **SCREENSHOT NEEDED**

**Purpose**: Real-time alerts display, severity filtering, notification history, and acknowledgment features.

**Expected UI Elements**:
- **Header**: "Alerts" title with back button
- **Filter Tabs**: "All", "Critical", "Warning", "Info"
- **Alert List**:
  - Alert cards with:
    - Severity icon (red/yellow/blue)
    - Alert title
    - Sensor name
    - Timestamp
    - Acknowledge button
    - Details button
- **Empty State**: "No alerts" message when list is empty
- **Action Buttons**:
  - "Mark All as Read" button
  - "Clear All" button (with confirmation)

**Key Features**:
- Real-time alert display
- Severity filtering (Critical, Warning, Info)
- Notification history
- Acknowledgment functionality
- Alert details view
- Timestamp display
- Color-coded severity indicators

**Screenshot Status**: ❌ **MISSING - Please take screenshot**

---

### 9. Profile Screen ⚠️ **SCREENSHOT NEEDED**

**Purpose**: User profile management and account settings.

**Expected UI Elements**:
- **Header**: "Profile" title
- **User Profile Section**:
  - User avatar (circle with initial)
  - User name
  - User email
  - Sign out button
- **Account Information**:
  - Display name
  - Email address
  - Account creation date

**Key Features**:
- User profile display
- Account information
- Sign out functionality

**Screenshot Status**: ❌ **MISSING - Please take screenshot**

---
  - Resource cards with:
    - Resource name
    - Category
    - Quantity available
    - Location
    - Contact info
    - "Request" button
- **Add Resource Button**: "+ Add Resource" floating button

**Key Features**:
- Resource listing
- Category filtering
- Resource request functionality
- Location sharing
- Contact information

**Screenshot Status**: ❌ **MISSING - Please take screenshot**

---

## Navigation Flow

```
Splash Screen
    ↓
Auth Screen (if not logged in)
    ↓
Dashboard Screen (Main Hub)
    ├──→ Sensor Monitoring Screen
    ├──→ Control Panel Screen
    ├──→ Analytics Screen
    ├──→ Settings Screen
    └──→ Alerts Screen (via notification icon)
         └──→ Alert Details
    └──→ Profile Screen (via settings)
```

---

## Missing Screenshots

### Critical Screens (Required for Documentation):

1. ❌ **Splash Screen** - First screen users see
2. ❌ **Authentication Screen** - Login/Registration
3. ❌ **Analytics & History Screen** - Charts and data visualization
4. ❌ **Settings Screen** - Configuration and thresholds
5. ❌ **Alerts & Notifications Screen** - Alert management

### Secondary Screens:

6. ❌ **Profile Screen** - User profile and account settings

### How to Take Screenshots:

1. **On Android Device**:
   - Connect device via USB
   - Enable USB debugging
   - Run: `adb shell screencap -p /sdcard/screenshot.png`
   - Pull: `adb pull /sdcard/screenshot.png screenshots/`

2. **On Android Emulator**:
   - Use the camera icon in the emulator toolbar
   - Or use: `adb shell screencap -p > screenshot.png`

3. **Recommended Screenshot Names**:
   - `01_splash_screen.png`
   - `02_auth_screen_login.png`
   - `02_auth_screen_register.png`
   - `03_dashboard_screen.png` ✅ (Already have)
   - `04_sensor_monitoring_screen.png` ✅ (Already have)
   - `05_control_panel_screen.png` ✅ (Already have)
   - `06_analytics_screen.png`
   - `07_settings_screen.png`
   - `08_alerts_screen.png`
   - `09_profile_screen.png`

---

## UI Components Summary

### Reusable Components:
- **Sensor Cards**: Display sensor readings with icons and status
- **Actuator Cards**: Control cards with toggle switches
- **Alert Cards**: Alert display with severity indicators
- **Bottom Navigation Bar**: 5-tab navigation (Home, Sensors, Control, Analytics, Settings)
- **Floating Action Buttons**: Voice command, add actions
- **Status Indicators**: Color-coded dots (green=active, gray=inactive, red=critical)
- **Circular Gauges**: Progress indicators for sensor values
- **Toggle Switches**: On/Off controls for actuators and settings

### Design Patterns:
- **Glassmorphism**: Frosted glass effect on cards
- **Gradient Backgrounds**: Teal gradients for headers
- **Card-based Layout**: Information organized in cards
- **Color-coded Status**: Visual indicators for system state
- **Real-time Updates**: Live data indicators with timestamps

---

## Notes for Screenshot Capture

When taking screenshots, ensure:
1. **Full Screen**: Capture entire screen without cropping
2. **Real Data**: Use actual sensor data if possible (not placeholder)
3. **Multiple States**: For screens with different states (e.g., logged in/out), capture both
4. **High Resolution**: Use device's native resolution
5. **Clean State**: Remove debug overlays if visible
6. **Consistent Time**: Use same time format across screenshots
7. **Active States**: Show interactive elements in their active state when relevant

---

## Conclusion

The AquaGrow app features a comprehensive UI with 9 main screens covering all aspects of hydroponic system management. The design is modern, intuitive, and follows Material Design principles with custom theming.

**Screenshot Status**:
- ✅ **Provided**: 3 screens (Dashboard, Sensor Monitoring, Control Panel)
- ❌ **Missing**: 10 screens (need screenshots)

Please capture screenshots for all missing screens to complete the UI documentation.

