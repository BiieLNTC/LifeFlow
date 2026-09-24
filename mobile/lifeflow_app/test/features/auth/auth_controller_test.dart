import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeflow_app/features/auth/data/supabase_auth_repository.dart';
import 'package:lifeflow_app/features/auth/domain/auth_repository.dart';
import 'package:lifeflow_app/features/auth/presentation/auth_controller.dart';

import '../../support/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() async {
    container.dispose();
    await repository.close();
  });

  test('login bem-sucedido atualiza o estado sem erro', () async {
    final controller = container.read(authControllerProvider.notifier);

    final succeeded = await controller.signIn(
      email: 'motorista@motora.app',
      password: 'Senha123',
    );

    expect(succeeded, isTrue);
    expect(repository.lastEmail, 'motorista@motora.app');
    expect(container.read(authControllerProvider).errorMessage, isNull);
  });

  test('erro conhecido é exposto de forma segura para a interface', () async {
    repository.nextError = const AuthFailure('E-mail ou senha inválidos.');
    final controller = container.read(authControllerProvider.notifier);

    final succeeded = await controller.signIn(
      email: 'motorista@motora.app',
      password: 'Senha123',
    );

    expect(succeeded, isFalse);
    expect(
      container.read(authControllerProvider).errorMessage,
      'E-mail ou senha inválidos.',
    );
  });

  test('cadastro informa quando a confirmação de e-mail é necessária', () async {
    final controller = container.read(authControllerProvider.notifier);

    final succeeded = await controller.signUp(
      email: 'novo@motora.app',
      password: 'Senha123',
      name: 'Gabriel',
    );

    expect(succeeded, isTrue);
    expect(
      container.read(authControllerProvider).successMessage,
      contains('Confirme sua conta'),
    );
    expect(repository.lastName, 'Gabriel');
  });
}
