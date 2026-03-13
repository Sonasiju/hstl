# Server Connection Fix - Setup Guide

## Problem Fixed ✅
The signup page was showing "Unable to connect to server" error because the mobile app couldn't reach the backend server.

## Solution Implemented
- **Created API Configuration Helper** (`lib/core/api_config.dart`)
- **Updated Auth Provider** to use dynamic base URL
- **Updated Hostel Provider** to use dynamic base URL
- The app now automatically detects the environment and uses the correct server URL

## Configuration by Platform

### 1. **Android Emulator**
```
Uses: http://10.0.2.2:5000 (special IP for emulator to reach host machine)
```
✅ **Already configured** - No changes needed

### 2. **iOS Simulator**  
```
Uses: http://localhost:5000
```
✅ **Already configured** - No changes needed

### 3. **Physical Android/iOS Device** (Same Network)
If your device is on the same network as your PC (10.223.111.90):
```
Uses: http://10.223.111.90:5000
```
✅ **Already configured as default** - Ensure device can reach this IP

### 4. **Physical Device (Different Network)**
Edit `lib/core/api_config.dart` and change:
```dart
static const String _productionUrl = 'http://YOUR_IP:5000';
```

Or dynamically change it in code:
```dart
ApiConfig.setCustomUrl('http://192.168.x.x:5000');
```

## Backend Server Status
✅ **Server is running** on port 5000
✅ **Signup endpoint** is working (tested and verified)
✅ **MongoDB** is configured and connected

## What to Do Next

### If Using Android Emulator:
1. No changes needed - it will automatically use `10.0.2.2:5000`
2. Run: `flutter run`

### If Using iOS Simulator:
1. No changes needed - it will automatically use `localhost:5000`  
2. Run: `flutter run`

### If Using Physical Device:
1. **Ensure your device is connected to the same network as your PC**
2. Verify the device can ping: `10.223.111.90`
3. Run: `flutter run`
4. The app will use `http://10.223.111.90:5000`

### If Connection Still Fails:
1. Check if device is on same network as PC
2. Check Windows Firewall - allow Node.js or port 5000
3. Verify server is running: `npm run dev` in `backend` folder
4. Or manually set URL in app code with `ApiConfig.setCustomUrl()`

## Files Modified
- ✅ Created: `frontend/lib/core/api_config.dart` (NEW)
- ✅ Updated: `frontend/lib/data/providers/auth_provider.dart`
- ✅ Updated: `frontend/lib/data/providers/hostel_provider.dart`
- ✅ Created: `backend/.env` (with configuration)

## Testing the Server
Backend is confirmed working:
```
✅ Server responds to GET http://localhost:5000
✅ Signup endpoint creates accounts successfully  
✅ JWT tokens are being issued correctly
```

## Quick Commands

Start backend server:
```bash
cd backend
npm run dev
```

Build and run Flutter app:
```bash
cd frontend
flutter pub get
flutter run
```

The server is now **ready** - just run your Flutter app! 🚀
