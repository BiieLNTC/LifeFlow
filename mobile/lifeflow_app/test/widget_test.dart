import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeflow_app/app.dart';
import 'package:lifeflow_app/core/sync/sync_models.dart';
import 'package:lifeflow_app/core/sync/sync_service.dart';
import 'package:lifeflow_app/core/theme/theme_mode_controller.dart';
import 'package:lifeflow_app/features/auth/data/supabase_auth_repository.dart';
import 'package:lifeflow_app/features/dashboard/data/supabase_dashboard_repository.dart';
import 'package:lifeflow_app/features/vehicles/data/supabase_vehicle_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_auth_repository.dart';
import 'support/fake_dashboard_repository.dart';
import 'support/fake_vehicle_repository.dart';

void main() {
  testWidgets('permite entrar e sair da sessão', (tester) async {
    final repository = FakeAuthRepository();
    addTearDown(repository.close);
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          syncRunnerProvider.overrideWithValue(
            ({bool retryFailed = false}) async {},
          ),
          syncSummaryProvider.overrideWith(
            (ref) => Stream.value(
              const SyncSummary(pending: 0, failed: 0),
            ),
          ),
          dashboardRepositoryProvider.overrideWithValue(
            FakeDashboardRepository(),
          ),
          vehicleRepositoryProvider.overrideWithValue(FakeVehicleRepository()),
          sharedPreferencesProvider.overrideWithValue(preferences),
        ],
        child: const LifeFlowApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ENTRAR'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'E-mail'),
      'motorista@motora.app',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Senha'),
      'Senha123',
    );
    await tester.tap(find.text('ENTRAR'));
    await tester.pumpAndSettle();

    expect(find.text('Sua garagem começa aqui.'), findsOneWidget);

    await tester.tap(find.text('Mais'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Sair'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();

    expect(find.text('ENTRAR'), findsOneWidget);
  });
}
