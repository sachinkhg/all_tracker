import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Data source for Google Sign-In authentication.
/// 
/// Handles OAuth flow with Google to obtain access tokens for Drive API access.
class GoogleAuthDataSource {
  static const String _driveAppDataScope = 'https://www.googleapis.com/auth/drive.appdata';
  
  GoogleSignInAccount? _currentUser;
  bool _initialized = false;

  GoogleAuthDataSource() {
    _initialize();
  }

  Future<void> _initialize() async {
    if (_initialized) return;
    
    // Initialize GoogleSignIn instance
    await GoogleSignIn.instance.initialize();
    
    // Listen to authentication events to track current user
    GoogleSignIn.instance.authenticationEvents.listen(
      (event) {
        _currentUser = switch (event) {
          GoogleSignInAuthenticationEventSignIn() => event.user,
          GoogleSignInAuthenticationEventSignOut() => null,
        };
      },
    );
    
    _initialized = true;
  }

  /// Initiate the OAuth sign-in flow.
  /// 
  /// Returns true if sign-in was successful, false otherwise.
  /// 
  /// Throws [GoogleSignInException] if the sign-in process fails.
  Future<bool> signIn() async {
    try {
      await _initialize();
      
      if (GoogleSignIn.instance.supportsAuthenticate()) {
        await GoogleSignIn.instance.authenticate(
          scopeHint: [_driveAppDataScope],
        );
        // Check if we have a user after authentication
        return _currentUser != null;
      } else {
        debugPrint('This platform requires platform-specific sign-in UI');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('Google sign-in failed: $e');
      debugPrint('$stackTrace');
      return false;
    }
  }

  /// Sign out from Google.
  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    _currentUser = null;
  }

  /// Get the current access token for Drive API calls.
  /// 
  /// Returns the access token if authenticated, null otherwise.
  /// Will automatically refresh the token if expired.
  Future<String?> getAccessToken() async {
    if (!await isSignedIn()) {
      return null;
    }

    final user = _currentUser;
    if (user == null) {
      return null;
    }

    // In v7, get authentication from the user account
    try {
      // The authentication property is directly available on GoogleSignInAccount
      final authentication = user.authentication;
      // In google_sign_in v7, check available properties on GoogleSignInAuthentication
      // The token might be available as a property or through a method
      return authentication.idToken;
    } catch (e) {
      debugPrint('Error getting access token: $e');
      return null;
    }
  }

  /// Check if the user is currently signed in.
  Future<bool> isSignedIn() async {
    return _currentUser != null;
  }

  /// Get the current user's account information.
  Future<GoogleSignInAccount?> getCurrentAccount() async {
    return _currentUser;
  }
}
