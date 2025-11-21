import 'package:flutter/foundation.dart';
import 'package:all_tracker/features/backup/data/datasources/google_auth_datasource.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Implementation of [AuthRepository] using [GoogleAuthDataSource].
class AuthRepositoryImpl implements AuthRepository {
  final GoogleAuthDataSource _googleAuthDataSource;

  AuthRepositoryImpl(this._googleAuthDataSource);

  @override
  Future<User?> signIn() async {
    try {
      final success = await _googleAuthDataSource.signIn();
      if (!success) {
        return null;
      }

      return await getCurrentUser();
    } catch (e, stackTrace) {
      debugPrint('Sign in failed: $e');
      debugPrint('$stackTrace');
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleAuthDataSource.signOut();
    } catch (e, stackTrace) {
      debugPrint('Sign out failed: $e');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  @override
  Future<bool> isSignedIn() async {
    try {
      return await _googleAuthDataSource.isSignedIn();
    } catch (e, stackTrace) {
      debugPrint('Check signed in failed: $e');
      debugPrint('$stackTrace');
      return false;
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      final account = await _googleAuthDataSource.getCurrentAccount();
      if (account == null) {
        return null;
      }

      return User(
        id: account.id,
        email: account.email,
        displayName: account.displayName,
        photoUrl: account.photoUrl,
      );
    } catch (e, stackTrace) {
      debugPrint('Get current user failed: $e');
      debugPrint('$stackTrace');
      return null;
    }
  }
}

