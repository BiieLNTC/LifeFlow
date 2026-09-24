import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/core/theme/theme_mode_controller.dart';

class AppearancePage extends ConsumerWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Aparência')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            Text(
              'Tema',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Escolha como o LifeFlow deve aparecer neste aparelho.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            _ModeOption(
              icon: Icons.brightness_auto_rounded,
              title: 'Automático',
              subtitle: 'Segue o tema do sistema',
              selected: mode == ThemeMode.system,
              onTap: () => ref
                  .read(themeModeControllerProvider.notifier)
                  .setThemeMode(ThemeMode.system),
            ),
            const SizedBox(height: 10),
            _ModeOption(
              icon: Icons.light_mode_outlined,
              title: 'Claro',
              selected: mode == ThemeMode.light,
              onTap: () => ref
                  .read(themeModeControllerProvider.notifier)
                  .setThemeMode(ThemeMode.light),
            ),
            const SizedBox(height: 10),
            _ModeOption(
              icon: Icons.dark_mode_outlined,
              title: 'Escuro',
              selected: mode == ThemeMode.dark,
              onTap: () => ref
                  .read(themeModeControllerProvider.notifier)
                  .setThemeMode(ThemeMode.dark),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: selected
            ? Icon(
                Icons.check_circle_rounded,
                color: Theme.of(context).colorScheme.primary,
              )
            : null,
      ),
    ),
  );
}
