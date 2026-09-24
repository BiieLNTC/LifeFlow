import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeflow_app/core/navigation/app_bottom_nav.dart';
import 'package:lifeflow_app/core/navigation/app_tab.dart';
import 'package:lifeflow_app/core/theme/app_palette.dart';
import 'package:lifeflow_app/features/auth/presentation/auth_controller.dart';
import 'package:lifeflow_app/features/notifications/presentation/notification_bell.dart';

class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).value;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MAIS',
          style: TextStyle(
            color: context.colors.primary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
          ),
        ),
        actions: const [NotificationBell()],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 104),
          children: [
            _ProfileHeader(name: session?.name, email: session?.email),
            const SizedBox(height: 28),
            _SectionLabel('FINANÇAS'),
            _MoreTile(
              icon: Icons.category_outlined,
              title: 'Categorias',
              onTap: () => context.push('/more/categories'),
            ),
            const SizedBox(height: 10),
            _MoreTile(
              icon: Icons.people_outline_rounded,
              title: 'Pessoas',
              onTap: () => context.push('/more/people'),
            ),
            const SizedBox(height: 10),
            _MoreTile(
              icon: Icons.autorenew_rounded,
              title: 'Transações recorrentes',
              onTap: () => context.push('/more/recurring'),
            ),
            const SizedBox(height: 10),
            _MoreTile(
              icon: Icons.savings_outlined,
              title: 'Metas de poupança',
              onTap: () => context.push('/finance/goals'),
            ),
            const SizedBox(height: 20),
            _SectionLabel('PREFERÊNCIAS'),
            _MoreTile(
              icon: Icons.palette_outlined,
              title: 'Aparência',
              onTap: () => context.push('/more/appearance'),
            ),
            const SizedBox(height: 10),
            _MoreTile(
              icon: Icons.sync_rounded,
              title: 'Sincronização',
              onTap: () => context.push('/more/sync'),
            ),
            const SizedBox(height: 10),
            _MoreTile(
              icon: Icons.ios_share_rounded,
              title: 'Exportar dados',
              subtitle: 'Em breve',
              enabled: false,
            ),
            const SizedBox(height: 20),
            _SectionLabel('CONTA'),
            _MoreTile(
              icon: Icons.logout_rounded,
              title: 'Sair',
              color: context.colors.critical,
              onTap: () => ref.read(authControllerProvider.notifier).signOut(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentTab: AppTab.more),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({this.name, this.email});
  final String? name, email;

  @override
  Widget build(BuildContext context) {
    final label = (name?.trim().isNotEmpty ?? false) ? name! : (email ?? '');
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: context.colors.primary.withValues(alpha: 0.15),
              child: Icon(Icons.person_rounded, color: context.colors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.isEmpty ? 'Seu perfil' : label,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (email != null && email != label) ...[
                    const SizedBox(height: 4),
                    Text(email!, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: context.colors.textSecondary,
        letterSpacing: 1.4,
      ),
    ),
  );
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.color,
    this.onTap,
    this.enabled = true,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? color;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: enabled ? 1 : 0.5,
    child: Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        enabled: enabled,
        leading: Icon(icon, color: color ?? context.colors.primary),
        title: Text(title, style: TextStyle(color: color)),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: enabled ? const Icon(Icons.chevron_right_rounded) : null,
        onTap: onTap,
      ),
    ),
  );
}
