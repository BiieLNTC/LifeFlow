import 'package:flutter/material.dart';
import 'package:lifeflow_app/core/theme/app_palette.dart';
import 'package:lifeflow_app/features/auth/presentation/auth_controller.dart';
import 'package:lifeflow_app/core/widgets/lifeflow_wordmark.dart';

class AuthFormShell extends StatelessWidget {
  const AuthFormShell({
    required this.title,
    required this.subtitle,
    required this.children,
    this.showBackButton = false,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showBackButton)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        tooltip: 'Voltar',
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                    )
                  else
                    const SizedBox(height: 48),
                  const SizedBox(height: 28),
                  const LifeFlowMark(size: 56),
                  const SizedBox(height: 16),
                  Text(title, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 32),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthFeedback extends StatelessWidget {
  const AuthFeedback({
    required this.state,
    required this.action,
    super.key,
  });

  final AuthActionState state;
  final AuthAction action;

  @override
  Widget build(BuildContext context) {
    if (state.action != action) {
      return const SizedBox.shrink();
    }

    final message = state.errorMessage ?? state.successMessage;
    if (message == null) {
      return const SizedBox.shrink();
    }

    final isError = state.errorMessage != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Semantics(
        liveRegion: true,
        child: Text(
          message,
          style: TextStyle(
            color: isError ? context.colors.critical : context.colors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
