# Guide Flutter Clean Architecture + Integration API

Ce guide documente une approche simple et reutilisable pour integrer une API dans ce projet en gardant ta structure actuelle et Riverpod. Il est pense pour etre copie/colle dans tous tes projets Flutter.

## 1) Architecture cible (clean + pragmatique)

Garde 3 couches dans chaque feature:

- presentation: UI + controllers (Riverpod Notifier/StateNotifier)
- domain: entites, interfaces de repository, use cases
- data: models/DTOs, data sources (remote/local), implementations de repository

Le code commun va dans core:

- core/api: client API, interceptors, erreurs
- core/storage: persistence token/session
- core/utils: result, failure, helpers

## 2) Structure de dossiers suggeree (exemple Auth)

lib/
  core/
    api/
      api_client.dart
      api_config.dart
      api_error.dart
      api_interceptor.dart
    storage/
      token_storage.dart
    utils/
      result.dart
      failure.dart
  features/
    Auth/
      presentation/
        login_page.dart
        register_page.dart
      controller/
        login_controller.dart
      domain/
        entities/
          auth_user.dart
        repositories/
          auth_repository.dart
        usecases/
          login_usecase.dart
          register_usecase.dart
      data/
        models/
          login_request.dart
          login_response.dart
        datasources/
          auth_remote_datasource.dart
        repositories/
          auth_repository_impl.dart

Note: Tu as deja Controller/Presentation/data. Ajoute domain et decoupe data en models/datasources/repositories.

## 3) Flux de donnees (regle a toujours suivre)

UI -> Controller -> UseCase -> Repository (interface) -> RepositoryImpl -> DataSource -> ApiClient -> HTTP

Les reponses reviennent dans l'autre sens avec mapping:

API JSON -> DTO Model -> Domain Entity -> Controller State -> UI

## 4) Client API (un seul point HTTP)

Utilise un seul client API pour garantir:
- baseUrl et timeouts centralises
- token attache automatiquement
- erreurs normalisees

Exemple (Dio):

```dart
class ApiConfig {
  static const baseUrl = "https://api.example.com";
  static const connectTimeout = Duration(seconds: 15);
  static const receiveTimeout = Duration(seconds: 15);
}

class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) {
    return _dio.get<T>(path, queryParameters: query);
  }

  Future<Response<T>> post<T>(String path, {dynamic data}) {
    return _dio.post<T>(path, data: data);
  }
}
```

Exemple d'interceptor (ajout token + gestion erreurs):

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
}
```

## 5) Gestion des erreurs (previsible)

Definis un type Failure dans core/utils et mappe les erreurs API vers lui.

```dart
class Failure {
  final String message;
  final int? statusCode;
  const Failure(this.message, {this.statusCode});
}

class Result<T> {
  final T? data;
  final Failure? error;
  const Result.success(this.data) : error = null;
  const Result.failure(this.error) : data = null;
  bool get isSuccess => data != null;
}
```

## 6) Couche domain (interfaces + use cases)

Interface repository (domain):

```dart
abstract class AuthRepository {
  Future<Result<AuthUser>> login(String npi, String password);
}
```

Use case (domain):

```dart
class LoginUseCase {
  const LoginUseCase(this._repo);
  final AuthRepository _repo;

  Future<Result<AuthUser>> call(String npi, String password) {
    return _repo.login(npi, password);
  }
}
```

## 7) Couche data (DTOs + datasources + repository impl)

DTO models:

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

Remote data source:

```dart
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._api);
  final ApiClient _api;

  Future<Map<String, dynamic>> login(LoginRequest request) async {
    final response = await _api.post('/auth/login', data: request.toJson());
    return response.data as Map<String, dynamic>;
  }
}
```

Repository implementation:

```dart
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);
  final AuthRemoteDataSource _remote;

  @override
  Future<Result<AuthUser>> login(String npi, String password) async {
    try {
      final json = await _remote.login(LoginRequest(npi: npi, password: password));
      final user = AuthUser.fromJson(json['user']);
      return Result.success(user);
    } catch (e) {
      return const Result.failure(Failure('Login failed'));
    }
  }
}
```

## 8) Controller (Riverpod Notifier)

Garde un state minimal et explicite:

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

Controller:

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
      state = state.copyWith(isLoading: false, errorMessage: result.error?.message ?? 'Login error');
    }
  }
}
```

## 9) Providers (composition root)

Cree des providers pour brancher les dependances:

```dart
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
  dio.interceptors.add(ApiInterceptor(ref.read(tokenStorageProvider)));
  return dio;
});

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref.read(dioProvider)));
final authRemoteProvider = Provider<AuthRemoteDataSource>((ref) => AuthRemoteDataSource(ref.read(apiClientProvider)));
final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepositoryImpl(ref.read(authRemoteProvider)));
final loginUseCaseProvider = Provider<LoginUseCase>((ref) => LoginUseCase(ref.read(authRepositoryProvider)));
```

## 10) Token storage (core/storage)

Prefere flutter_secure_storage pour les tokens. Garde read/write dans une seule classe:

```dart
class TokenStorage {
  Future<String?> readToken() async => _storage.read(key: 'token');
  Future<void> saveToken(String token) async => _storage.write(key: 'token', value: token);
  Future<void> clear() async => _storage.delete(key: 'token');
}
```

## 11) Integrer une nouvelle feature API (checklist)

1. Ajouter l'endpoint + DTOs request/response dans data/models
2. Ajouter la methode remote dans data/datasources
3. Mapper DTO -> entite domain dans repository impl
4. Ajouter la methode dans le repository interface (domain)
5. Ajouter le use case correspondant
6. Appeler le use case depuis le controller et mettre a jour le state
7. Mettre a jour l'UI pour afficher le state

Si tu respectes cette sequence, tu ne casses pas l'architecture.

## 12) Appliquer a ton code actuel (Auth)

Ton login est mocke dans le controller. Les etapes minimales pour le rendre reel:

- Creer core/api client et token storage
- Creer Auth remote datasource et repository implementation
- Ajouter LoginUseCase et l'injecter dans AuthController
- Remplacer Future.delayed par l'appel du use case

## 13) Conventions suggerees

- snake_case pour les fichiers, PascalCase pour les classes
- Garder le code d'une feature dans son dossier
- Eviter le HTTP direct dans UI ou controllers
- Toujours mapper DTO -> Entity, ne jamais exposer du JSON brut a l'UI

## 14) Plan de test rapide

- Tests DataSource: mock ApiClient et verifier le parsing JSON
- Tests Repository: mock DataSource et verifier le mapping
- Tests Controller: mock UseCase et verifier les transitions d'etat

## 15) Prochaines etapes

Si tu me partages la spec API (endpoints, request/response JSON), je peux implementer toute l'integration Auth selon ce guide.
