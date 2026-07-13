import 'package:dio/dio.dart';

import '../../../../core/storage/token_storage.dart';
import '../../../../core/utils/failure.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._tokenStorage);

  final AuthRemoteDataSource _remote;
  final TokenStorage _tokenStorage;

  @override
  Future<Result<AuthUser>> login(String npi, String password) async {
    try {
      final response = await _remote.login(
        LoginRequest(npi: npi, password: password),
      );

      if (response.token.isEmpty) {
        return const Result.failure(Failure('Token manquant dans la reponse'));
      }

      await _tokenStorage.saveToken(response.token);
      await _tokenStorage.saveUser(response.user);
      return Result.success(response.user.toEntity());
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = _mapDioError(statusCode, e.response?.data);
      return Result.failure(Failure(message, statusCode: statusCode));
    } catch (_) {
      return const Result.failure(Failure('Erreur inconnue lors du login'));
    }
  }

  @override
  Future<Result<AuthUser>> getCurrentUser() async {
    try {
      final response = await _remote.getCurrentUser();
      return Result.success(response.toEntity());
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = _mapDioError(statusCode, e.response?.data);
      return Result.failure(Failure(message, statusCode: statusCode));
    } catch (_) {
      return const Result.failure(Failure('Erreur lors de la recuperation de l\'utilisateur'));
    }
  }

  @override
  Future<Result<AuthUser>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String npi,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _remote.register(
        RegisterRequest(
          name: firstName,
          lastName: lastName,
          email: email,
          phone: phone,
          npi: npi,
          password: password,
          passwordConfirmation: passwordConfirmation,
        ),
      );

      if (response.token.isEmpty) {
        return const Result.failure(Failure('Token manquant dans la reponse'));
      }

      await _tokenStorage.saveToken(response.token);
      await _tokenStorage.saveUser(response.user);
      return Result.success(response.user.toEntity());
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = _mapDioError(statusCode, e.response?.data);
      return Result.failure(Failure(message, statusCode: statusCode));
    } catch (_) {
      return const Result.failure(Failure('Erreur inconnue lors de l\'inscription'));
    }
  }

  @override
  Future<Result<AuthUser>> updateProfile({
    String? name,
    String? lastname,
    String? email,
    String? phone,
    String? currentPassword,
    String? password,
    String? passwordConfirmation,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (name != null) data['name'] = name;
      if (lastname != null) data['lastname'] = lastname;
      if (email != null) data['email'] = email;
      if (phone != null) data['phone'] = phone;
      if (currentPassword != null) data['current_password'] = currentPassword;
      if (password != null) data['password'] = password;
      if (passwordConfirmation != null) {
        data['password_confirmation'] = passwordConfirmation;
      }

      final response = await _remote.updateProfile(data);
      
      // Update saved user in storage
      await _tokenStorage.saveUser(response);
      
      return Result.success(response.toEntity());
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = _mapDioError(statusCode, e.response?.data);
      return Result.failure(Failure(message, statusCode: statusCode));
    } catch (e) {
      return Result.failure(Failure('Erreur lors de la mise a jour du profil: ${e.toString()}'));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _remote.logout();
      return const Result.success(null);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = _mapDioError(statusCode, e.response?.data);
      return Result.failure(Failure(message, statusCode: statusCode));
    } catch (_) {
      return const Result.failure(Failure('Erreur lors de la deconnexion'));
    }
  }

  String _mapDioError(int? statusCode, dynamic data) {
    if (statusCode == 401) {
      return 'Identifiants incorrects';
    }
    if (statusCode == 422) {
      final errors = data is Map<String, dynamic> ? data['errors'] : null;
      if (errors is Map) {
        final messages = <String>[];
        for (final entry in errors.values) {
          if (entry is List) {
            for (final item in entry) {
              messages.add(item.toString());
            }
          } else {
            messages.add(entry.toString());
          }
        }
        if (messages.isNotEmpty) {
          return messages.join('\n');
        }
      }
      return 'Donnees invalides';
    }
    if (statusCode == 500) {
      return 'Erreur serveur, reessaie plus tard';
    }
    final messageFromApi = data is Map<String, dynamic> ? data['message'] : null;
    if (messageFromApi is String && messageFromApi.isNotEmpty) {
      return messageFromApi;
    }
    return 'Erreur de connexion, verifiez vôtre connexion internet';
  }
}
