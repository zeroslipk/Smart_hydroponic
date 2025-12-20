# Missing Requirements for Second Milestone

## Critical Missing Items

### 1. SQLite Database Integration (Requirement #3) - [3 marks]
**Status:** ❌ NOT IMPLEMENTED

**What's needed:**
- Install `sqflite` package
- Create database helper/service class
- Store sensor readings with timestamps
- Store actuator activities with timestamps
- Store warnings/alerts with timestamps
- Store scheduled tasks
- Implement database operations (CRUD)

**Current State:** Only Firebase Realtime Database is implemented

---

### 2. Testing Suite (Requirement #5) - [3 marks]
**Status:** ❌ NOT IMPLEMENTED

**What's needed:**
- Unit tests (`test/` folder)
  - Test sensor provider
  - Test Firebase service
  - Test models
  - Test validation logic
- Integration tests (`integration_test/` folder)
  - Test navigation flows
  - Test screen interactions
  - Test database operations
- PowerShell auto-test script (`run_tests.ps1`)
  - Automate test execution
  - Use ADB commands
  - Generate test logs
- Test case documentation
  - List all test cases
  - Test scenarios
  - Expected results

**Current State:** No test files found

---

### 3. Quality Enhancement Features (Requirement #4) - [2 marks]
**Status:** ❌ MOSTLY MISSING

#### 3.1 Text-to-Speech
- **Status:** ❌ Missing
- **Package needed:** `flutter_tts`
- **Implementation:** Add TTS for sensor readings, alerts

#### 3.2 Speech Recognition
- **Status:** ❌ Missing
- **Package needed:** `speech_to_text`
- **Implementation:** Voice commands for control panel

#### 3.3 Notification System
- **Status:** ❌ Missing
- **Package needed:** `flutter_local_notifications`
- **Implementation:** 
  - Critical warnings (high temperature, low water level)
  - Alert notifications
  - System status notifications

#### 3.4 MVVM Architecture
- **Status:** ❌ Not implemented
- **Current:** Using Provider pattern (not MVVM)
- **Needed:** Refactor to:
  - View (UI screens)
  - ViewModel (business logic)
  - Model (data models)

#### 3.5 Data Validation
- **Status:** ⚠️ Partially missing
- **Needed:**
  - Email format validation
  - Required field validation
  - Date format validation
  - Input range validation

---

### 4. Documentation (Requirement #6) - [2 marks]
**Status:** ⚠️ INCOMPLETE

**What's needed:**
- Comprehensive project document with:
  - Introduction
  - Survey of similar apps (comparative analysis)
  - UI Design (detailed description + screenshots)
  - Code Description and Navigation scenarios
  - Test plan and scoreboard of test cases
  - Known bugs
  - Version Control Activity Report (GitHub)
  - Work statement (team member contributions)
- 2-minute YouTube video demo
- Link to video in project document
- GitHub repository access for instructor

---

## What's Already Implemented ✅

1. ✅ UI Layout (Requirement #1) - All screens exist
2. ✅ Navigation - All pages navigable
3. ✅ Firebase Integration - Firebase Realtime Database configured
4. ✅ State Management - Provider implemented
5. ✅ Basic App Structure - All screens created

---

## Priority Order for Implementation

1. **HIGH PRIORITY (Required for Milestone 2):**
   - SQLite Database Integration
   - Basic Testing Suite
   - Navigation verification

2. **MEDIUM PRIORITY (Quality Features):**
   - Notification System
   - Data Validation
   - Text-to-Speech
   - Speech Recognition

3. **LOW PRIORITY (Can be done later):**
   - MVVM Architecture refactoring
   - Comprehensive documentation
   - Video demo

---

## Next Steps

1. Add SQLite database implementation
2. Create test files (unit + integration)
3. Create PowerShell test script
4. Add notification system
5. Add TTS and Speech Recognition
6. Implement data validation
7. Prepare documentation






