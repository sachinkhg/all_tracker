import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/secret_question.dart';
import '../../domain/usecases/secret_question/get_secret_questions_by_password_id.dart';
import '../../domain/usecases/secret_question/create_secret_question.dart';
import '../../domain/usecases/secret_question/update_secret_question.dart';
import '../../domain/usecases/secret_question/delete_secret_question.dart';
import 'secret_question_state.dart';

/// ---------------------------------------------------------------------------
/// SecretQuestionCubit
///
/// File purpose:
/// - Manages presentation state for SecretQuestion entities within the SecretQuestion feature.
/// - Loads, creates, updates and deletes secret questions by delegating
///   to domain use-cases.
///
/// Developer guidance:
/// - Keep domain validation and persistence in the use-cases/repository; this
///   cubit should orchestrate and transform results for UI consumption only.
/// ---------------------------------------------------------------------------

class SecretQuestionCubit extends Cubit<SecretQuestionState> {
  final GetSecretQuestionsByPasswordId getByPasswordId;
  final CreateSecretQuestion create;
  final UpdateSecretQuestion update;
  final DeleteSecretQuestion delete;

  SecretQuestionCubit({
    required this.getByPasswordId,
    required this.create,
    required this.update,
    required this.delete,
  }) : super(SecretQuestionsLoading());

  /// Loads all secret questions for a specific password.
  Future<void> loadSecretQuestions(String passwordId) async {
    emit(SecretQuestionsLoading());
    try {
      final secretQuestions = await getByPasswordId(passwordId);
      emit(SecretQuestionsLoaded(secretQuestions));
    } catch (e) {
      emit(SecretQuestionsError('Failed to load secret questions: $e'));
    }
  }

  /// Creates a new secret question.
  Future<void> createSecretQuestion({
    required String passwordId,
    required String question,
    required String answer,
  }) async {
    try {
      final newSecretQuestion = SecretQuestion(
        id: const Uuid().v4(),
        passwordId: passwordId,
        question: question,
        answer: answer,
      );

      await create(newSecretQuestion);
      await loadSecretQuestions(passwordId); // Reload to get updated list
    } catch (e) {
      emit(SecretQuestionsError('Failed to create secret question: $e'));
    }
  }

  /// Updates an existing secret question.
  Future<void> updateSecretQuestion(SecretQuestion secretQuestion) async {
    try {
      await update(secretQuestion);
      await loadSecretQuestions(secretQuestion.passwordId); // Reload to get updated list
    } catch (e) {
      emit(SecretQuestionsError('Failed to update secret question: $e'));
    }
  }

  /// Deletes a secret question by its ID.
  Future<void> deleteSecretQuestion(String id, String passwordId) async {
    try {
      await delete(id);
      await loadSecretQuestions(passwordId); // Reload to get updated list
    } catch (e) {
      emit(SecretQuestionsError('Failed to delete secret question: $e'));
    }
  }
}

