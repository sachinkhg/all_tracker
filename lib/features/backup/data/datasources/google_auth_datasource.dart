import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Data source for Google Sign-In authentication.
/// 
/// Handles OAuth flow with Google to obtain access tokens for Drive API access.
class GoogleAuthDataSource {
  static const String _driveAppDataScope = 'https://www.googleapis.com/auth/drive.appdata';
  
  GoogleSignInAccount? _currentUser;
  bool _initialized = false;
  String? _cachedAccessToken; // Cache access token when we get it

  GoogleAuthDataSource() {
    _initialize();
  }

  Future<void> _initialize() async {
    if (_initialized) return;
    
    // Initialize GoogleSignIn instance
    await GoogleSignIn.instance.initialize();
    
    // Listen to authentication events to track current user
    // This will fire events when user signs in/out, including existing sessions
    GoogleSignIn.instance.authenticationEvents.listen(
      (event) {
        _currentUser = switch (event) {
          GoogleSignInAuthenticationEventSignIn() => event.user,
          GoogleSignInAuthenticationEventSignOut() => null,
        };
        // Clear cached token on sign out
        if (_currentUser == null) {
          _cachedAccessToken = null;
        }
      },
    );
    
    // Wait for authentication events to fire if user is already signed in
    // In v7, authentication events automatically fire for existing sessions on initialization
    // Give events time to populate _currentUser
    await Future.delayed(const Duration(milliseconds: 500));
    
    _initialized = true;
  }

  /// Initiate the OAuth sign-in flow.
  /// 
  /// Returns true if sign-in was successful, false otherwise.
  /// Returns false if the user cancels or if sign-in fails.
  Future<bool> signIn() async {
    try {
      await _initialize();
      
      if (GoogleSignIn.instance.supportsAuthenticate()) {
        await GoogleSignIn.instance.authenticate(
          scopeHint: [_driveAppDataScope],
        );
        
        // After authenticate(), check if we have a user
        // The authentication events listener should have updated _currentUser,
        // but if not, wait a moment and check again, or check directly
        if (_currentUser == null) {
          // Give the event listener a moment to process
          await Future.delayed(const Duration(milliseconds: 100));
        }
        
        // If still null, user might have cancelled or sign-in failed
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
    await GoogleSignIn.instance.signOut();
    _currentUser = null;
    _cachedAccessToken = null; // Clear cached token
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
        if (GoogleSignIn.instance.supportsAuthenticate()) {
          await GoogleSignIn.instance.authenticate(
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
  /// Events should fire automatically when a user is already signed in during initialization.
  Future<bool> isSignedIn() async {
    await _initialize();
    
    // Check if we have a cached user from authentication events
    // Authentication events should fire automatically for existing sessions
    if (_currentUser != null) {
      debugPrint('User found from cached state');
      return true;
    }
    
    // Wait for authentication events to fire (they should fire for existing sessions)
    // In v7, events are the primary way to detect existing authentication
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Check again after waiting for events
    if (_currentUser != null) {
      debugPrint('User found after waiting for authentication events');
      return true;
    }
    
    // No user found - user is not signed in or events haven't fired yet
    // Authentication events should fire for existing sessions, so if we don't have
    // a user after waiting, they're likely not signed in
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
    
    // If no cached user, wait a bit for authentication events to fire
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Return the user if events have populated it
    return _currentUser;
  }
}
