import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeflow_app/features/auth/domain/auth_repository.dart';
import 'package:lifeflow_app/features/auth/presentation/auth_controller.dart';
import 'package:lifeflow_app/features/auth/presentation/auth_splash_page.dart';
import 'package:lifeflow_app/features/auth/presentation/forgot_password_page.dart';
import 'package:lifeflow_app/features/auth/presentation/login_page.dart';
import 'package:lifeflow_app/features/auth/presentation/sign_up_page.dart';
import 'package:lifeflow_app/features/auth/presentation/update_password_page.dart';
import 'package:lifeflow_app/features/dashboard/presentation/home_page.dart';
import 'package:lifeflow_app/features/expenses/presentation/expense_form_page.dart';
import 'package:lifeflow_app/features/expenses/presentation/expenses_page.dart';
import 'package:lifeflow_app/features/finance/presentation/categories_page.dart';
import 'package:lifeflow_app/features/finance/presentation/category_form_page.dart';
import 'package:lifeflow_app/features/finance/presentation/finance_page.dart';
import 'package:lifeflow_app/features/finance/presentation/people_page.dart';
import 'package:lifeflow_app/features/finance/presentation/person_form_page.dart';
import 'package:lifeflow_app/features/finance/presentation/recurring_transaction_form_page.dart';
import 'package:lifeflow_app/features/finance/presentation/recurring_transactions_page.dart';
import 'package:lifeflow_app/features/finance/presentation/savings_goal_details_page.dart';
import 'package:lifeflow_app/features/finance/presentation/savings_goal_form_page.dart';
import 'package:lifeflow_app/features/finance/presentation/savings_goals_page.dart';
import 'package:lifeflow_app/features/finance/presentation/transaction_form_page.dart';
import 'package:lifeflow_app/features/history/presentation/timeline_page.dart';
import 'package:lifeflow_app/features/maintenance/presentation/maintenance_details_page.dart';
import 'package:lifeflow_app/features/maintenance/presentation/maintenance_form_page.dart';
import 'package:lifeflow_app/features/maintenance/presentation/maintenances_page.dart';
import 'package:lifeflow_app/features/more/presentation/appearance_page.dart';
import 'package:lifeflow_app/features/more/presentation/more_page.dart';
import 'package:lifeflow_app/features/more/presentation/sync_page.dart';
import 'package:lifeflow_app/features/notifications/presentation/notifications_page.dart';
import 'package:lifeflow_app/features/refueling/domain/refueling.dart';
import 'package:lifeflow_app/features/refueling/presentation/refueling_form_page.dart';
import 'package:lifeflow_app/features/refueling/presentation/refuelings_page.dart';
import 'package:lifeflow_app/features/reminders/presentation/reminder_form_page.dart';
import 'package:lifeflow_app/features/reminders/presentation/reminders_page.dart';
import 'package:lifeflow_app/features/vehicles/presentation/vehicle_details_page.dart';
import 'package:lifeflow_app/features/vehicles/presentation/vehicle_form_page.dart';
import 'package:lifeflow_app/features/vehicles/presentation/vehicles_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authSessionProvider);
  final router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final location = state.matchedLocation;
      const publicLocations = {'/login', '/sign-up', '/forgot-password'};

      if (authState.isLoading) {
        return location == '/splash' ? null : '/splash';
      }

      final session = authState.value;
      if (authState.hasError || session == null || !session.isAuthenticated) {
        return publicLocations.contains(location) ? null : '/login';
      }

      if (session.status == AuthSessionStatus.passwordRecovery) {
        return location == '/update-password' ? null : '/update-password';
      }

      if (publicLocations.contains(location) ||
          location == '/splash' ||
          location == '/update-password') {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const AuthSplashPage(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/sign-up',
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/update-password',
        builder: (context, state) => const UpdatePasswordPage(),
      ),
      GoRoute(path: '/', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/finance',
        builder: (context, state) => const FinancePage(),
        routes: [
          GoRoute(
            path: 'transactions/new',
            builder: (context, state) => const TransactionFormPage(),
          ),
          GoRoute(
            path: 'transactions/:transactionId/edit',
            builder: (context, state) => TransactionEditRoutePage(
              transactionId: state.pathParameters['transactionId']!,
            ),
          ),
          GoRoute(
            path: 'goals',
            builder: (context, state) => const SavingsGoalsPage(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const SavingsGoalFormPage(),
              ),
              GoRoute(
                path: ':goalId',
                builder: (context, state) => SavingsGoalDetailsPage(
                  goalId: state.pathParameters['goalId']!,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => SavingsGoalEditRoutePage(
                      goalId: state.pathParameters['goalId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/more',
        builder: (context, state) => const MorePage(),
        routes: [
          GoRoute(
            path: 'appearance',
            builder: (context, state) => const AppearancePage(),
          ),
          GoRoute(path: 'sync', builder: (context, state) => const SyncPage()),
          GoRoute(
            path: 'categories',
            builder: (context, state) => const CategoriesPage(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const CategoryFormPage(),
              ),
              GoRoute(
                path: ':categoryId/edit',
                builder: (context, state) => CategoryEditRoutePage(
                  categoryId: state.pathParameters['categoryId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'people',
            builder: (context, state) => const PeoplePage(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const PersonFormPage(),
              ),
              GoRoute(
                path: ':personId/edit',
                builder: (context, state) => PersonEditRoutePage(
                  personId: state.pathParameters['personId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'recurring',
            builder: (context, state) => const RecurringTransactionsPage(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const RecurringTransactionFormPage(),
              ),
              GoRoute(
                path: ':recurringId/edit',
                builder: (context, state) => RecurringTransactionEditRoutePage(
                  recurringId: state.pathParameters['recurringId']!,
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/vehicles',
        builder: (context, state) => const VehiclesPage(),
      ),
      GoRoute(
        path: '/vehicles/new',
        builder: (context, state) => const VehicleFormPage(),
      ),
      GoRoute(
        path: '/vehicles/:id',
        builder: (context, state) =>
            VehicleDetailsPage(vehicleId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'history',
            builder: (context, state) =>
                TimelinePage(vehicleId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'edit',
            builder: (context, state) =>
                VehicleEditRoutePage(vehicleId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'maintenances',
            builder: (context, state) =>
                MaintenancesPage(vehicleId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => MaintenanceCreateRoutePage(
                  vehicleId: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: ':maintenanceId',
                builder: (context, state) => MaintenanceDetailsPage(
                  vehicleId: state.pathParameters['id']!,
                  maintenanceId: state.pathParameters['maintenanceId']!,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => MaintenanceEditRoutePage(
                      vehicleId: state.pathParameters['id']!,
                      maintenanceId: state.pathParameters['maintenanceId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: 'refuelings',
            builder: (context, state) =>
                RefuelingsPage(vehicleId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => RefuelingCreateRoutePage(
                  vehicleId: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: ':refuelingId/edit',
                builder: (context, state) => RefuelingFormPage(
                  vehicleId: state.pathParameters['id']!,
                  initial: state.extra as Refueling?,
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'expenses',
            builder: (context, state) =>
                ExpensesPage(vehicleId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) =>
                    ExpenseFormPage(vehicleId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: ':expenseId/edit',
                builder: (context, state) => ExpenseEditRoutePage(
                  vehicleId: state.pathParameters['id']!,
                  expenseId: state.pathParameters['expenseId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'reminders',
            builder: (context, state) =>
                RemindersPage(vehicleId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) =>
                    ReminderFormPage(vehicleId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: ':reminderId/edit',
                builder: (context, state) => ReminderEditRoutePage(
                  vehicleId: state.pathParameters['id']!,
                  reminderId: state.pathParameters['reminderId']!,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
