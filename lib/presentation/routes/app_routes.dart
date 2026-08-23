import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/auth/unauthorized_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/master_lc/master_lc_list_screen.dart';
import '../screens/purchase_order/po_list_screen.dart';
import '../screens/master_lc/master_lc_form_screen.dart';
import '../screens/master_lc/master_lc_detail_screen.dart';
import '../screens/purchase_order/po_form_screen.dart';
import '../screens/cutting/cutting_list_screen.dart';
import '../screens/cutting/cutting_form_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/user_management/user_list_screen.dart';
import '../screens/role_management/role_list_screen.dart';
import '../screens/role_management/role_create_screen.dart';
import '../screens/role_management/permission_matrix_screen.dart';
import '../blocs/user_management/user_management_bloc.dart';
import '../blocs/user_management/user_management_event.dart';
import '../blocs/role_management/role_management_bloc.dart';
import '../blocs/role_management/role_management_event.dart';
import '../blocs/master_lc/master_lc_bloc.dart';
import '../blocs/purchase_order/po_bloc.dart';
import '../blocs/cutting/cutting_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import 'route_constants.dart';
import 'route_guard.dart';

class AppRoutes {
  static final router = GoRouter(
    initialLocation: RouteConstants.dashboard,
    refreshListenable: GoRouterRefreshStream(GetIt.I<AuthBloc>().stream),
    redirect: (context, state) => RouteGuard.redirect(state),
    routes: [
      GoRoute(
        path: RouteConstants.dashboard,
        builder: (_, _) => const DashboardScreen(),
      ),
      GoRoute(
        path: RouteConstants.login,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteConstants.register,
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: RouteConstants.resetPassword,
        builder: (_, _) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/master-lc',
        builder: (_, _) => BlocProvider(
          create: (_) => GetIt.I<MasterLCBloc>(),
          child: const MasterLCListScreen(),
        ),
      ),
      GoRoute(
        path: '/purchase-orders',
        builder: (_, _) => BlocProvider(
          create: (_) => GetIt.I<POBloc>(),
          child: const POListScreen(),
        ),
      ),
      GoRoute(
        path: '/master-lc/new',
        builder: (_, _) => BlocProvider(
          create: (_) => GetIt.I<MasterLCBloc>(),
          child: const MasterLCFormScreen(),
        ),
      ),
      GoRoute(
        path: '/master-lc/:tag',
        builder: (_, state) =>
            MasterLCDetailScreen(tag: state.pathParameters['tag']!),
      ),
      GoRoute(
        path: '/purchase-orders/new',
        builder: (_, _) => BlocProvider(
          create: (_) => GetIt.I<POBloc>(),
          child: const POFormScreen(),
        ),
      ),
      GoRoute(
        path: '/cutting',
        builder: (_, _) => BlocProvider(
          create: (_) => GetIt.I<CuttingBloc>(),
          child: const CuttingListScreen(),
        ),
      ),
      GoRoute(
        path: '/cutting/new',
        builder: (_, _) => BlocProvider(
          create: (_) => GetIt.I<CuttingBloc>(),
          child: const CuttingFormScreen(),
        ),
      ),
      GoRoute(
        path: '/unauthorized',
        builder: (_, _) => const UnauthorizedScreen(),
      ),
      GoRoute(path: '/admin', builder: (_, _) => const AdminDashboardScreen()),
      GoRoute(
        path: '/admin/users',
        builder: (_, _) => BlocProvider(
          create: (_) => GetIt.I<UserManagementBloc>()..add(LoadUsers()),
          child: const UserListScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/roles',
        builder: (_, _) => BlocProvider(
          create: (_) => GetIt.I<RoleManagementBloc>()..add(LoadRoles()),
          child: const RoleListScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/roles/create',
        builder: (_, _) => BlocProvider.value(
          value: GetIt.I<RoleManagementBloc>(),
          child: const RoleCreateScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/permissions',
        builder: (_, _) => const PermissionMatrixScreen(),
      ),
    ],
    errorBuilder: (_, state) =>
        Scaffold(body: Center(child: Text(state.error.toString()))),
  );
}

/// Bridges the [AuthBloc] state stream to a [Listenable] so GoRouter
/// re-evaluates [RouteGuard.redirect] whenever authentication changes.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
