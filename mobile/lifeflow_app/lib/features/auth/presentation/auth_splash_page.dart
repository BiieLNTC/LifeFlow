import 'package:flutter/material.dart';
import 'package:lifeflow_app/core/widgets/lifeflow_wordmark.dart';

class AuthSplashPage extends StatelessWidget {
  const AuthSplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Semantics(
          label: 'Carregando sessão',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LifeFlowMark(size: 72),
              SizedBox(height: 24),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
