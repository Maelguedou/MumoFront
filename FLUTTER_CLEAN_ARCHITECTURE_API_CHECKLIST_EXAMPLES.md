# Checklist API + Clean Architecture (toutes les etapes avec code)

Ce fichier couvre rigoureusement toutes les etapes: core -> domain -> data -> presentation -> providers. Les exemples sont generiques et adaptables a n importe quelle API.

## 1) Core: configuration API

Fichier: core/api/api_config.dart

```dart
class ApiConfig {
  static const baseUrl = 'https://api.example.com';
  static const connectTimeout = Duration(seconds: 15);
  static const receiveTimeout = Duration(seconds: 15);
}
```

Pourquoi: une seule source de verite pour l URL et les timeouts.

## 2) Core: client API

Fichier: core/api/api_client.dart

```dart
class ApiClient {
  ApiClient(this._dio);
  final Dio _dio;

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) {
    return _dio.get<T>(path, queryParameters: query);
  }

  Future<Response<T>> post<T>(String path, {dynamic data}) {
    return _dio.post<T>(path, data: data);
  }

  Future<Response<T>> put<T>(String path, {dynamic data}) {
    return _dio.put<T>(path, data: data);
  }

  Future<Response<T>> delete<T>(String path, {dynamic data}) {
    return _dio.delete<T>(path, data: data);
  }
}
```

Pourquoi: un seul client pour tout le projet, pas d HTTP disperse.

## 3) Core: interceptor

Fichier: core/api/api_interceptor.dart

```dart
class ApiInterceptor extends Interceptor {
  ApiInterceptor(this._tokenStorage);
  final TokenStorage _tokenStorage;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokenStorage.readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }
}
```

Pourquoi: tu ajoutes le token et tu centralises la gestion des erreurs.

## 4) Core: failure

Fichier: core/utils/failure.dart

```dart
class Failure {
  final String message;
  final int? statusCode;
  const Failure(this.message, {this.statusCode});
}
```

Pourquoi: toutes les erreurs ont le meme format.

## 5) Core: result

Fichier: core/utils/result.dart

```dart
class Result<T> {
  final T? data;
  final Failure? error;

  const Result.success(this.data) : error = null;
  const Result.failure(this.error) : data = null;

  bool get isSuccess => data != null;
}
```

Pourquoi: un type unique pour le succes et l echec.

## 6) Core: token storage

Fichier: core/storage/token_storage.dart

```dart
class TokenStorage {
  TokenStorage(this._storage);
  final FlutterSecureStorage _storage;

  Future<String?> readToken() async => _storage.read(key: 'token');
  Future<void> saveToken(String token) async => _storage.write(key: 'token', value: token);
  Future<void> clear() async => _storage.delete(key: 'token');
}
```

Pourquoi: le token est gere au meme endroit partout.

## 7) Domain: entite

Fichier: features/Auth/domain/entities/auth_user.dart

```dart
class AuthUser {
  final String id;
  const AuthUser({required this.id});
}
```

Pourquoi: l entite est pure, sans JSON ni Dio.

## 8) Domain: repository interface

Fichier: features/Auth/domain/repositories/auth_repository.dart

```dart
abstract class AuthRepository {
  Future<Result<AuthUser>> login(String npi, String password);
}
```

Pourquoi: la UI depend d une abstraction stable.

## 9) Domain: use case

Fichier: features/Auth/domain/usecases/login_usecase.dart

```dart
class LoginUseCase {
  const LoginUseCase(this._repo);
  final AuthRepository _repo;

  Future<Result<AuthUser>> call(String npi, String password) {
    return _repo.login(npi, password);
  }
}
```

Pourquoi: un point unique pour la logique metier.

## 10) Data: request DTO

Fichier: features/Auth/data/models/login_request.dart

```dart
class LoginRequest {
  final String npi;
  final String password;

  LoginRequest({required this.npi, required this.password});

  Map<String, dynamic> toJson() => {
    'npi': npi,
    'password': password,
  };
}
```

Pourquoi: une forme exacte envoyee a l API.

## 11) Data: response DTO

Fichier: features/Auth/data/models/login_response.dart

```dart
class LoginResponse {
  final String token;
  final String userId;

  LoginResponse({required this.token, required this.userId});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String,
      userId: json['userId'] as String,
    );
  }
}
```

Pourquoi: tu parses le JSON brut en objet typable.

## 12) Data: datasource remote

Fichier: features/Auth/data/datasources/auth_remote_datasource.dart

```dart
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._api);
  final ApiClient _api;

  Future<LoginResponse> login(LoginRequest request) async {
    final response = await _api.post('/auth/login', data: request.toJson());
    return LoginResponse.fromJson(response.data as Map<String, dynamic>);
  }
}
```

Pourquoi: couche API pure, sans logique metier.

## 13) Data: repository implementation

Fichier: features/Auth/data/repositories/auth_repository_impl.dart

```dart
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._tokenStorage);

  final AuthRemoteDataSource _remote;
  final TokenStorage _tokenStorage;

  @override
  Future<Result<AuthUser>> login(String npi, String password) async {
    try {
      final response = await _remote.login(LoginRequest(npi: npi, password: password));
      await _tokenStorage.saveToken(response.token);
      final user = AuthUser(id: response.userId);
      return Result.success(user);
    } catch (e) {
      return const Result.failure(Failure('Login failed'));
    }
  }
}
```

Pourquoi: mapping DTO -> Entity + gestion des erreurs.

## 14) Presentation: state

Fichier: features/Auth/controller/auth_state.dart

```dart
class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const AuthState({this.isLoading = false, this.errorMessage, this.isSuccess = false});

  AuthState copyWith({bool? isLoading, String? errorMessage, bool? isSuccess}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}
```

Pourquoi: un state simple et previsible.

## 15) Presentation: controller

Fichier: features/Auth/controller/login_controller.dart

```dart
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<void> login(String npi, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await ref.read(loginUseCaseProvider).call(npi, password);

    if (result.isSuccess) {
      state = state.copyWith(isLoading: false, isSuccess: true);
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.error?.message ?? 'Erreur de connexion',
      );
    }
  }
}
```

Pourquoi: le controller orchestre le flux sans connaitre l API.

## 16) Presentation: UI

Fichier: features/Auth/presentation/login_page.dart

```dart
ElevatedButton(
  onPressed: authState.isLoading ? null : _submit,
  child: authState.isLoading
      ? const CircularProgressIndicator()
      : const Text('Se connecter'),
)
```

Pourquoi: l UI ne fait que rendre l etat et appeler le controller.

## 17) Providers (composition root)

Fichier: core/di/providers.dart

```dart
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(const FlutterSecureStorage());
});

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
  dio.interceptors.add(ApiInterceptor(ref.read(tokenStorageProvider)));
  return dio;
});

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref.read(dioProvider)));
final authRemoteProvider = Provider<AuthRemoteDataSource>((ref) => AuthRemoteDataSource(ref.read(apiClientProvider)));
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.read(authRemoteProvider), ref.read(tokenStorageProvider)),
);
final loginUseCaseProvider = Provider<LoginUseCase>((ref) => LoginUseCase(ref.read(authRepositoryProvider)));
final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);
```

Pourquoi: un seul endroit pour brancher toutes les dependances.
