import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/features/auth/presentation/auth_controller.dart';
import 'package:lifeflow_app/features/auth/presentation/auth_form_shell.dart';
import 'package:lifeflow_app/features/auth/presentation/auth_validators.dart';

class UpdatePasswordPage extends ConsumerStatefulWidget {
  const UpdatePasswordPage({super.key});

  @override
  ConsumerState<UpdatePasswordPage> createState() =>
      _UpdatePasswordPageState();
}

class _UpdatePasswordPageState extends ConsumerState<UpdatePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(authControllerProvider.notifier)
        .updatePassword(password: _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(authControllerProvider);
    final isLoading =
        actionState.action == AuthAction.updatePassword &&
        actionState.isLoading;

    return AuthFormShell(
      title: 'Crie uma nova senha.',
      subtitle: 'Escolha uma senha segura para proteger seu histórico.',
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _passwordController,
                enabled: !isLoading,
                obscureText: true,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: (value) =>
                    validatePassword(value, enforceStrength: true),
                decoration: const InputDecoration(
                  labelText: 'Nova senha',
                  helperText: 'Mínimo de 8 caracteres, com letras e números.',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmationController,
                enabled: !isLoading,
                obscureText: true,
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'As senhas não coincidem.';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Confirmar nova senha',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AuthFeedback(state: actionState, action: AuthAction.updatePassword),
        FilledButton(
          onPressed: isLoading ? null : _submit,
          child: isLoading
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('SALVAR NOVA SENHA'),
        ),
      ],
    );
  }
}
