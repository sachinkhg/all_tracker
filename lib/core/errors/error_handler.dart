import 'dart:async';
import 'package:flutter/foundation.dart';
import 'error_mapper.dart';

/// Centralized error handler for the application.
///
/// This class provides a consistent way to handle errors across the application,
/// including logging, user notification, and error recovery strategies.
class ErrorHandler {
  /// Handles an error and optionally shows it to the user.
  ///
  /// Parameters:
  /// - [error]: The error/exception that occurred
  /// - [stackTrace]: Optional stack trace
  /// - [onError]: Optional callback to handle the error (e.g., show dialog, log)
  /// - [onRetry]: Optional callback for retry action if error is recoverable
  ///
  /// Returns a Future that completes with the user-friendly error message.
  static Future<String> handleError(
    Object error, {
    StackTrace? stackTrace,
    void Function(String userMessage)? onError,
    Future<void> Function()? onRetry,
  }) async {
    // Get user-friendly message
    final userMessage = ErrorMapper.toUserMessage(error);

    // Get detailed message for logging
    final detailedMessage = ErrorMapper.toDetailedMessage(error, stackTrace);

    // Log the error (in production, send to crash reporting service)
    _logError(error, detailedMessage);

    // Check if error is recoverable (can be used for retry logic)
    // final isRecoverable = ErrorMapper.isRecoverable(error);

    // Call error callback if provided
    if (onError != null) {
      onError(userMessage);
    } else {
      // Default: debugPrint to console (should be replaced with proper logging in production)
      debugPrint('Error: $detailedMessage');
    }

    return userMessage;
  }

  /// Logs an error with appropriate severity level.
  ///
  /// In production, this should integrate with a crash reporting service
  /// like Firebase Crashlytics, Sentry, etc.
  static void _logError(Object error, String detailedMessage) {
    // Integrate with crash reporting service
    // Example: FirebaseCrashlytics.instance.recordError(error, stackTrace);
    debugPrint('[ErrorHandler] $detailedMessage');
  }

  /// Wraps an async operation with error handling.
  ///
  /// Example:
  /// ```dart
  /// final result = await ErrorHandler.wrapAsync(
  ///   () => repository.getAll(),
  ///   onError: (message) => showErrorDialog(message),
  /// );
  /// ```
  static Future<T?> wrapAsync<T>(
    Future<T> Function() operation, {
    void Function(String userMessage)? onError,
    Future<void> Function()? onRetry,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      await handleError(
        error,
        stackTrace: stackTrace,
        onError: onError,
        onRetry: onRetry,
      );
      return null;
    }
  }

  /// Wraps a sync operation with error handling.
  ///
  /// Example:
  /// ```dart
  /// final result = ErrorHandler.wrapSync(
  ///   () => service.process(data),
  ///   onError: (message) => showErrorDialog(message),
  /// );
  /// ```
  static T? wrapSync<T>(
    T Function() operation, {
    void Function(String userMessage)? onError,
  }) {
    try {
      return operation();
    } catch (error, stackTrace) {
      handleError(
        error,
        stackTrace: stackTrace,
        onError: onError,
      );
      return null;
    }
  }
}

