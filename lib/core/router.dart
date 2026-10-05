import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/approvals/approvals_screen.dart';
import '../screens/approvals/expense_detail_screen.dart';
import '../screens/attendance/attendance_screen.dart';
import '../screens/customers/customers_list_screen.dart';
import '../screens/employees/employees_list_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/shell/app_shell.dart';
import '../screens/splash_screen.dart';
import '../state/auth_providers.dart';

class Routes {
  static const splash = '/';
  static const login = '/login';
  static const forgotPassword = '/forgot-password';
  static const register = '/register';
  static const dashboard = '/dashboard';
  static const employees = '/employees';
  static const attendance = '/attendance';
  static const customers = '/customers';
  static const approvals = '/approvals';
  static const settings = '/settings';
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final loc = state.matchedLocation;

      if (auth.isLoading) return loc == Routes.splash ? null : Routes.splash;

      final loggedIn = auth.value != null;
      final onPublic = loc == Routes.login ||
          loc == Routes.forgotPassword ||
          loc == Routes.register;

      if (!loggedIn) return onPublic ? null : Routes.login;
      if (onPublic || loc == Routes.splash) return Routes.dashboard;
      return null;
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: Routes.register,
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: Routes.settings,
        builder: (_, _) => const SettingsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.dashboard,
              builder: (_, _) => const DashboardScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.employees,
              builder: (_, _) => const EmployeesListScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.attendance,
              builder: (_, _) => const AttendanceScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.customers,
              builder: (_, _) => const CustomersListScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.approvals,
              builder: (_, _) => const ApprovalsScreen(),
              routes: [
                GoRoute(
                  path: ':expenseId',
                  builder: (_, state) => ExpenseDetailScreen(
                    expenseId: state.pathParameters['expenseId']!,
                  ),
                ),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
});
