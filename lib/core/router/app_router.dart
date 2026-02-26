import 'package:app_2/features/auth/presentation/pages/auth_entry_page.dart';
import 'package:app_2/features/account/presentation/pages/account_page.dart';
import 'package:app_2/features/finance/presentation/pages/calendar_overview_page.dart';
import 'package:app_2/features/finance/presentation/pages/financial_plan_page.dart';
import 'package:app_2/features/finance/presentation/pages/master_data_page.dart';
import 'package:app_2/features/finance/presentation/pages/stats_page.dart';
import 'package:app_2/features/finance/presentation/pages/transaction_list_page.dart';
import 'package:app_2/features/owner/presentation/pages/owner_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

class AppRouter {
  const AppRouter._();

  static final router = GoRouter(
    errorBuilder: (context, state) {
      final isAuthenticated =
          Hive.isBoxOpen('auth_box') &&
          (Hive.box<Map>('auth_box').get('session')?['isAuthenticated'] as bool? ??
              false);
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.map_outlined, size: 44),
                const SizedBox(height: 10),
                const Text('Halaman tidak ditemukan'),
                const SizedBox(height: 6),
                Text(state.uri.toString()),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => context.go(isAuthenticated ? '/home' : '/'),
                  child: Text(isAuthenticated ? 'Kembali ke Home' : 'Kembali ke Login'),
                ),
              ],
            ),
          ),
        ),
      );
    },
    redirect: (context, state) {
      final isOwnerRoute =
          defaultTargetPlatform == TargetPlatform.windows &&
          state.matchedLocation == '/owner';
      if (!Hive.isBoxOpen('auth_box')) {
        return state.matchedLocation == '/' || isOwnerRoute ? null : '/';
      }

      final raw = Hive.box<Map>('auth_box').get('session');
      final isAuthenticated = raw?['isAuthenticated'] as bool? ?? false;
      final isAuthRoute = state.matchedLocation == '/';

      if (!isAuthenticated && !isAuthRoute && !isOwnerRoute) {
        return '/';
      }
      if (isAuthenticated && isAuthRoute) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const AuthEntryPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const TransactionListPage(),
      ),
      GoRoute(
        path: '/account',
        builder: (context, state) => const AccountPage(),
      ),
      GoRoute(
        path: '/masters',
        builder: (context, state) => const MasterDataPage(),
      ),
      GoRoute(
        path: '/plans',
        builder: (context, state) => const FinancialPlanPage(),
      ),
      GoRoute(
        path: '/calendar',
        builder: (context, state) => const CalendarOverviewPage(),
      ),
      GoRoute(
        path: '/stats',
        builder: (context, state) => const StatsPage(),
      ),
      GoRoute(
        path: '/calendar-view',
        builder: (context, state) => const CalendarOverviewPage(),
      ),
      GoRoute(
        path: '/kalender',
        builder: (context, state) => const CalendarOverviewPage(),
      ),
      GoRoute(
        path: '/calender',
        builder: (context, state) => const CalendarOverviewPage(),
      ),
      if (defaultTargetPlatform == TargetPlatform.windows)
        GoRoute(
          path: '/owner',
          builder: (context, state) => const OwnerDashboardPage(),
        ),
      GoRoute(
        path: '/:rest(.*)',
        builder: (context, state) {
          final raw = Hive.isBoxOpen('auth_box')
              ? Hive.box<Map>('auth_box').get('session')
              : null;
          final isAuthenticated = raw?['isAuthenticated'] as bool? ?? false;
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.map_outlined, size: 44),
                    const SizedBox(height: 10),
                    const Text('Route tidak ditemukan'),
                    const SizedBox(height: 6),
                    Text(state.uri.toString()),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => context.go(isAuthenticated ? '/home' : '/'),
                      child: Text(
                        isAuthenticated ? 'Kembali ke Home' : 'Kembali ke Login',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ],
  );
}
