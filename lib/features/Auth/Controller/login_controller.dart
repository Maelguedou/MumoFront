import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/token_storage.dart';
import '../data/login_state_model.dart';
import '../data/user_model.dart';
import '../di/auth_providers.dart';
import '../domain/entities/auth_user.dart';

final authControllerProvider = NotifierProvider<AuthController, AuthStateModel>(
  () {
    return AuthController();
  },
);

class AuthController extends Notifier<AuthStateModel> {
  @override
  AuthStateModel build() {
    return AuthStateModel();
  }

  // Charge l'utilisateur connecté depuis l'API
  Future<void> fetchCurrentUser() async {
    try {
      final result = await ref.read(getCurrentUserUseCaseProvider).call();
      if (result.isSuccess && result.data != null) {
        state = state.copyWith(user: result.data);
      }
    } catch (_) {
      // Ignore errors; user remains whatever it was
    }
  }

  Future<void> login(String npi, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await ref.read(loginUseCaseProvider).call(npi, password);

    if (result.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        user: result.data,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.error?.message ?? 'Erreur de connexion',
      );
    }
  }

  Future<void> ensureUserLoaded() async {
    if (state.user != null) return; // User already loaded
    try {
      final savedUser = await ref.read(tokenStorageProvider).readUser();
      if (savedUser != null) {
        state = state.copyWith(user: savedUser.toEntity());
      }
    } catch (_) {
      // Ignore restore errors
    }
  }

  void setMinimalUser(String userId) {
    // Create a minimal user with just the ID (for fallback when user data isn't available)
    state = state.copyWith(user: AuthUser(id: userId, npi: null, name: null));
  }

  Future<void> selectContext(AuthContext context) async {
    final currentUser = state.user;
    if (currentUser == null) return;

    final selectedUser = AuthUser(
      id: currentUser.id,
      npi: currentUser.npi,
      name: currentUser.name,
      firstName: currentUser.firstName,
      phone: currentUser.phone,
      lastname: currentUser.lastname,
      role: context.role,
      email: currentUser.email,
      mustChangePassword: currentUser.mustChangePassword,
      contexts: currentUser.contexts,
    );

    state = state.copyWith(user: selectedUser);
    await ref
        .read(tokenStorageProvider)
        .saveUser(UserModel.fromEntity(selectedUser));
  }

  // Pour déconnecter l'utilisateur plus tard
  Future<void> logout() async {
    // Attempt server-side logout; regardless of result, clear local token and reset state.
    try {
      final result = await ref.read(logoutUseCaseProvider).call();
      // ignore result contents; we'll clear local storage below
      if (result.isSuccess) {
        await ref.read(tokenStorageProvider).clear();
        state = AuthStateModel();
        return;
      }
      // On failure, still clear local storage to ensure user is logged out locally
      await ref.read(tokenStorageProvider).clear();
      state = AuthStateModel();
    } catch (_) {
      await ref.read(tokenStorageProvider).clear();
      state = AuthStateModel();
    }
  }

  Future<void> updateProfile({
    String? name,
    String? lastname,
    String? email,
    String? phone,
    String? currentPassword,
    String? password,
    String? passwordConfirmation,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await ref
        .read(updateProfileUseCaseProvider)
        .call(
          name: name,
          lastname: lastname,
          email: email,
          phone: phone,
          currentPassword: currentPassword,
          password: password,
          passwordConfirmation: passwordConfirmation,
        );

    if (result.isSuccess) {
      final updatedUser = result.data;
      final currentUser = state.user;
      final mergedUser = updatedUser == null || currentUser == null
          ? updatedUser
          : AuthUser(
              id: updatedUser.id ?? currentUser.id,
              npi: updatedUser.npi ?? currentUser.npi,
              name: updatedUser.name ?? currentUser.name,
              firstName: updatedUser.firstName ?? currentUser.firstName,
              phone: updatedUser.phone ?? currentUser.phone,
              lastname: updatedUser.lastname ?? currentUser.lastname,
              role: updatedUser.role ?? currentUser.role,
              email: updatedUser.email ?? currentUser.email,
              mustChangePassword:
                  updatedUser.mustChangePassword ??
                  currentUser.mustChangePassword,
              contexts: updatedUser.contexts.isNotEmpty
                  ? updatedUser.contexts
                  : currentUser.contexts,
            );

      if (mergedUser != null) {
        await ref
            .read(tokenStorageProvider)
            .saveUser(UserModel.fromEntity(mergedUser));
      }

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        user: mergedUser,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.error?.message ?? 'Erreur lors de la mise à jour',
      );
    }
  }

  void resetStatus() {
    state = AuthStateModel(user: state.user);
  }
}
