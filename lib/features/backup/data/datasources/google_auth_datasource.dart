import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Data source for Google Sign-In authentication.
/// 
/// Handles OAuth flow with Google to obtain access tokens for Drive API access.
class GoogleAuthDataSource {
  static const String _driveAppDataScope = 'https://www.googleapis.com/auth/drive.appdata';
  static const String _signedInKey = 'google_sign_in_state';
  static const String _userEmailKey = 'google_user_email';
  
  // Singleton instance to maintain state across app lifecycle
  static GoogleAuthDataSource? _instance;
  static GoogleAuthDataSource get instance {
    _instance ??= GoogleAuthDataSource._internal();
    return _instance!;
  }
  
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Use GoogleSignIn.instance - client ID should be read from Info.plist
  // For iOS, GIDClientID must be set in Info.plist
  GoogleSignIn get _googleSignIn => GoogleSignIn.instance;
  
  GoogleSignInAccount? _currentUser;
  bool _initialized = false;
  String? _cachedAccessToken; // Cache access token when we get it
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authEventSubscription;
  
  // Private constructor for singleton
  GoogleAuthDataSource._internal() {
    _initialize();
  }
  
  // Public factory constructor - returns singleton instance
  factory GoogleAuthDataSource() => instance;

  Future<void> _initialize() async {
    if (_initialized) return;
    
    // Set up authentication event listener BEFORE initialization
    // This ensures we catch events that fire during initialization
    _authEventSubscription?.cancel();
    _authEventSubscription = _googleSignIn.authenticationEvents.listen(
      (event) {
        _currentUser = switch (event) {
          GoogleSignInAuthenticationEventSignIn() => event.user,
          GoogleSignInAuthenticationEventSignOut() => null,
        };
        // Update secure storage based on sign-in state
        if (_currentUser != null) {
          _secureStorage.write(key: _signedInKey, value: 'true');
          _secureStorage.write(key: _userEmailKey, value: _currentUser!.email);
          debugPrint('Authentication event: User signed in - ${_currentUser!.email}');
        } else {
          _secureStorage.delete(key: _signedInKey);
          _secureStorage.delete(key: _userEmailKey);
          _cachedAccessToken = null;
          debugPrint('Authentication event: User signed out');
        }
      },
    );
    
    // Initialize GoogleSignIn instance
    // This may trigger authentication events for existing sessions
    await _googleSignIn.initialize();
    
    // Check if user was previously signed in (from secure storage)
    final wasSignedIn = await _secureStorage.read(key: _signedInKey) == 'true';
    final storedEmail = await _secureStorage.read(key: _userEmailKey);
    
    if (wasSignedIn && storedEmail != null) {
      debugPrint('User was previously signed in ($storedEmail), waiting for authentication events...');
      
      // Wait longer for authentication events to fire after initialization
      // Events should fire automatically for existing sessions, but may take time
      for (int i = 0; i < 10 && _currentUser == null; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (_currentUser != null) {
          debugPrint('Session restored via authentication events: ${_currentUser!.email}');
          break;
        }
      }
      
      // If still no user after waiting, the session may have expired
      // But don't clear the state yet - let the user try to use the app
      // The state will be cleared if they explicitly sign out or if authentication fails
      if (_currentUser == null) {
        debugPrint('No authentication events received for previously signed-in user ($storedEmail)');
        debugPrint('Session may have expired. User will need to sign in again when accessing protected features.');
      }
    } else {
      // Still wait a bit for events, but not as long
      await Future.delayed(const Duration(milliseconds: 500));
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
      
      if (_googleSignIn.supportsAuthenticate()) {
        await _googleSignIn.authenticate(
          scopeHint: [_driveAppDataScope],
        );
        
        // After authenticate(), wait for authentication events to fire
        // The authentication events listener should have updated _currentUser
        if (_currentUser == null) {
          // Give the event listener time to process
          await Future.delayed(const Duration(milliseconds: 500));
        }
        
        // If still null, user might have cancelled or sign-in failed
        if (_currentUser != null) {
          debugPrint('Sign-in successful: ${_currentUser!.email}');
          // Store sign-in state in secure storage (already done by event listener, but ensure it's set)
          await _secureStorage.write(key: _signedInKey, value: 'true');
          await _secureStorage.write(key: _userEmailKey, value: _currentUser!.email);
        }
        return _currentUser != null;
      } else {
        debugPrint('This platform requires platform-specific sign-in UI');
        return false;
      }
    } on GoogleSignInException catch (e) {
      // Handle Google Sign-In specific exceptions
      if (e.code == GoogleSignInExceptionCode.canceled) {
        // User cancelled sign-in - this is expected behavior, not an error
        debugPrint('User cancelled Google sign-in');
        return false;
      } else {
        // Other Google Sign-In errors
        debugPrint('Google sign-in error: ${e.code}');
        return false;
      }
    } catch (e, stackTrace) {
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

  /// Get the current access token for Drive API calls.
  /// 
  /// Returns the access token if authenticated, null otherwise.
  /// Will automatically refresh the token if expired.
  /// 
  /// In Google Sign-In v7, authentication and authorization are separate.
  /// We need to request authorization for scopes to get the access token.
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
      // In Google Sign-In v7, try to get access token from authentication
      // First, try getting from authentication object
      final auth = await user.authentication;
      
      // Try accessing accessToken property using dynamic access
      // (In v7, the property might exist but not be in type definitions)
      try {
        final dynamicAuth = auth as dynamic;
        final accessToken = dynamicAuth.accessToken;
        if (accessToken is String && accessToken.isNotEmpty) {
          _cachedAccessToken = accessToken;
          debugPrint('Found access token on authentication object');
          return accessToken;
        }
      } catch (e) {
        debugPrint('accessToken property not available: $e');
      }
      
      // Try authorization client approach (if available in v7)
      try {
        final dynamicUser = user as dynamic;
        if (dynamicUser.authorizationClient != null) {
          final authClient = dynamicUser.authorizationClient;
          final authResult = await authClient.authorizeScopes([_driveAppDataScope]);
          if (authResult != null) {
            final token = authResult.accessToken;
            if (token is String && token.isNotEmpty) {
              _cachedAccessToken = token;
              debugPrint('Found access token via authorizationClient');
              return token;
            }
          }
        }
      } catch (e) {
        debugPrint('Authorization client approach not available: $e');
      }
      
      // If we still don't have access token, try re-authenticating with scopes
      // This might be needed if authorization wasn't granted during initial sign-in
      debugPrint('Attempting to re-authenticate with Drive scopes to get access token...');
      try {
        if (_googleSignIn.supportsAuthenticate()) {
          await _googleSignIn.authenticate(
            scopeHint: [_driveAppDataScope],
          );
          // After re-authenticating, try getting token again
          final updatedAuth = await user.authentication;
          try {
            final dynamicAuth = updatedAuth as dynamic;
            final accessToken = dynamicAuth.accessToken;
            if (accessToken is String && accessToken.isNotEmpty) {
              _cachedAccessToken = accessToken;
              debugPrint('Found access token after re-authentication with scopes');
              return accessToken;
            }
          } catch (_) {
            // Still not available
          }
        }
      } catch (reAuthError) {
        debugPrint('Re-authentication failed: $reAuthError');
      }
      
      // Log available information for debugging
      debugPrint('ERROR: Unable to retrieve OAuth accessToken for Drive API.');
      debugPrint('This will cause 401 errors when accessing Drive API.');
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
  /// 
  /// In Google Sign-In v7, we rely on authentication events to detect existing sessions.
  Future<bool> isSignedIn() async {
    await _initialize();
    
    // Check if we have a cached user from authentication events
    if (_currentUser != null) {
      debugPrint('User found from cached state: ${_currentUser!.email}');
      return true;
    }
    
    // Check if user was previously signed in (from secure storage)
    final wasSignedIn = await _secureStorage.read(key: _signedInKey) == 'true';
    final storedEmail = await _secureStorage.read(key: _userEmailKey);
    
    if (wasSignedIn && storedEmail != null) {
      debugPrint('User was previously signed in ($storedEmail), waiting for authentication events...');
      
      // Wait longer for authentication events to fire
      for (int i = 0; i < 10 && _currentUser == null; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (_currentUser != null) {
          debugPrint('User found after waiting: ${_currentUser!.email}');
          return true;
        }
      }
    } else {
      // Wait a bit for authentication events to fire
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (_currentUser != null) {
        debugPrint('User found after waiting: ${_currentUser!.email}');
        return true;
      }
    }
    
    // If we expected a user but didn't find one, clear the state
    if (wasSignedIn && _currentUser == null) {
      debugPrint('User was marked as signed in but no user found, clearing state');
      await _secureStorage.delete(key: _signedInKey);
      await _secureStorage.delete(key: _userEmailKey);
    }
    
    // No user found - user is not signed in
    debugPrint('No user found - user not signed in');
    return false;
  }

  /// Get the current user's account information.
  /// This will check for existing sessions if _currentUser is null.
  /// 
  /// In Google Sign-In v7, we rely on authentication events to detect existing sessions.
  Future<GoogleSignInAccount?> getCurrentAccount() async {
    await _initialize();
    
    // Return cached user if available
    if (_currentUser != null) {
      return _currentUser;
    }
    
    // Check if user was previously signed in (from secure storage)
    final wasSignedIn = await _secureStorage.read(key: _signedInKey) == 'true';
    final storedEmail = await _secureStorage.read(key: _userEmailKey);
    
    if (wasSignedIn && storedEmail != null) {
      debugPrint('User was previously signed in ($storedEmail), waiting for authentication events...');
      
      // Wait longer for authentication events to fire
      for (int i = 0; i < 10 && _currentUser == null; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (_currentUser != null) {
          break;
        }
      }
    } else {
      // Wait a bit for authentication events to fire
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    // If we expected a user but didn't find one, clear the state
    if (wasSignedIn && _currentUser == null) {
      debugPrint('User was marked as signed in but no user found, clearing state');
      await _secureStorage.delete(key: _signedInKey);
      await _secureStorage.delete(key: _userEmailKey);
    }
    
    // Return the user if found
    return _currentUser;
  }
  
  /// Dispose resources
  void dispose() {
    _authEventSubscription?.cancel();
  }
}

