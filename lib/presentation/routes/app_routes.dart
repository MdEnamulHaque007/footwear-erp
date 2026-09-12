import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../domain/entities/master_lc_entity.dart';

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
import '../screens/purchase_order/po_detail_screen.dart';
import '../screens/cutting/cutting_list_screen.dart';
import '../screens/cutting/cutting_form_screen.dart';
import '../screens/cutting/cutting_detail_screen.dart';
import '../screens/sewing/sewing_list_screen.dart';
import '../screens/sewing/sewing_form_screen.dart';
import '../screens/production/production_list_screen.dart';
import '../screens/production/production_form_screen.dart';
import '../screens/issue/issue_list_screen.dart';
import '../screens/issue/issue_form_screen.dart';
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
import '../blocs/sewing/sewing_bloc.dart';
import '../blocs/production/production_bloc.dart';
import '../blocs/issue/issue_bloc.dart';
import '../../domain/entities/po_entity.dart';
import '../../domain/entities/cutting_entity.dart';
import '../blocs/auth/auth_bloc.dart';
import 'route_constants.dart';
import 'route_guard.dart';
import 'home_navigation_shell.dart';

class AppRoutes {
  static final router = GoRouter(
    initialLocation: RouteConstants.dashboard,
    refreshListenable: GoRouterRefreshStream(GetIt.I<AuthBloc>().stream),
    redirect: (context, state) => RouteGuard.redirect(state),
    routes: [
      GoRoute(path: '/dashboard', redirect: (_, _) => RouteConstants.dashboard),
      ShellRoute(
        builder: (_, state, child) =>
            HomeNavigationShell(location: state.uri.path, child: child),
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
            path: '/master-lc/edit/:id',
            builder: (_, state) => BlocProvider(
              create: (_) => GetIt.I<MasterLCBloc>(),
              child: MasterLCFormScreen(
                id: state.pathParameters['id'],
                entity: state.extra as MasterLCEntity?,
              ),
            ),
          ),
          GoRoute(
            path: '/master-lc/detail/:id',
            builder: (_, state) => MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => GetIt.I<MasterLCBloc>()),
                BlocProvider(create: (_) => GetIt.I<POBloc>()),
              ],
              child: MasterLCDetailScreen(
                id: state.pathParameters['id']!,
                initialItem: state.extra as MasterLCEntity?,
              ),
            ),
          ),
          GoRoute(
            path: '/master-lc/:tag',
            redirect: (_, state) =>
                '/master-lc/detail/${state.pathParameters['tag']}',
          ),
          GoRoute(
            path: '/purchase-orders/new',
            builder: (_, state) => MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => GetIt.I<POBloc>()),
                BlocProvider(create: (_) => GetIt.I<MasterLCBloc>()),
              ],
              child: POFormScreen(
                initialTagNo: state.uri.queryParameters['tag'],
              ),
            ),
          ),
          GoRoute(
            path: '/purchase-orders/edit/:id',
            builder: (_, state) => MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => GetIt.I<POBloc>()),
                BlocProvider(create: (_) => GetIt.I<MasterLCBloc>()),
              ],
              child: POFormScreen(initialItem: state.extra as POEntity?),
            ),
          ),
          GoRoute(
            path: '/purchase-orders/detail/:id',
            builder: (_, state) => BlocProvider(
              create: (_) => GetIt.I<POBloc>(),
              child: PODetailScreen(
                id: state.pathParameters['id']!,
                initialItem: state.extra as POEntity?,
              ),
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
            path: '/cutting/edit/:id',
            builder: (_, state) => BlocProvider(
              create: (_) => GetIt.I<CuttingBloc>(),
              child: CuttingFormScreen(
                initialItem: state.extra as CuttingEntity?,
              ),
            ),
          ),
          GoRoute(
            path: '/cutting/detail/:id',
            builder: (_, state) => CuttingDetailScreen(
              id: state.pathParameters['id']!,
              initialItem: state.extra as CuttingEntity?,
            ),
          ),
          GoRoute(
            path: '/sewing',
            builder: (_, _) => BlocProvider(
              create: (_) => GetIt.I<SewingBloc>(),
              child: const SewingListScreen(),
            ),
          ),
          GoRoute(
            path: '/sewing/new',
            builder: (_, _) => BlocProvider(
              create: (_) => GetIt.I<SewingBloc>(),
              child: const SewingFormScreen(),
            ),
          ),
          GoRoute(
            path: '/production',
            builder: (_, _) => BlocProvider(
              create: (_) => GetIt.I<ProductionBloc>(),
              child: const ProductionListScreen(),
            ),
          ),
          GoRoute(
            path: '/production/new',
            builder: (_, _) => BlocProvider(
              create: (_) => GetIt.I<ProductionBloc>(),
              child: const ProductionFormScreen(),
            ),
          ),
          GoRoute(
            path: '/issue',
            builder: (_, _) => BlocProvider(
              create: (_) => GetIt.I<IssueBloc>(),
              child: const IssueListScreen(),
            ),
          ),
          GoRoute(
            path: '/issue/new',
            builder: (_, _) => BlocProvider(
              create: (_) => GetIt.I<IssueBloc>(),
              child: const IssueFormScreen(),
            ),
          ),
          GoRoute(
            path: '/unauthorized',
            builder: (_, _) => const UnauthorizedScreen(),
          ),
          GoRoute(
            path: '/admin',
            builder: (_, _) => const AdminDashboardScreen(),
          ),
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
      ),
    ],
    errorBuilder: (_, state) => HomeNavigationShell(
      location: state.uri.path,
      child: const Scaffold(
        body: Center(child: Text('Page not found. Use Home to return.')),
      ),
    ),
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
