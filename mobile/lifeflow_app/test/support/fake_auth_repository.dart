import 'dart:async';

import 'package:lifeflow_app/features/auth/domain/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    AuthSessionState initialSession = const AuthSessionState.signedOut(),
  }) : _currentSession = initialSession;

  final StreamController<AuthSessionState> _controller =
      StreamController<AuthSessionState>.broadcast();

  AuthSessionState _currentSession;

  Object? nextError;
  bool requiresEmailConfirmation = true;
  String? lastEmail;
  String? lastName;
  String? lastPasswordResetEmail;

  @override
  AuthSessionState get currentSession => _currentSession;

  @override
  Stream<AuthSessionState> get authStateChanges => _controller.stream;

  @override
  Future<void> signIn({required String email, required String password}) async {
    _throwNextErrorIfNeeded();
    lastEmail = email;
    emit(
      AuthSessionState(
        status: AuthSessionStatus.signedIn,
        userId: 'user-id',
        email: email,
        name: 'Motorista',
      ),
    );
  }

  @override
  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    _throwNextErrorIfNeeded();
    lastEmail = email;
    lastName = name;

    if (!requiresEmailConfirmation) {
      emit(
        AuthSessionState(
          status: AuthSessionStatus.signedIn,
          userId: 'user-id',
          email: email,
          name: name,
        ),
      );
    }

    return SignUpResult(
      requiresEmailConfirmation: requiresEmailConfirmation,
    );
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    _throwNextErrorIfNeeded();
    lastPasswordResetEmail = email;
  }

  @override
  Future<void> updatePassword({required String password}) async {
    _throwNextErrorIfNeeded();
    emit(
      const AuthSessionState(
        status: AuthSessionStatus.signedIn,
        userId: 'user-id',
        email: 'motorista@motora.app',
        name: 'Motorista',
      ),
    );
  }

  @override
  Future<void> signOut() async {
    _throwNextErrorIfNeeded();
    emit(const AuthSessionState.signedOut());
  }

  void emit(AuthSessionState session) {
    _currentSession = session;
    _controller.add(session);
  }

  Future<void> close() => _controller.close();

  void _throwNextErrorIfNeeded() {
    final error = nextError;
    nextError = null;
    if (error != null) {
      throw error;
    }
  }
}
