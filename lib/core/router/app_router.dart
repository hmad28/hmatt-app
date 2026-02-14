import 'package:app_2/features/auth/presentation/pages/auth_entry_page.dart';
import 'package:app_2/features/finance/presentation/pages/master_data_page.dart';
import 'package:app_2/features/finance/presentation/pages/transaction_list_page.dart';
import 'package:app_2/features/owner/presentation/pages/owner_dashboard_page.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

class AppRouter {
  const AppRouter._();

  static final router = GoRouter(
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
        path: '/masters',
        builder: (context, state) => const MasterDataPage(),
      ),
      if (defaultTargetPlatform == TargetPlatform.windows)
        GoRoute(
          path: '/owner',
          builder: (context, state) => const OwnerDashboardPage(),
        ),
    ],
  );
}
