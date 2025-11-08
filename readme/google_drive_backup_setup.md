# Google Drive Backup Setup Guide

This guide will help you set up Google Drive backup functionality for the All Tracker application.

## Prerequisites

- Google Cloud Console account
- Firebase project
- App package name/bundle ID already configured
- Development environment set up for both Android and iOS

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or select existing project
3. Follow the project setup wizard
4. Add Android and iOS apps to the project

## Step 2: Configure Android

### 2.1 Download Configuration File

1. In Firebase Console, go to Project Settings
2. Under "Your apps" section, select Android app
3. Download `google-services.json`
4. Place the file in: `android/app/google-services.json`

### 2.2 Get SHA-1 Fingerprint

Get your debug keystore fingerprint:

```bash
cd android
./gradlew signingReport
```

Look for SHA-1 fingerprint in the output and add it to Firebase Console under "SHA certificate fingerprints".

### 2.3 Update build.gradle.kts

The build.gradle.kts already includes required configuration. Verify:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}
```

Ensure `minSdk >= 21` (required for Google Sign-In).

### 2.4 Verify AndroidManifest.xml

Internet permission should already be present in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

## Step 3: Configure iOS

### 3.1 Download Configuration File

1. In Firebase Console, go to Project Settings
2. Under "Your apps" section, select iOS app
3. Download `GoogleService-Info.plist`
4. Open Xcode and add the file to `ios/Runner/` directory
5. Make sure "Copy items if needed" is checked

### 3.2 Update Info.plist

Add OAuth client ID to `ios/Runner/Info.plist`:

```xml
<key>GIDClientID</key>
<string>YOUR_CLIENT_ID.apps.googleusercontent.com</string>
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

Note: Replace `YOUR_CLIENT_ID` with the actual client ID from GoogleService-Info.plist.

## Step 4: Enable Drive API

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your Firebase project
3. Navigate to "APIs & Services" > "Library"
4. Search for "Google Drive API"
5. Click "Enable"

## Step 5: Configure OAuth Consent Screen

1. In Google Cloud Console, go to "APIs & Services" > "OAuth consent screen"
2. Choose "Internal" if your domain is verified (recommended for testing)
3. Fill in required information:
   - App name: All Tracker
   - User support email: your email
   - Developer contact: your email
4. Add scopes:
   - `https://www.googleapis.com/auth/drive.appdata`
5. Add test users (if testing with external users)

## Step 6: Verify Configuration

### Android

```bash
# Clean and rebuild
cd android
./gradlew clean

# Run the app
flutter run
```

### iOS

```bash
# Clean pods
cd ios
pod deintegrate
pod install

# Run the app
flutter run
```

## Step 7: Test the Backup Feature

1. Launch the app on a device (not emulator for first test)
2. Go to Settings > Backup & Restore > Cloud Backup
3. Tap "Configure Cloud Backup"
4. Sign in with your Google account
5. Try creating a backup
6. Verify the backup appears in the list

## Troubleshooting

### Sign-in Fails

**Problem:** Google Sign-In button doesn't work or shows error

**Solutions:**
- Verify SHA-1 fingerprint is added to Firebase
- Check that `google-services.json` is in correct location
- Ensure OAuth consent screen is configured
- Verify Drive API is enabled
- Check that internet permission is present in AndroidManifest.xml

### Upload Fails

**Problem:** Backup creation fails with error

**Solutions:**
- Verify Drive API is enabled in Google Cloud Console
- Check that OAuth consent screen has the correct scope
- Ensure test users are added (fill external testing)
- Check network connectivity

### iOS Redirect Fails

**Problem:** iOS sign-in redirect doesn't work

**Solutions:**
- Verify URL scheme in Info.plist matches client ID
- Ensure GoogleService-Info.plist is added to Xcode project
- Check that GIDClientID is set correctly
- Clean and rebuild the app

### Build Errors

**Problem:** App won't build after adding configuration

**Solutions:**
- Clean the build: `flutter clean`
- Get dependencies: `flutter pub get`
- For iOS: `cd ios && pod install`
- For Android: `cd android && ./gradlew clean`

## Security Notes

- Never commit `google-services.json` or `GoogleService-Info.plist` to version control
- These files contain sensitive project information
- Add them to `.gitignore` (already configured)
- Use different projects for development and production
- Regularly rotate OAuth credentials

## Next Steps

After successful configuration:

1. Test backup creation on Android
2. Test backup creation on iOS
3. Test cross-platform restore
4. Test E2EE mode with passphrase
5. Test automatic backup after 24 hours

For more information, see the main [README.md](../README.md) file.

