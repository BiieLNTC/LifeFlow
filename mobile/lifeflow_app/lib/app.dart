import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/core/router/app_router.dart';
import 'package:lifeflow_app/core/sync/sync_status_host.dart';
import 'package:lifeflow_app/core/theme/app_theme.dart';
import 'package:lifeflow_app/core/theme/theme_mode_controller.dart';

class LifeFlowApp extends ConsumerWidget {
  const LifeFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'LifeFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeControllerProvider),
      routerConfig: ref.watch(appRouterProvider),
      builder: (context, child) =>
          SyncStatusHost(child: child ?? const SizedBox.shrink()),
    );
  }
}
