enum AuthSessionStatus { signedOut, signedIn, passwordRecovery }

class AuthSessionState {
  const AuthSessionState({
    required this.status,
    this.userId,
    this.email,
    this.name,
  });

  const AuthSessionState.signedOut()
    : status = AuthSessionStatus.signedOut,
      userId = null,
      email = null,
      name = null;

  final AuthSessionStatus status;
  final String? userId;
  final String? email;
  final String? name;

  bool get isAuthenticated => status != AuthSessionStatus.signedOut;
}

class SignUpResult {
  const SignUpResult({required this.requiresEmailConfirmation});

  final bool requiresEmailConfirmation;
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class AuthRepository {
  AuthSessionState get currentSession;

  Stream<AuthSessionState> get authStateChanges;

  Future<void> signIn({required String email, required String password});

  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String name,
  });

  Future<void> sendPasswordReset({required String email});

  Future<void> updatePassword({required String password});

  Future<void> signOut();
}
