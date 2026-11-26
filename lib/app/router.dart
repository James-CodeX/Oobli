import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/activity/activity_screen.dart';
import '../features/analytics/analytics_screen.dart';
import '../features/auth/auth_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/goals/goals_screen.dart';
import '../features/home/home_shell.dart';
import '../features/onboarding/gamified_setup_screen.dart';
import '../features/onboarding/meet_oobli_screen.dart';
import '../features/onboarding/sms_permission_screen.dart';
import '../features/onboarding/splash_screen.dart';
import '../features/plans/plans_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/transactions/quick_sort_screen.dart';
import '../features/wrapped/wrapped_screen.dart';
import '../state/auth_controller.dart';
import '../state/preferences.dart';

abstract final class Routes {
  static const splash = '/';
  static const welcome = '/welcome';
  static const auth = '/auth';
  static const smsPermission = '/onboarding/sms';
  static const setup = '/onboarding/setup';
  static const feed = '/home/feed';
  static const plans = '/home/plans';
  static const goals = '/home/goals';
  static const wrapped = '/home/wrapped';
  static const activity = '/activity';
  static const analytics = '/analytics';
  static const settings = '/settings';
  static const quickSort = '/sort';

  static String authWith({required bool login}) => '$auth?mode=${login ? 'login' : 'register'}';
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.listen(onboardingReplayProvider.select((r) => r.active), (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;

      // Still resolving the session (or failed to): the splash handles both.
      if (!auth.hasValue) return loc == Routes.splash ? null : Routes.splash;

      final user = auth.value;
      final isPublic = loc == Routes.welcome || loc == Routes.auth;
      if (user == null) return isPublic ? null : Routes.welcome;
      if (!user.onboardingComplete) return loc.startsWith('/onboarding') ? null : Routes.smsPermission;
      // Replaying from Settings: intro carousel, then the onboarding steps.
      if (ref.read(onboardingReplayProvider).active) {
        return loc == Routes.welcome || loc.startsWith('/onboarding') ? null : Routes.welcome;
      }
      if (loc == Routes.splash || isPublic) return Routes.feed;
      return null;
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.welcome, pageBuilder: (_, s) => _fade(s, const MeetOobliScreen())),
      GoRoute(
        path: Routes.auth,
        pageBuilder: (_, s) => _slide(s, AuthScreen(startWithLogin: s.uri.queryParameters['mode'] == 'login')),
      ),
      GoRoute(path: Routes.smsPermission, pageBuilder: (_, s) => _fade(s, const SmsPermissionScreen())),
      GoRoute(path: Routes.setup, pageBuilder: (_, s) => _slide(s, const GamifiedSetupScreen())),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: Routes.feed, builder: (_, _) => const DashboardScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.plans, builder: (_, _) => const PlansScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.goals, builder: (_, _) => const GoalsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.wrapped, builder: (_, _) => const WrappedScreen())]),
        ],
      ),
      GoRoute(
        path: Routes.activity,
        pageBuilder: (_, s) => _slide(s, ActivityScreen(initialQuery: s.uri.queryParameters['q'])),
      ),
      GoRoute(path: Routes.analytics, pageBuilder: (_, s) => _slide(s, const AnalyticsScreen())),
      GoRoute(
        path: Routes.quickSort,
        pageBuilder: (_, s) => _slide(s, QuickSortScreen(focusId: s.uri.queryParameters['focus'])),
      ),
      GoRoute(path: Routes.settings, pageBuilder: (_, s) => _slide(s, const SettingsScreen())),
    ],
  );
});

CustomTransitionPage<void> _fade(GoRouterState state, Widget child) => CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
    );

CustomTransitionPage<void> _slide(GoRouterState state, Widget child) => CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(begin: const Offset(0.08, 0), end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
    );
