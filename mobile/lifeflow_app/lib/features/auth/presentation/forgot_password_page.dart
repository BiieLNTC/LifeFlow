import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/features/auth/presentation/auth_controller.dart';
import 'package:lifeflow_app/features/auth/presentation/auth_form_shell.dart';
import 'package:lifeflow_app/features/auth/presentation/auth_validators.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() =>
      _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(authControllerProvider.notifier)
        .sendPasswordReset(email: _emailController.text);
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(authControllerProvider);
    final isLoading =
        actionState.action == AuthAction.resetPassword &&
        actionState.isLoading;

    return AuthFormShell(
      showBackButton: true,
      title: 'Recupere seu acesso.',
      subtitle: 'Enviaremos um link seguro para você criar uma nova senha.',
      children: [
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _emailController,
            enabled: !isLoading,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            validator: validateEmail,
            onFieldSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              labelText: 'E-mail',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
          ),
        ),
        const SizedBox(height: 24),
        AuthFeedback(state: actionState, action: AuthAction.resetPassword),
        FilledButton(
          onPressed: isLoading ? null : _submit,
          child: isLoading
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('ENVIAR LINK'),
        ),
      ],
    );
  }
}
