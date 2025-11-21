import '../repositories/auth_repository.dart';

/// Use case for signing out the current user.
class SignOut {
  final AuthRepository repository;

  SignOut(this.repository);

  /// Execute sign-out flow.
  Future<void> call() async {
    await repository.signOut();
  }
}

