import 'package:equatable/equatable.dart';
import '../../domain/entities/secret_question.dart';

/// ---------------------------------------------------------------------------
/// SecretQuestionState (Bloc State Definitions)
///
/// File purpose:
/// - Defines the various states used by the [SecretQuestionCubit] for managing secret question
///   lifecycle and UI rendering.
/// - Encapsulates data and UI-relevant conditions (loading, loaded, error)
///   using immutable, equatable classes for efficient Bloc rebuilds.
///
/// State overview:
/// - [SecretQuestionsLoading]: Emitted while loading secret questions from the data source.
/// - [SecretQuestionsLoaded]: Emitted when secret questions are successfully loaded; contains a list
///   of [SecretQuestion] entities.
/// - [SecretQuestionsError]: Emitted when an exception or data failure occurs.
///
/// Developer guidance:
/// - States are intentionally minimal and serializable-safe (no mutable fields).
/// - Always emit new instances (avoid mutating existing state).
/// - When adding new states, ensure they extend [SecretQuestionState] and override
///   `props` for correct Equatable comparisons.
///
/// ---------------------------------------------------------------------------

// Base state for secret question operations
abstract class SecretQuestionState extends Equatable {
  const SecretQuestionState();

  @override
  List<Object?> get props => [];
}

// Loading state — emitted when secret question data is being fetched.
class SecretQuestionsLoading extends SecretQuestionState {}

// Loaded state — holds the list of successfully fetched secret questions.
class SecretQuestionsLoaded extends SecretQuestionState {
  final List<SecretQuestion> secretQuestions;

  const SecretQuestionsLoaded(this.secretQuestions);

  @override
  List<Object?> get props => [secretQuestions];
}

// Error state — emitted when fetching or modifying secret questions fails.
class SecretQuestionsError extends SecretQuestionState {
  final String message;

  const SecretQuestionsError(this.message);

  @override
  List<Object?> get props => [message];
}

