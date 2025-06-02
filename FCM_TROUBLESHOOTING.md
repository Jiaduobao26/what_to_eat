# FCM Troubleshooting Guide

## Current FCM Setup Status ✅

Your app now has comprehensive FCM (Firebase Cloud Messaging) setup with the following components:

### ✅ What's Been Configured:

1. **FCM Service** (`lib/services/fcm_service.dart`)
   - Token generation and management
   - Message handling for foreground/background
   - Topic subscription functionality
   - Permission management

2. **Main App Integration** (`lib/main.dart`)
   - Background message handler
   - FCM service initialization
   - Proper Firebase initialization

3. **Android Configuration** (`android/app/src/main/AndroidManifest.xml`)
   - Notification permissions
   - FCM metadata configurations
   - Default notification settings

4. **Test Interface** (`lib/screens/fcm_test_screen.dart`)
   - Token display and copy functionality
   - Topic subscription testing
   - Instructions for testing

5. **Firebase Configuration Files**
   - `google-services.json` ✅
   - `firebase_options.dart` ✅
   - Package name: `com.csen268.what_to_eat` ✅

## 🔧 Testing FCM Messages

### Method 1: Using Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `csen268-s25-g5-6be5f`
3. Navigate to **Cloud Messaging** section
4. Click **"Send your first message"**
5. Fill in:
   - **Title**: Test Notification
   - **Text**: This is a test message
6. Click **"Send test message"**
7. Paste your FCM token from the app
8. Click **"Test"**

### Method 2: Using cURL Command
```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "YOUR_FCM_TOKEN",
    "notification": {
      "title": "Test Notification",
      "body": "This is a test message from cURL"
    },
    "data": {
      "screen": "test",
      "action": "open_app"
    }
  }'
```

### Method 3: Using Topic Messaging
1. In the app, click **"Subscribe to Test Topic"**
2. In Firebase Console, send a message to topic: `test_notifications`
3. All subscribed devices will receive the message

## 🚨 Common Issues & Solutions

### Issue 1: No FCM Token Generated
**Symptoms**: Token shows as null or empty
**Solutions**:
- Check internet connection
- Ensure Google Play Services is installed (Android)
- Verify Firebase project configuration
- Check if app is properly signed

### Issue 2: Messages Not Received
**Symptoms**: Token exists but no notifications appear
**Solutions**:
- Verify notification permissions are granted
- Test on real device (emulator has limitations)
- Check if app is in foreground vs background
- Verify Firebase project settings

### Issue 3: Background Messages Not Working
**Symptoms**: Foreground messages work, background don't
**Solutions**:
- Ensure background message handler is registered
- Check device battery optimization settings
- Verify app is not being killed by OS

### Issue 4: Android Emulator Issues
**Symptoms**: FCM not working on emulator
**Solutions**:
- Use emulator with Google Play Services
- Test on real Android device
- Ensure emulator has proper Google account

## 📱 Real Device Testing Recommendations

For the most reliable FCM testing:

1. **Use a real Android device** with Google Play Services
2. **Enable Developer Options** and USB Debugging
3. **Connect via USB** and run: `flutter run`
4. **Grant all permissions** when prompted
5. **Test different app states**:
   - Foreground (app open)
   - Background (app minimized)
   - Terminated (app closed)

## 🔍 Debug Commands

### Check FCM Token:
The app will print the FCM token in the debug console. Look for:
```
I/flutter (12345): FCM Token: [long_token_string]
```

### Check Message Reception:
Look for these logs when messages are received:
```
I/flutter (12345): 📱 Foreground message received!
I/flutter (12345): Title: Test Notification
I/flutter (12345): Body: This is a test message
```

### Verify Firebase Connection:
```bash
flutter pub run firebase_messaging:check
```

## ✅ Next Steps

1. **Run the app** and navigate to Profile → FCM Test
2. **Copy the FCM token** displayed
3. **Send a test message** using Firebase Console
4. **Verify messages are received** in different app states
5. **Test on real device** for complete validation

## 🆘 If Issues Persist

1. Check Firebase project quotas and billing
2. Verify SHA-1 fingerprint in Firebase Console
3. Ensure app package name matches exactly
4. Review device notification settings
5. Test with a minimal FCM setup

Your FCM setup should now be working! The key is testing on a real device with proper Google Play Services.
