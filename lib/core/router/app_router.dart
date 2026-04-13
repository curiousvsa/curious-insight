import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/onboarding/permission_screen.dart';
import '../../presentation/screens/main_shell.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/screens.dart';
import '../../presentation/screens/export/export_screen.dart';
import '../constants/app_strings.dart';

/// Route path constants
class AppRoutes {
  AppRoutes._();

  static const onboarding = '/onboarding';
  static const permissions = '/permissions';
  static const shell = '/';
  static const dashboard = '/dashboard';
  static const spending = '/spending';
  static const notifications = '/notifications';
  static const export = '/export';
  static const settings = '/settings';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.onboarding,
    debugLogDiagnostics: false,
    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding =
          prefs.getBool(AppConstants.kHasSeenOnboarding) ?? false;

      if (!hasSeenOnboarding &&
          state.matchedLocation != AppRoutes.onboarding &&
          state.matchedLocation != AppRoutes.permissions) {
        return AppRoutes.onboarding;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) => _fadeTransition(
          state: state,
          child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.permissions,
        pageBuilder: (context, state) => _slideTransition(
          state: state,
          child: const PermissionScreen(),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            pageBuilder: (context, state) => _noTransition(
              state: state,
              child: const DashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.spending,
            pageBuilder: (context, state) => _noTransition(
              state: state,
              child: const SpendingScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.notifications,
            pageBuilder: (context, state) => _noTransition(
              state: state,
              child: const NotificationsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.export,
            pageBuilder: (context, state) => _noTransition(
              state: state,
              child: const ExportScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (context, state) => _noTransition(
              state: state,
              child: const SettingsScreen(),
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});

CustomTransitionPage<void> _fadeTransition({
  required GoRouterState state,
  required Widget child,
}) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    );

CustomTransitionPage<void> _slideTransition({
  required GoRouterState state,
  required Widget child,
}) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
        )),
        child: child,
      ),
    );

NoTransitionPage<void> _noTransition({
  required GoRouterState state,
  required Widget child,
}) =>
    NoTransitionPage<void>(
      key: state.pageKey,
      child: child,
    );
