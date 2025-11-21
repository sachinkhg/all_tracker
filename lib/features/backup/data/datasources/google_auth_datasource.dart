import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Data source for Google Sign-In authentication.
/// 
/// Handles OAuth flow with Google to obtain access tokens for Drive API access.
class GoogleAuthDataSource {
  static const String _driveAppDataScope = 'https://www.googleapis.com/auth/drive.appdata';

  late final GoogleSignIn _googleSignIn;

  GoogleAuthDataSource() {
    _googleSignIn = GoogleSignIn(
      scopes: [_driveAppDataScope],
    );
  }

  /// Initiate the OAuth sign-in flow.
  /// 
  /// Returns true if sign-in was successful, false otherwise.
  /// 
  /// Throws [GoogleSignInException] if the sign-in process fails.
  Future<bool> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      return account != null;
    } catch (e, stackTrace) {
      debugPrint('Google sign-in failed: $e');
      debugPrint('$stackTrace');
      return false;
    }
  }

  /// Sign out from Google.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// Get the current access token for Drive API calls.
  /// 
  /// Returns the access token if authenticated, null otherwise.
  /// Will automatically refresh the token if expired.
  Future<String?> getAccessToken() async {
    if (!await isSignedIn()) {
      return null;
    }

    final authentication = await _googleSignIn.currentUser?.authentication;
    return authentication?.accessToken;
  }

  /// Check if the user is currently signed in.
  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  /// Get the current user's account information.
  Future<GoogleSignInAccount?> getCurrentAccount() async {
    return _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
  }
}

