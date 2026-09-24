import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeflow_app/core/navigation/app_tab.dart';
import 'package:lifeflow_app/core/navigation/quick_add_sheet.dart';
import 'package:lifeflow_app/core/theme/app_palette.dart';

/// Navegação inferior de 5 posições (Início, Finanças, + , Veículos, Mais),
/// compartilhada pelas telas de topo. A troca de aba usa `go` (substitui a
/// rota atual) — as navegações internas de cada aba continuam usando `push`.
class AppBottomNav extends ConsumerWidget {
  const AppBottomNav({
    required this.currentTab,
    this.preferredVehicleId,
    super.key,
  });

  final AppTab currentTab;
  final String? preferredVehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NavigationBar(
      selectedIndex: _indexFor(currentTab),
      onDestinationSelected: (index) => _onSelected(context, ref, index),
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Início',
        ),
        const NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet_rounded),
          label: 'Finanças',
        ),
        NavigationDestination(
          icon: Container(
            width: 42,
            height: 34,
            decoration: BoxDecoration(
              color: context.colors.primary,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.add_rounded, color: context.colors.background),
          ),
          label: 'Novo',
        ),
        const NavigationDestination(
          icon: Icon(Icons.directions_car_outlined),
          selectedIcon: Icon(Icons.directions_car_filled_rounded),
          label: 'Veículos',
        ),
        const NavigationDestination(
          icon: Icon(Icons.menu_rounded),
          label: 'Mais',
        ),
      ],
    );
  }

  int _indexFor(AppTab tab) => switch (tab) {
    AppTab.home => 0,
    AppTab.finance => 1,
    AppTab.vehicles => 3,
    AppTab.more => 4,
  };

  void _onSelected(BuildContext context, WidgetRef ref, int index) {
    switch (index) {
      case 0:
        if (currentTab != AppTab.home) context.go('/');
        return;
      case 1:
        if (currentTab != AppTab.finance) context.go('/finance');
        return;
      case 2:
        showQuickAddSheet(
          context,
          ref,
          preferredVehicleId: preferredVehicleId,
        );
        return;
      case 3:
        if (currentTab != AppTab.vehicles) context.go('/vehicles');
        return;
      case 4:
        if (currentTab != AppTab.more) context.go('/more');
        return;
    }
  }
}
