import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/register_draft_model.dart';

class RegisterDraftNotifier extends Notifier<RegisterDraft> {
  @override
  RegisterDraft build() => const RegisterDraft();

  void setFirstName(String value) {
    state = state.copyWith(firstName: value.trim());
  }

  void setLastName(String value) {
    state = state.copyWith(lastName: value.trim());
  }

  void setEmail(String value) {
    state = state.copyWith(email: value.trim());
  }

  void setPhone(String value) {
    state = state.copyWith(phone: value.trim());
  }

  void setNpi(String value) {
    state = state.copyWith(npi: value.trim());
  }

  void setPassword(String value) {
    state = state.copyWith(password: value);
  }

  void setConfirmPassword(String value) {
    state = state.copyWith(confirmPassword: value);
  }

  void reset() {
    state = const RegisterDraft();
  }
}

final registerDraftProvider = NotifierProvider<RegisterDraftNotifier, RegisterDraft>(
  RegisterDraftNotifier.new,
);
