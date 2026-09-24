import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/features/auth/data/supabase_auth_repository.dart';
import 'package:lifeflow_app/features/auth/domain/auth_repository.dart';

final authSessionProvider = StreamProvider<AuthSessionState>((ref) async* {
  final repository = ref.watch(authRepositoryProvider);
  yield repository.currentSession;
  yield* repository.authStateChanges;
});

enum AuthAction { signIn, signUp, resetPassword, updatePassword, signOut }

class AuthActionState {
  const AuthActionState({
    this.action,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  final AuthAction? action;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthActionState>(AuthController.new);

class AuthController extends Notifier<AuthActionState> {
  @override
  AuthActionState build() => const AuthActionState();

  Future<bool> signIn({required String email, required String password}) {
    return _run(
      AuthAction.signIn,
      () => ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password),
    );
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    const action = AuthAction.signUp;
    state = const AuthActionState(action: action, isLoading: true);

    try {
      final result = await ref
          .read(authRepositoryProvider)
          .signUp(email: email, password: password, name: name);
      state = AuthActionState(
        action: action,
        successMessage: result.requiresEmailConfirmation
            ? 'Cadastro realizado. Confirme sua conta pelo e-mail enviado.'
            : 'Conta criada com sucesso.',
      );
      return true;
    } on AuthFailure catch (error) {
      state = AuthActionState(action: action, errorMessage: error.message);
      return false;
    } catch (_) {
      state = const AuthActionState(
        action: action,
        errorMessage: 'Não foi possível criar sua conta. Tente novamente.',
      );
      return false;
    }
  }

  Future<bool> sendPasswordReset({required String email}) {
    return _run(
      AuthAction.resetPassword,
      () => ref
          .read(authRepositoryProvider)
          .sendPasswordReset(email: email),
      successMessage: 'Enviamos um link de recuperação para seu e-mail.',
    );
  }

  Future<bool> updatePassword({required String password}) {
    return _run(
      AuthAction.updatePassword,
      () => ref
          .read(authRepositoryProvider)
          .updatePassword(password: password),
      successMessage: 'Senha atualizada com sucesso.',
    );
  }

  Future<bool> signOut() {
    return _run(
      AuthAction.signOut,
      () => ref.read(authRepositoryProvider).signOut(),
    );
  }

  Future<bool> _run(
    AuthAction action,
    Future<void> Function() operation, {
    String? successMessage,
  }) async {
    state = AuthActionState(action: action, isLoading: true);

    try {
      await operation();
      state = AuthActionState(
        action: action,
        successMessage: successMessage,
      );
      return true;
    } on AuthFailure catch (error) {
      state = AuthActionState(action: action, errorMessage: error.message);
      return false;
    } catch (_) {
      state = AuthActionState(
        action: action,
        errorMessage: 'Ocorreu um erro inesperado. Tente novamente.',
      );
      return false;
    }
  }
}
