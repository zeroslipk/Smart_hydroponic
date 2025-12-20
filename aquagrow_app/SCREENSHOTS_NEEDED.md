# Screenshots Needed - Quick Reference

## ✅ Screenshots Already Provided

1. ✅ **Dashboard Screen** - Main hub with system status
2. ✅ **Sensor Monitoring Screen** - Detailed sensor readings
3. ✅ **Control Panel Screen** - Actuator control and scheduling

---

## ❌ Screenshots Needed (6 screens)

### Priority 1: Core App Screens (Required)

1. **Splash Screen**
   - First screen when app launches
   - Shows app logo with loading animation
   - **How to capture**: Launch app fresh, wait for splash screen

2. **Authentication Screen (Login)**
   - Email and password fields
   - "Sign In" button
   - "Forgot Password?" link
   - **How to capture**: Log out, then open app

3. **Authentication Screen (Registration)**
   - Toggle to "Sign Up" mode
   - Name, email, password fields
   - "Create Account" button
   - **How to capture**: Toggle to registration mode

4. **Analytics & History Screen**
   - Navigate: Dashboard → Bottom Nav → "Analytics"
   - Shows charts and historical data
   - **How to capture**: Tap Analytics tab in bottom navigation

5. **Settings Screen**
   - Navigate: Dashboard → Bottom Nav → "Settings"
   - Shows sensor thresholds, notifications, profile
   - **How to capture**: Tap Settings tab in bottom navigation

6. **Alerts & Notifications Screen**
   - Navigate: Dashboard → Notification bell icon (top right)
   - Shows list of alerts with severity indicators
   - **How to capture**: Tap notification bell icon

### Priority 2: Profile Screen

7. **Profile Screen**
   - Navigate: Settings → Profile section
   - Shows user info and account settings
   - **How to capture**: Navigate from Settings screen

---

## Quick Capture Guide

### Using ADB (Recommended)

```powershell
# Navigate to project
cd "D:\mobile project\Smart_hydroponic\aquagrow_app"

# Create screenshots folder
mkdir screenshots

# Take screenshot
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png screenshots/01_splash_screen.png
```

### Using Android Studio Emulator

1. Open emulator
2. Navigate to desired screen
3. Click camera icon in emulator toolbar
4. Save with descriptive name

### Screenshot Naming Convention

Use this naming format:
- `01_splash_screen.png`
- `02_auth_screen_login.png`
- `02_auth_screen_register.png`
- `03_dashboard_screen.png` ✅
- `04_sensor_monitoring_screen.png` ✅
- `05_control_panel_screen.png` ✅
- `06_analytics_screen.png`
- `07_settings_screen.png`
- `08_alerts_screen.png`
- `09_profile_screen.png`

---

## Navigation Paths for Each Screen

| Screen | Navigation Path |
|--------|----------------|
| Splash | App launch (automatic) |
| Auth Login | Splash → (if not logged in) |
| Auth Register | Auth → Toggle to "Sign Up" |
| Dashboard | Auth → (after login) |
| Sensor Monitoring | Dashboard → Bottom Nav → "Sensors" |
| Control Panel | Dashboard → Bottom Nav → "Control" |
| Analytics | Dashboard → Bottom Nav → "Analytics" |
| Settings | Dashboard → Bottom Nav → "Settings" |
| Alerts | Dashboard → Notification bell icon |
| Profile | Settings → Profile section |

---

## Tips for Good Screenshots

1. **Use Real Data**: If possible, use actual sensor data instead of placeholders
2. **Show Active States**: Capture interactive elements in their active state
3. **Multiple States**: For screens with different modes (login/register), capture both
4. **Clean UI**: Remove any debug overlays or test data
5. **Consistent Time**: Use the same time format across all screenshots
6. **Full Screen**: Capture entire screen without cropping
7. **High Resolution**: Use device's native resolution

---

## Status Summary

- **Total Screens**: 9
- **Screenshots Provided**: 3 ✅
- **Screenshots Needed**: 6 ❌
- **Completion**: 33%

---

## Next Steps

1. Take screenshots for all 6 missing screens
2. Save them in a `screenshots/` folder
3. Update `UI_DESIGN_DOCUMENTATION.md` with screenshot references
4. Include screenshots in project documentation

