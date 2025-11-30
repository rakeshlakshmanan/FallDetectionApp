# Fall Detection Application - Setup & Installation Guide

## Application Overview

A comprehensive mobile fall detection system using sensor fusion, cloud data integration, and automated emergency response. Built with Flutter for iOS and Android.

---

## Prerequisites

### Required Software

- **Flutter SDK**: Version 3.0 or higher
    - Download: https://docs.flutter.dev/get-started/install
- **Xcode**: Version 14+ (for iOS development)
    - Download from Mac App Store
- **CocoaPods**: Latest version
```bash
  sudo gem install cocoapods
```
- **Git**: For cloning the repository
- **Visual Studio Code** or **Android Studio**: Recommended IDEs

### Required Accounts

- **Firebase Account**: Free tier sufficient
    - Sign up: https://firebase.google.com/
- **Apple Developer Account**: For iOS device testing (free tier works)

### Hardware Requirements

- **Mac Computer**: Required for iOS development
- **iPhone**: iOS 13.0 or higher with:
    - Accelerometer and gyroscope sensors
    - GPS capability
    - Active internet connection (WiFi or cellular)

---

## Installation Steps

### Step 1: Clone the Repository
```bash
git clone https://github.com/your-username/fall-detection-app.git
cd fall-detection-app
```

### Step 2: Install Flutter Dependencies
```bash
flutter pub get
```

This will install all required packages:
- `sensors_plus` - Sensor data access
- `firebase_database` - Cloud storage
- `sqflite` - Local database
- `audioplayers` - Emergency alarm
- `firebase_core` - Firebase initialization

### Step 3: Firebase Setup

#### 3.1 Create Firebase Project

1. Go to https://console.firebase.google.com/
2. Click **"Add project"**
3. Name: `fall-detection-app` (or your preferred name)
4. Disable Google Analytics (optional for this project)
5. Click **"Create project"**

#### 3.2 Add iOS App to Firebase

1. In Firebase Console, click **iOS icon** (⊕ iOS)
2. Register app with Bundle ID: `com.yourcompany.falldetection`
    - Find in Xcode: `ios/Runner.xcworkspace` → Runner → General → Bundle Identifier
3. Download `GoogleService-Info.plist`
4. Add to project:
```bash
   # Place the downloaded file here:
   ios/Runner/GoogleService-Info.plist
```
5. In Xcode:
    - Right-click `Runner` folder
    - **"Add Files to Runner"**
    - Select `GoogleService-Info.plist`
    - Check **"Copy items if needed"**

#### 3.3 Enable Realtime Database

1. Firebase Console → Build → **Realtime Database**
2. Click **"Create Database"**
3. Location: Choose closest region (e.g., `europe-west1`)
4. Security Rules: Start in **"Test mode"** (open access)
```json
   {
     "rules": {
       ".read": true,
       ".write": true
     }
   }
```
 **Note**: Use proper security rules in production!

5. Your database URL will be:
```
   https://YOUR-PROJECT-ID-default-rtdb.REGION.firebasedatabase.app/
```

#### 3.4 Update Firebase Configuration in Code

Edit `lib/firebase_service.dart`:
```dart
// Update with your Firebase Realtime Database URL
final databaseURL = 'https://YOUR-PROJECT-ID-default-rtdb.REGION.firebasedatabase.app/';
```

### Step 4: iOS Configuration

#### 4.1 Update Info.plist

Add sensor and background audio permissions to `ios/Runner/Info.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Existing keys... -->
    
    <!-- Sensor Access -->
    <key>NSMotionUsageDescription</key>
    <string>This app needs motion sensors to detect falls</string>
    
    <!-- Location Access -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>This app needs your location for emergency response</string>
    <key>NSLocationAlwaysUsageDescription</key>
    <string>This app needs your location to detect falls at construction sites</string>
    
    <!-- Background Audio (Emergency Alarm) -->
    <key>UIBackgroundModes</key>
    <array>
        <string>audio</string>
    </array>
    
    <!-- Microphone (for audio playback) -->
    <key>NSMicrophoneUsageDescription</key>
    <string>Emergency alarm needs to play even when app is in background</string>
</dict>
</plist>
```

#### 4.2 Install iOS Dependencies
```bash
cd ios
pod install
cd ..
```

If you encounter errors:
```bash
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..
```

---

## Connecting iPhone for Development

### Step 1: Physical Connection (First Time Only)

1. **Connect iPhone to Mac via USB cable**

2. **Trust Computer on iPhone:**
    - iPhone will prompt: "Trust This Computer?"
    - Tap **"Trust"**
    - Enter iPhone passcode

3. **Open Xcode:**
```bash
   open ios/Runner.xcworkspace
```

4. **Select Your iPhone as Target:**
    - Top toolbar → Select device dropdown
    - Choose your iPhone (e.g., "Rakesh's iPhone")

5. **Sign the App:**
    - Select `Runner` in left sidebar
    - Go to **"Signing & Capabilities"** tab
    - Team: Select your Apple ID (add if needed)
    - Bundle Identifier: Ensure it's unique (e.g., `com.yourname.falldetection`)

### Step 2: Enable Developer Mode (iOS 16+)

If you see "Developer Mode Required":

1. On iPhone: **Settings → Privacy & Security → Developer Mode**
2. Toggle **"Developer Mode"** ON
3. iPhone will restart
4. After restart, confirm enabling Developer Mode

### Step 3: Trust Developer Certificate

After first app installation:

1. On iPhone: **Settings → General → VPN & Device Management**
2. Find **"Apple Development: your.email@example.com"**
3. Tap it → **"Trust Apple Development..."**
4. Confirm by tapping **"Trust"**

### Step 4: Enable Wireless Debugging (Optional)

**For wireless connection without cable:**

1. Keep iPhone connected via USB (first time)
2. In Xcode: **Window → Devices and Simulators**
3. Select your iPhone from left sidebar
4. Check  **"Connect via network"**
5. Wait for network icon to appear
6. **Disconnect USB cable** - iPhone now connected wirelessly!

**Requirements:**
- Mac and iPhone on **same WiFi network**
- Initial USB pairing completed

---

## Running the Application

### Method 1: Using Flutter Command Line
```bash
# Check connected devices
flutter devices

# You should see your iPhone:
# Rakesh's iPhone (mobile) • 00008030-001234567890 • ios • iOS 17.x

# Run the app
flutter run
```

### Method 2: Using Visual Studio Code

1. Open project in VS Code
2. Bottom right: Click device selector
3. Select your iPhone
4. Press **F5** or Run → Start Debugging

### Method 3: Using Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select your iPhone from device dropdown
3. Click **Run button** or press **Cmd + R**

### Expected Output
```
Launching lib/main.dart on Rakesh's iPhone in debug mode...
Running Xcode build...
Xcode build done.                                            15.2s
Syncing files to device Rakesh's iPhone...
Flutter run key commands.
r Hot reload. 
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).

Running with sound null safety

To hot reload changes while running, press "r" or "R".
```

---

## 🎮 Using the Application

### First Launch

1. **Registration Screen** appears (no users registered yet)

2. **Register First User:**
    - Tap **"Register New User"**
    - Fill in details:
        - Name: `John Doe`
        - Email: `john@example.com`
        - Phone: `+353-87-1234567`
        - Emergency Contact: `+353-87-7654321`
        - Address: `123 Main St, Dublin` (optional)
    - Tap **"Register"**

3. **Login Screen** now shows registered user

4. **Select User:**
    - Tap on **"John Doe"** card
    - App navigates to HomePage

### Starting Fall Detection

1. **Grant Permissions:**
    - Allow motion sensors: Tap **"Allow"**
    - Allow location: Tap **"Allow While Using App"**

2. **Start Monitoring:**
    - Tap green **"Start"** button
    - Status changes to **"Monitoring Active"**
    - You'll see real-time acceleration values updating

3. **Test Fall Detection:**
    - **Controlled test**: Drop phone onto soft surface (cushion/bed) from ~1 meter
    - **Warning**: Do NOT drop on hard surfaces!
    - App should detect fall and show warning banner

4. **During Fall Detection:**
    - Red banner appears: **"FALL DETECTED"**
    - 10-second countdown begins
    - **If false alarm**: Tap **"I'm OK - Stop Alarm"**
    - **If real fall**: Countdown reaches 0 → loud alarm plays

5. **Stop Monitoring:**
    - Tap red **"Stop"** button
    - Alarm stops if playing
    - Status changes to **"Monitoring Stopped"**

### Adding Multiple Users

1. Return to login screen (back button from HomePage)
2. Tap **"Add New User"**
3. Register second user (e.g., Jane Smith)
4. Login screen now shows both users
5. Select either user to monitor

---

## Troubleshooting

### Issue: "Untrusted Developer"

**Error:** App won't open, shows untrusted developer message

**Solution:**
1. Settings → General → VPN & Device Management
2. Tap your developer certificate
3. Tap **"Trust"** → Confirm

---

### Issue: "Module 'audioplayers_darwin' not found"

**Error:** Build fails with audioplayers module error

**Solution:**
```bash
flutter clean
flutter pub get
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..
flutter run
```

---

### Issue: "No devices found"

**Error:** `flutter devices` shows no iPhone

**Solution:**

1. **Check USB connection:**
    - Try different cable
    - Try different USB port

2. **Trust computer:**
    - Disconnect and reconnect iPhone
    - Tap "Trust" on iPhone prompt

3. **Restart services:**
```bash
   # Kill Xcode
   killall Xcode
   
   # Restart usbmuxd
   sudo launchctl stop com.apple.usbmuxd
   sudo launchctl start com.apple.usbmuxd
```

4. **Check device list:**
```bash
   flutter devices
   xcrun xctrace list devices
```

---

### Issue: Sensors not working

**Error:** Acceleration values always show 0.0

**Solution:**

1. **Check permissions:**
    - Settings → Fall Detection App → Motion & Fitness → Enable

2. **Real device only:**
    - Sensors DON'T work in iOS Simulator
    - Must test on physical iPhone

3. **Restart app:**
    - Stop and restart monitoring
    - Close and reopen app

---

### Issue: Firebase connection error

**Error:** "Failed to upload to Firebase"

**Solution:**

1. **Check internet connection:**
    - Ensure iPhone has WiFi or cellular data

2. **Verify Firebase URL:**
    - Check `firebase_service.dart` has correct database URL
    - Format: `https://PROJECT-ID-default-rtdb.REGION.firebasedatabase.app/`

3. **Check Firebase Console:**
    - Ensure Realtime Database is created
    - Verify security rules allow writes (test mode)

4. **Check GoogleService-Info.plist:**
    - Ensure file is in `ios/Runner/` directory
    - Verify it's added to Xcode project (appears in Runner folder)

---

### Issue: Alarm doesn't play when app is locked

**Error:** Alarm stops when phone screen locks

**Solution:**

1. **Check Info.plist:**
    - Verify `UIBackgroundModes` includes `audio`

2. **Test with app in foreground first:**
    - Confirm alarm works when app is visible
    - Then test with locked screen

3. **Check Do Not Disturb:**
    - Disable Do Not Disturb on iPhone
    - Check volume is not muted

---

### Issue: Wireless connection fails

**Error:** iPhone doesn't appear as network device

**Solution:**

1. **Same WiFi network:**
    - Mac and iPhone must be on identical network
    - Corporate/school networks may block device discovery

2. **Re-pair device:**
```bash
   # In Xcode: Window → Devices and Simulators
   # Toggle "Connect via network" OFF then ON
```

3. **Use cable temporarily:**
    - Wireless is optional, cable always works
    - Reconnect USB cable if wireless fails

---

## Project Structure
```
fall-detection-app/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── login_page.dart              # User selection screen
│   ├── registration_page.dart       # New user registration
│   ├── home_page.dart               # Main fall detection UI
│   ├── sensor_service.dart          # Sensor data acquisition
│   ├── firebase_service.dart        # Cloud storage
│   └── database_helper.dart         # SQLite operations
├── ios/
│   ├── Runner/
│   │   ├── Info.plist               # iOS permissions
│   │   └── GoogleService-Info.plist # Firebase config
│   └── Podfile                      # CocoaPods dependencies
├── assets/
│   └── sounds/
│       └── emergency_alarm.mp3      # Emergency sound file
├── pubspec.yaml                     # Flutter dependencies
└── README.md                        # This file
```

---

## Configuration Files

### pubspec.yaml (Key Dependencies)
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Sensors
  sensors_plus: ^3.0.0
  
  # Firebase
  firebase_core: ^2.24.0
  firebase_database: ^10.4.0
  
  # Local storage
  sqflite: ^2.2.0
  path: ^1.8.0
  
  # Audio
  audioplayers: ^5.2.1

flutter:
  assets:
    - assets/sounds/emergency_alarm.mp3
```

---

## Testing Checklist

Before submission, verify:

- [ ] App runs on physical iPhone without errors
- [ ] User registration creates new profiles successfully
- [ ] Login screen displays all registered users
- [ ] Real-time sensor values display and update (50-60 Hz)
- [ ] Fall detection triggers when phone dropped
- [ ] 10-second countdown displays correctly
- [ ] "I'm OK" button cancels false alarms
- [ ] Emergency alarm plays at full volume
- [ ] Alarm continues when app minimized
- [ ] Alarm continues when phone locked
- [ ] Fall events saved to SQLite database
- [ ] User profile displays correct information
- [ ] Total falls count increments after detection
- [ ] Data uploads to Firebase (check Firebase Console)
- [ ] Multiple users can be registered and selected
- [ ] Each user's fall history is separate

---

## Getting Help

### Useful Commands
```bash
# Check Flutter installation
flutter doctor

# See all connected devices
flutter devices

# Clean build artifacts
flutter clean

# Reinstall dependencies
flutter pub get

# Run with verbose logging
flutter run -v

# Check iOS device logs
flutter logs
```

### Common Error Messages

| Error | Solution |
|-------|----------|
| `Could not find an option named "null-safety"` | Upgrade Flutter: `flutter upgrade` |
| `CocoaPods not installed` | Install: `sudo gem install cocoapods` |
| `GoogleService-Info.plist not found` | Download from Firebase Console |
| `Signing for "Runner" requires a development team` | Add Apple ID in Xcode |
| `Developer Mode Required` | Enable in Settings → Privacy & Security |

---

## Success Indicators

You've successfully set up the app when:

1. App installs on iPhone without "Untrusted Developer" error
2. Registration screen allows creating new users
3. HomePage displays real-time acceleration values
4. Dropping phone triggers fall detection warning
5. Emergency alarm plays loudly
6. Firebase Console shows incoming sensor data
7. SQLite database stores user profiles and fall events

---

## Next Steps

After successful installation:

1. Register multiple users to test multi-user functionality
2. Simulate falls with different intensities
3. Test alarm cancellation with "I'm OK" button
4. Review Firebase Console to see uploaded sensor data
5. Check SQLite database for fall event records
6. Test wireless debugging (disconnect cable)
7. Test background alarm (lock phone during countdown)

---

## License

This project is for educational purposes as part of a Smart City IoT assignment.

---

**Last Updated:** November 30, 2025  
**Flutter Version:** 3.16+  
**iOS Support:** iOS 13.0+  
**Xcode Version:** 14.0+