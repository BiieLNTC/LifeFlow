import 'package:flutter_test/flutter_test.dart';
import 'package:lifeflow_app/features/auth/presentation/auth_validators.dart';

void main() {
  group('validateName', () {
    test('exige o nome no cadastro', () {
      expect(validateName(null), 'Informe seu nome.');
      expect(validateName('   '), 'Informe seu nome.');
      expect(validateName('A'), 'Informe um nome válido.');
    });

    test('aceita um nome preenchido', () {
      expect(validateName(' Gabriel '), isNull);
    });
  });
}
