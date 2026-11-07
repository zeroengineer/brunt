import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/accounts/account_detail_screen.dart';
import '../features/accounts/accounts_screen.dart';
import '../features/daily_log/daily_log_screen.dart';
import '../features/gallery/gallery_screen.dart';
import '../features/history/history_screen.dart';
import '../features/home/home_screen.dart';
import '../features/insights/insights_screen.dart';
import '../features/lock/lock_screen.dart';
import '../features/lock/splash_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/plan/plan_screen.dart';
import '../features/plan/templates_screen.dart';
import '../features/settings/categories_screen.dart';
import '../features/settings/settings_screen.dart';
import '../security/lock_controller.dart';
import 'shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(lockProvider.select((s) => (s.phase, s.onboarded)), (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final lock = ref.read(lockProvider);
      final loc = state.matchedLocation;
      if (loc == '/gallery' && kDebugMode) return null;
      switch (lock.phase) {
        case LockPhase.booting:
          return loc == '/splash' ? null : '/splash';
        case LockPhase.needsSetup:
          return loc == '/onboarding' ? null : '/onboarding';
        case LockPhase.locked:
          return loc == '/lock' ? null : '/lock';
        case LockPhase.unlocked:
          if (!lock.onboarded) return loc == '/onboarding' ? null : '/onboarding';
          if (loc == '/lock' || loc == '/onboarding' || loc == '/splash') return '/home';
          return null;
      }
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/lock', builder: (_, _) => const LockScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/gallery', builder: (_, _) => const GalleryScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, _) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/log', builder: (_, _) => const DailyLogScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/plan', builder: (_, _) => const PlanScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/accounts', builder: (_, _) => const AccountsScreen())]),
        ],
      ),
      GoRoute(
        path: '/account/:id',
        builder: (_, s) => AccountDetailScreen(accountId: int.parse(s.pathParameters['id']!)),
      ),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(path: '/templates', builder: (_, _) => const TemplatesScreen()),
      GoRoute(path: '/categories', builder: (_, _) => const CategoriesScreen()),
      GoRoute(path: '/history', builder: (_, _) => const HistoryScreen(standalone: true)),
      GoRoute(path: '/insights', builder: (_, _) => const InsightsScreen(standalone: true)),
    ],
  );
});
