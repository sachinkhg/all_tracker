import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Data source for Google Sign-In authentication.
/// 
/// Handles OAuth flow with Google to obtain access tokens for Drive API access.
/// Uses google_sign_in v6.2.1 which has reliable session management.
class GoogleAuthDataSource {
  static const String _driveAppDataScope = 'https://www.googleapis.com/auth/drive.appdata';
  static const String _sheetsReadonlyScope = 'https://www.googleapis.com/auth/spreadsheets.readonly';
  static const String _signedInKey = 'google_sign_in_state';
  static const String _userEmailKey = 'google_user_email';
  
  // Singleton instance to maintain state across app lifecycle
  static GoogleAuthDataSource? _instance;
  static GoogleAuthDataSource get instance {
    _instance ??= GoogleAuthDataSource._internal();
    return _instance!;
  }
  
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Configure GoogleSignIn with Drive and Sheets scopes
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [_driveAppDataScope, _sheetsReadonlyScope],
  );
  
  GoogleSignInAccount? _currentUser;
  bool _initialized = false;
  String? _cachedAccessToken; // Cache access token when we get it
  
  // Private constructor for singleton
  GoogleAuthDataSource._internal() {
    _initialize();
  }
  
  // Public factory constructor - returns singleton instance
  factory GoogleAuthDataSource() => instance;

  Future<void> _initialize() async {
    if (_initialized) return;
    
    try {
      // In v6, use signInSilently() to check for existing sessions
      // This is more reliable than waiting for events
      final user = await _googleSignIn.signInSilently();
      if (user != null) {
        _currentUser = user;
        // Update secure storage to match actual state
        await _secureStorage.write(key: _signedInKey, value: 'true');
        await _secureStorage.write(key: _userEmailKey, value: user.email);
        debugPrint('Session restored via signInSilently: ${user.email}');
      } else {
        // Check if we have stored state but no active session
        final wasSignedIn = await _secureStorage.read(key: _signedInKey) == 'true';
        if (wasSignedIn) {
          debugPrint('Stored state indicates sign-in, but no active session found. Clearing stale state.');
          await _secureStorage.delete(key: _signedInKey);
          await _secureStorage.delete(key: _userEmailKey);
        }
      }
    } catch (e) {
      debugPrint('Error during initialization: $e');
      // If signInSilently fails, clear any stale state
      await _secureStorage.delete(key: _signedInKey);
      await _secureStorage.delete(key: _userEmailKey);
    }
    
    _initialized = true;
  }


  /// Initiate the OAuth sign-in flow.
  /// 
  /// Returns true if sign-in was successful, false otherwise.
  /// Returns false if the user cancels or if sign-in fails.
  Future<bool> signIn() async {
    try {
      await _initialize();
      
      // In v6, use signIn() which handles the OAuth flow
      final user = await _googleSignIn.signIn();
      
      if (user != null) {
        _currentUser = user;
        // Store sign-in state in secure storage
        await _secureStorage.write(key: _signedInKey, value: 'true');
        await _secureStorage.write(key: _userEmailKey, value: user.email);
        debugPrint('Sign-in successful: ${user.email}');
        return true;
      } else {
        debugPrint('User cancelled Google sign-in');
        return false;
      }
    } catch (e, stackTrace) {
      // In v6, signIn() returns null if user cancels, so we handle it above
      // Other errors are caught here
      // Handle any other unexpected errors
      debugPrint('Unexpected error during Google sign-in: $e');
      debugPrint('$stackTrace');
      return false;
    }
  }

  /// Sign out from Google.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _cachedAccessToken = null; // Clear cached token
    // Clear sign-in state from secure storage
    await _secureStorage.delete(key: _signedInKey);
    await _secureStorage.delete(key: _userEmailKey);
  }

  /// Clear the cached access token to force refresh on next request.
  /// Useful when scopes have changed and user needs to re-authenticate.
  void clearCachedToken() {
    _cachedAccessToken = null;
    debugPrint('Cleared cached access token');
  }

  /// Get the current access token for Drive API calls.
  /// 
  /// Returns the access token if authenticated, null otherwise.
  /// Will automatically refresh the token if expired.
  Future<String?> getAccessToken() async {
    // Return cached token if available
    if (_cachedAccessToken != null && _cachedAccessToken!.isNotEmpty) {
      return _cachedAccessToken;
    }
    
    final user = _currentUser;
    if (user == null) {
      debugPrint('No user found, cannot get access token');
      return null;
    }

    try {
      // In v6, get access token from authentication object
      final auth = await user.authentication;
      final accessToken = auth.accessToken;
      
      if (accessToken != null && accessToken.isNotEmpty) {
        _cachedAccessToken = accessToken;
        debugPrint('Found access token');
        return accessToken;
      }
      
      debugPrint('ERROR: Unable to retrieve OAuth accessToken for Drive API.');
      debugPrint('Available: idToken=${auth.idToken != null}');
      debugPrint('Note: idToken cannot be used for Drive API - accessToken is required.');
      
      return null;
    } catch (e, stackTrace) {
      debugPrint('Error getting access token: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
  }

  /// Check if the user is currently signed in.
  /// This will check for existing sessions and update _currentUser.
  Future<bool> isSignedIn() async {
    await _initialize();
    
    // Check if we have a cached user
    if (_currentUser != null) {
      debugPrint('User found from cached state: ${_currentUser!.email}');
      return true;
    }
    
    // Try to restore session using signInSilently
    try {
      final user = await _googleSignIn.signInSilently();
      if (user != null) {
        _currentUser = user;
        // Update secure storage to match actual state
        await _secureStorage.write(key: _signedInKey, value: 'true');
        await _secureStorage.write(key: _userEmailKey, value: user.email);
        debugPrint('User found via signInSilently: ${user.email}');
        return true;
      }
    } catch (e) {
      debugPrint('Error checking sign-in status: $e');
    }
    
    // No user found - clear any stale state
    final wasSignedIn = await _secureStorage.read(key: _signedInKey) == 'true';
    if (wasSignedIn) {
      debugPrint('No active session found, clearing stale authentication state.');
      await _secureStorage.delete(key: _signedInKey);
      await _secureStorage.delete(key: _userEmailKey);
    }
    
    debugPrint('No user found - user not signed in');
    return false;
  }

  /// Get the current user's account information.
  /// This will check for existing sessions if _currentUser is null.
  Future<GoogleSignInAccount?> getCurrentAccount() async {
    await _initialize();
    
    // Return cached user if available
    if (_currentUser != null) {
      return _currentUser;
    }
    
    // Try to restore session using signInSilently
    try {
      final user = await _googleSignIn.signInSilently();
      if (user != null) {
        _currentUser = user;
        // Update secure storage to match actual state
        await _secureStorage.write(key: _signedInKey, value: 'true');
        await _secureStorage.write(key: _userEmailKey, value: user.email);
        debugPrint('User found via signInSilently: ${user.email}');
        return user;
      }
    } catch (e) {
      debugPrint('Error getting current account: $e');
    }
    
    // No user found - clear any stale state
    final wasSignedIn = await _secureStorage.read(key: _signedInKey) == 'true';
    if (wasSignedIn) {
      debugPrint('No active session found, clearing stale authentication state.');
      await _secureStorage.delete(key: _signedInKey);
      await _secureStorage.delete(key: _userEmailKey);
    }
    
    return null;
  }
  
  /// Dispose resources
  void dispose() {
    // No subscriptions to cancel in v6
  }
}
