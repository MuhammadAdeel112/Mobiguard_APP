class Failure {
  final String message;
  final int? statusCode;

  const Failure(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.statusCode});
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message) : super(statusCode: null);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.statusCode});
}

class ValidationFailure extends Failure {
  final Map<String, List<String>> errors;
  const ValidationFailure(super.message, {super.statusCode, this.errors = const {}});
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}
