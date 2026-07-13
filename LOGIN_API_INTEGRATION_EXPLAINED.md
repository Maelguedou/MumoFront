# Integration login (explication claire)

Ce document explique, pas a pas et sans jargon inutile, ce qui a ete mis en place pour le login avec une clean architecture. Il sert de reference pour comprendre le flux et les fichiers.

## 1) Le probleme a resoudre

On veut:
- Appeler l API pour se connecter
- Recuperer un token
- Garder le code propre et facile a tester

Pour ca, on separe les responsabilites en couches. Chaque couche a un role precis.

## 2) Le flux complet (version simple)

UI (login_page.dart)
  -> Controller (login_controller.dart)
  -> Use case (login_usecase.dart)
  -> Repository (auth_repository.dart)
  -> Repository Impl (auth_repository_impl.dart)
  -> DataSource (auth_remote_datasource.dart)
  -> ApiClient (api_client.dart)
  -> HTTP

Retour:
HTTP -> DTO (login_response.dart) -> UserModel -> AuthUser -> State -> UI

## 2.1) Le meme flux, explique en 6 actions simples

1. L utilisateur clique sur "Se connecter" dans l UI.
2. Le controller appelle le use case.
3. Le use case appelle le repository (interface).
4. Le repository appelle la datasource qui fait l appel HTTP.
5. La datasource parse la reponse JSON et renvoie un LoginResponse.
6. Le repository transforme LoginResponse en AuthUser, sauvegarde le token, et renvoie le resultat au controller.

## 3) Core: ce qui est commun a tout le projet

### 3.1 ApiConfig
Fichier: lib/core/api/api_config.dart
- Definir baseUrl et timeouts une seule fois.
- Toute l app utilise ApiConfig.baseUrl.

### 3.2 ApiClient
Fichier: lib/core/api/api_client.dart
- Encapsule Dio.
- Fournit get/post/put/delete pour ne pas disperser Dio partout.

### 3.3 ApiInterceptor
Fichier: lib/core/api/api_interceptor.dart
- Ajoute automatiquement le header Authorization.
- Utilise TokenStorage pour lire le token.

### 3.4 TokenStorage
Fichier: lib/core/storage/token_storage.dart
- Stocke le token en securite.
- Lire / sauver / supprimer le token.

## 4) Domain: logique metier pure

### 4.1 AuthUser (entite)
Fichier: lib/features/Auth/domain/entities/auth_user.dart
- C est la representation propre de l utilisateur.
- Pas de JSON ici.

### 4.2 AuthRepository (interface)
Fichier: lib/features/Auth/domain/repositories/auth_repository.dart
- Decrit ce que le login doit faire.
- Pas de Dio, pas de JSON.

### 4.3 LoginUseCase
Fichier: lib/features/Auth/domain/usecases/login_usecase.dart
- Appelle le repository.
- Sert de point d entree pour la logique metier.

## 5) Data: communication API et mapping

### 5.1 LoginRequest (DTO)
Fichier: lib/features/Auth/data/models/login_request.dart
- Contient npi et password.
- toJson() pour envoyer a l API.

### 5.2 LoginResponse (DTO)
Fichier: lib/features/Auth/data/models/login_response.dart
- Parse la reponse API.
- Recupere token + user.

### 5.3 UserModel
Fichier: lib/features/Auth/data/user_model.dart
- Model cote data, construit depuis JSON.
- Converti vers AuthUser via toEntity().
- Pas de mot de passe ici pour eviter de stocker un secret.

### 5.4 AuthRemoteDataSource
Fichier: lib/features/Auth/data/datasources/auth_remote_datasource.dart
- Fait l appel HTTP /login.
- Retourne un LoginResponse.

### 5.5 AuthRepositoryImpl
Fichier: lib/features/Auth/data/repositories/auth_repository_impl.dart
- Transforme LoginResponse en AuthUser.
- Sauve le token dans TokenStorage.
- Mappe les erreurs Dio en messages clairs.

## 6) Presentation: state + controller

### 6.1 AuthStateModel
Fichier: lib/features/Auth/data/login_state_model.dart
- Garde l etat: isLoading, isSuccess, errorMessage, user.
- Ne stocke pas le token dans l UI.

### 6.2 AuthController
Fichier: lib/features/Auth/Controller/login_controller.dart
- Appelle LoginUseCase.
- Met a jour le state.
- logout() efface le token via TokenStorage.

## 7) Providers (injection des dependances)

Fichier: lib/features/Auth/di/auth_providers.dart

Explication simple:
- Un provider est une "usine" qui construit un objet.
- Le fichier DI dit juste "comment construire" chaque piece.
- Tu n ecris plus new partout dans le code, c est centralise.

Ce que fait chaque provider:
- authRemoteDataSourceProvider: cree la datasource avec ApiClient.
- authRepositoryProvider: cree le repository avec datasource + TokenStorage.
- loginUseCaseProvider: cree le use case avec repository.

Pourquoi c est utile:
- Si un jour tu changes ApiClient ou AuthRepositoryImpl, tu ne touches pas l UI.
- Tu peux remplacer une piece par un mock pour tester.

## 8) Ce que tu dois verifier / adapter

- Le chemin API: /login dans auth_remote_datasource.dart
- Les champs retournes par ton backend: token, user, id, npi, name
- Les messages d erreur dans auth_repository_impl.dart

## 9) Resume ultra-simple

- UI ne parle jamais a Dio.
- Controller ne parle jamais a l API.
- Repository est le pont entre data et domain.
- Data connait le JSON, Domain ne connait pas le JSON.
- Token est stocke dans TokenStorage, pas dans l UI.

## 10) Mini exemple concret (fictif)

Request envoyee par l app:

```
POST /login
{
  "npi": "123456",
  "password": "secret"
}
```

Reponse attendue:

```
{
  "token": "abc.def.ghi",
  "user": {
    "id": 7,
    "npi": "123456",
    "name": "Jean Dupont"
  }
}
```

Ce que fait ton code:
- LoginRequest.toJson() fabrique le JSON de la requete.
- AuthRemoteDataSource envoie la requete via ApiClient.
- LoginResponse.fromJson() lit la reponse.
- AuthRepositoryImpl sauvegarde le token.
- AuthController met a jour le state pour l UI.

Si tu veux, je peux aussi faire une version avec un schema graphique ou une version plus courte en 1 page.
