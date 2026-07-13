# Verification reseau avant inscription (explication ligne par ligne)

Ce document explique l ajout du controle reseau avant l envoi du formulaire d inscription.

## 1) Dependence ajoutee

Fichier: pubspec.yaml

```
connectivity_plus: ^6.0.5
```

- Cette lib permet de verifier si l appareil est connecte (wifi, data, ou rien).
- On l utilise avant d envoyer la requete.

## 2) Import ajoute

Fichier: lib/features/Auth/Presentation/Register_page.dart

```dart
import 'package:connectivity_plus/connectivity_plus.dart';
```

- On importe la classe Connectivity pour faire le check reseau.

## 3) La methode principale modifiee

Fichier: lib/features/Auth/Presentation/Register_page.dart

```dart
Future<void> _submitRegistration() async {
  final hasConnection = await _hasConnection();
  if (!hasConnection) {
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearMaterialBanners();
    messenger.showMaterialBanner(
      const MaterialBanner(
        content: Text("Pas de connexion internet. Reessaie."),
        backgroundColor: Color(0xFFFDECEA),
        contentTextStyle: TextStyle(color: Color(0xFFB71C1C)),
        actions: [
          SizedBox.shrink(),
        ],
      ),
    );
    return;
  }

  if (_formKey.currentState!.validate()) {
    final notifier = ref.read(registerDraftProvider.notifier);
    notifier.setPhone(_phoneController.text);
    notifier.setNpi(_npiController.text);
    notifier.setPassword(_passwordController.text);
    notifier.setConfirmPassword(_confirmPasswordController.text);

    final draft = ref.read(registerDraftProvider);

    ref.read(registerControllerProvider.notifier).register(
          firstName: draft.firstName,
          lastName: draft.lastName,
          email: draft.email,
          phone: draft.phone,
          npi: draft.npi,
          password: draft.password,
          passwordConfirmation: draft.confirmPassword,
        );
  }
}
```

Explication ligne par ligne:
- `Future<void> _submitRegistration() async` : on rend la methode async pour attendre le check reseau.
- `final hasConnection = await _hasConnection();` : on demande l etat reseau.
- `if (!hasConnection) { ... return; }` : si pas de reseau, on n envoie rien.
- `if (!mounted) return;` : securite pour eviter d utiliser un context detruit.
- `ScaffoldMessenger.of(context)` : permet d afficher un message en haut.
- `showMaterialBanner(...)` : affiche un message rouge en header.
- `return;` : on stoppe la soumission.
- `if (_formKey.currentState!.validate())` : on valide les champs uniquement si reseau OK.
- `notifier.set...` : on sauvegarde les champs de l etape 2 dans le draft.
- `final draft = ref.read(...)` : on recupere toutes les infos (etape 1 + etape 2).
- `register(...)` : on envoie enfin l inscription au backend.

## 4) La methode de check reseau

Fichier: lib/features/Auth/Presentation/Register_page.dart

```dart
Future<bool> _hasConnection() async {
  final result = await Connectivity().checkConnectivity();
  return result != ConnectivityResult.none;
}
```

Explication ligne par ligne:
- `Connectivity().checkConnectivity()` : verifie l etat actuel du reseau.
- `ConnectivityResult.none` : signifie aucune connexion.
- `return result != ConnectivityResult.none` : vrai si wifi ou data.

## 5) Ce que ca change pour l utilisateur

- Si pas de connexion -> message rouge en haut, pas d envoi.
- Si connexion OK -> validation, puis envoi au backend.

## 6) Points a retenir

- Le check reseau ne garantit pas 100% que la requete passera, mais evite les envois inutiles.
- En cas de coupure pendant l envoi, la logique d erreurs backend reste la protection finale.

Si tu veux, je peux faire une version equivalente pour la page login.
