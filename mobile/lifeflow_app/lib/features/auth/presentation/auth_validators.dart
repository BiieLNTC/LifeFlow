String? validateName(String? value) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) return 'Informe seu nome.';
  if (name.length < 2) return 'Informe um nome válido.';
  return null;
}

String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  final separator = email.indexOf('@');
  final lastDot = email.lastIndexOf('.');

  if (separator <= 0 || lastDot <= separator + 1 || lastDot == email.length - 1) {
    return 'Informe um e-mail válido.';
  }

  return null;
}

String? validatePassword(String? value, {bool enforceStrength = false}) {
  final password = value ?? '';
  if (password.isEmpty) {
    return 'Informe sua senha.';
  }

  if (enforceStrength &&
      (password.length < 8 ||
          !RegExp('[A-Za-z]').hasMatch(password) ||
          !RegExp('[0-9]').hasMatch(password))) {
    return 'Use ao menos 8 caracteres, com letras e números.';
  }

  return null;
}
