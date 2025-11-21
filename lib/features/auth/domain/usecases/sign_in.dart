import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for signing in a user.
class SignIn {
  final AuthRepository repository;

  SignIn(this.repository);

  /// Execute sign-in flow.
  /// 
  /// Returns [User] if successful, null otherwise.
  Future<User?> call() async {
    return await repository.signIn();
  }
}

