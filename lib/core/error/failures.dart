import 'package:equatable/equatable.dart';

/// Base failure class for all domain errors
abstract class Failure extends Equatable {
  const Failure([this.message = 'An unexpected error occurred']);
  final String message;

  @override
  List<Object> get props => [message];
}

class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'Database operation failed']);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Permission denied']);
}

class PlatformFailure extends Failure {
  const PlatformFailure([super.message = 'Platform channel error']);
}

class ParseFailure extends Failure {
  const ParseFailure([super.message = 'Failed to parse data']);
}

class ExportFailure extends Failure {
  const ExportFailure([super.message = 'Failed to export report']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network error']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Unknown error']);
}
