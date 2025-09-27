// lib/services/1_infrastructure/shared/service_result.dart

import 'package:equatable/equatable.dart';

/*
  Why ServiceResult is needed:
  Problem: Without it, each service handles errors differently
  (exceptions, null returns, etc.), making the codebase inconsistent and hard to use.
  Solution: ServiceResult provides a consistent wrapper for all infrastructure operations. 

  Used by ALL infrastructure services.

  Benefits:
  - Consistent: All services use same pattern
  - Type-safe: Know what type you get on success
  - Error-safe: Can't accidentally use null data
  - Composable: Easy to chain operations

  Without ServiceResult, you'd have inconsistent error handling
  across firebase_auth, firestore, places, payments, etc.
*/

/// Service exception types for categorizing infrastructure errors
enum ServiceErrorType {
  /// Network connectivity issues, timeouts, etc.
  network,

  /// Authentication/authorization failures
  authentication,

  /// Data validation errors from external services
  validation,

  /// Business rule violations detected at infrastructure level
  business,

  /// Configuration or setup issues
  configuration,

  /// External service unavailable or rate limited
  serviceUnavailable,

  /// Resource was not found (e.g., missing document, deleted entity)
  notFound,

  /// Unknown or unexpected errors
  unknown,
}

/// Infrastructure service exception
///
/// Represents technical errors that occur in the infrastructure layer,
/// separate from domain exceptions which represent business rule violations.
class ServiceException implements Exception {
  final String message;
  final ServiceErrorType type;
  final dynamic originalError;

  const ServiceException(this.message, this.type, [this.originalError]);

  @override
  String toString() => 'ServiceException(${type.name}): $message';
}

/// Result wrapper for infrastructure service operations
///
/// Provides consistent result handling across all infrastructure services
/// while maintaining clean separation from domain layer exceptions.
/// Enables proper error propagation to upper layers.
class ServiceResult<T> extends Equatable {
  /// Whether the operation completed successfully
  final bool isSuccess;

  /// The successful result data (null if failure)
  final T? data;

  /// Human-readable error message for UI display
  final String? errorMessage;

  /// Technical exception details for logging and debugging
  final ServiceException? exception;

  /// Creates a successful result with data
  const ServiceResult.success(this.data)
    : isSuccess = true,
      errorMessage = null,
      exception = null;

  /// Creates a successful result with no data (void operations)
  const ServiceResult.successVoid()
    : isSuccess = true,
      data = null,
      errorMessage = null,
      exception = null;

  /// Creates a failure result with error message and optional exception
  const ServiceResult.failure(this.errorMessage, [this.exception])
    : isSuccess = false,
      data = null;

  /// Whether this result represents a failure
  bool get isFailure => !isSuccess;

  /// Gets the error message or a default message if none provided
  String getErrorMessage() {
    return errorMessage ?? 'Unknown error occurred';
  }

  /// Maps the success data to a different type
  /// Returns failure result if this result is already a failure
  ServiceResult<R> map<R>(R Function(T data) mapper) {
    if (isFailure) {
      return ServiceResult.failure(errorMessage!, exception);
    }
    return ServiceResult.success(mapper(data as T));
  }

  /// Chains another async operation if this result is successful
  /// Returns the failure result if this result is already a failure
  Future<ServiceResult<R>> then<R>(
    Future<ServiceResult<R>> Function(T data) next,
  ) async {
    if (isFailure) {
      return ServiceResult.failure(errorMessage!, exception);
    }
    return await next(data as T);
  }

  @override
  List<Object?> get props => [isSuccess, data, errorMessage, exception];

  @override
  String toString() {
    if (isSuccess) {
      return 'ServiceResult.success($data)';
    } else {
      return 'ServiceResult.failure($errorMessage)';
    }
  }
}
