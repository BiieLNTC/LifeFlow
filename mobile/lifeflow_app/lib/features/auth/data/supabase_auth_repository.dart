import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/core/config/app_config.dart';
import 'package:lifeflow_app/core/supabase/supabase_provider.dart';
import 'package:lifeflow_app/features/auth/domain/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(ref.watch(supabaseClientProvider));
});

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  AuthSessionState get currentSession => _mapSession(
    _client.auth.currentSession,
    AuthSessionStatus.signedIn,
  );

  @override
  Stream<AuthSessionState> get authStateChanges {
    return _client.auth.onAuthStateChange.map((state) {
      final status = state.event == AuthChangeEvent.passwordRecovery
          ? AuthSessionStatus.passwordRecovery
          : AuthSessionStatus.signedIn;
      return _mapSession(state.session, status);
    });
  }

  @override
  Future<void> signIn({required String email, required String password}) {
    return _guard(() async {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    });
  }

  @override
  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String name,
  }) {
    return _guard(() async {
      final normalizedName = name.trim();
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        emailRedirectTo: AppConfig.authCallbackUrl,
        data: {'name': normalizedName},
      );

      return SignUpResult(
        requiresEmailConfirmation: response.session == null,
      );
    });
  }

  @override
  Future<void> sendPasswordReset({required String email}) {
    return _guard(() async {
      await _client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: AppConfig.authCallbackUrl,
      );
    });
  }

  @override
  Future<void> updatePassword({required String password}) {
    return _guard(() async {
      await _client.auth.updateUser(UserAttributes(password: password));
    });
  }

  @override
  Future<void> signOut() {
    return _guard(() => _client.auth.signOut(scope: SignOutScope.local));
  }

  AuthSessionState _mapSession(
    Session? session,
    AuthSessionStatus authenticatedStatus,
  ) {
    final user = session?.user;
    if (user == null) {
      return const AuthSessionState.signedOut();
    }

    return AuthSessionState(
      status: authenticatedStatus,
      userId: user.id,
      email: user.email,
      name: user.userMetadata?['name'] as String?,
    );
  }

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on AuthException catch (error) {
      throw AuthFailure(_messageFor(error));
    } catch (_) {
      throw const AuthFailure(
        'Não foi possível conectar ao serviço. Verifique sua internet e tente novamente.',
      );
    }
  }

  String _messageFor(AuthException error) {
    return switch (error.code) {
      'invalid_credentials' => 'E-mail ou senha incorretos.',
      'email_not_confirmed' => 'Confirme seu e-mail antes de entrar.',
      'user_already_exists' => 'Já existe uma conta com este e-mail.',
      'weak_password' =>
        'Use uma senha com pelo menos 8 caracteres, letras e números.',
      'over_request_rate_limit' || 'over_email_send_rate_limit' =>
        'Muitas tentativas. Aguarde alguns minutos e tente novamente.',
      'signup_disabled' => 'Novos cadastros estão temporariamente indisponíveis.',
      'email_address_invalid' => 'Informe um e-mail válido.',
      'same_password' => 'A nova senha deve ser diferente da senha atual.',
      'session_not_found' => 'Sua sessão expirou. Solicite um novo link.',
      _ => 'Não foi possível concluir a autenticação. Tente novamente.',
    };
  }
}
