import 'failure.dart';
class Result<T> {
  // Contient soit des donnees (success), soit une erreur (failure).
  // T est le type de data (ex: AuthUser, List<Agency>, etc.).
  final T? data;
  final Failure? error;
  final bool isSuccess;

  const Result.success(this.data)
      : error = null,
        isSuccess = true;
  const Result.failure(this.error)
      : data = null,
        isSuccess = false;
}