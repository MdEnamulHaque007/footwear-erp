/// ============================================================================
/// ফাইল: lib/presentation/routes/app_routes.dart
/// স্তর: Navigation | মডিউল: Application Routing
/// উদ্দেশ্য: Route path, navigation shell, redirect এবং authorization guard পরিচালনা করে।
/// প্রধান অংশ: AppRoutes, GoRouterRefreshStream
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
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
import '../screens/auth/admin_bootstrap_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/dashboard/timelapse_dashboard_screen.dart';
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
import '../screens/sewing/sewing_detail_screen.dart';
import '../screens/production/production_list_screen.dart';
import '../screens/production/production_form_screen.dart';
import '../screens/production/production_detail_screen.dart';
import '../screens/issue/issue_list_screen.dart';
import '../screens/issue/issue_form_screen.dart';
import '../screens/issue/issue_detail_screen.dart';
import '../screens/export/export_list_screen.dart';
import '../screens/export/export_form_screen.dart';
import '../screens/export/export_detail_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/reports/production_report_screen.dart';
import '../screens/reports/finished_goods_report_screen.dart';
import '../screens/reports/warehouse_report_screen.dart';
import '../screens/audit/audit_log_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/appearance_screen.dart';
import '../screens/settings/notifications_screen.dart';
import '../screens/settings/business_settings_screen.dart';
import '../screens/settings/factory_list_screen.dart';
import '../screens/settings/project_list_screen.dart';
import '../screens/settings/brand_list_screen.dart';
import '../screens/settings/article_list_screen.dart';
import '../screens/settings/color_list_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/demo_data_screen.dart';
import '../screens/user_management/user_list_screen.dart';
import '../screens/user_management/user_form_screen.dart';
import '../screens/user_management/user_detail_screen.dart';
import '../../domain/entities/user_entity.dart';
import '../screens/role_management/role_list_screen.dart';
import '../screens/role_management/role_create_screen.dart';
import '../screens/role_management/permission_matrix_screen.dart';
import '../blocs/user_management/user_management_bloc.dart';
import '../blocs/user_management/user_management_event.dart';
import '../blocs/role_management/role_management_bloc.dart';
import '../blocs/role_management/role_management_event.dart';
import '../blocs/master_lc/master_lc_bloc.dart';
import '../blocs/timelapse/timelapse_bloc.dart';
import '../blocs/purchase_order/po_bloc.dart';
import '../blocs/cutting/cutting_bloc.dart';
import '../blocs/sewing/sewing_bloc.dart';
import '../blocs/production/production_bloc.dart';
import '../blocs/issue/issue_bloc.dart';
import '../../domain/entities/po_entity.dart';
import '../../domain/entities/cutting_entity.dart';
import '../../domain/entities/sewing_entity.dart';
import '../../domain/entities/production_entity.dart';
import '../../domain/entities/issue_entity.dart';
import '../../domain/entities/export_entity.dart';
import '../blocs/export/export_bloc.dart';
import '../blocs/reports/production_report_bloc.dart';
import '../blocs/reports/finished_goods_report_bloc.dart';
import '../blocs/reports/warehouse_report_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/settings/settings_bloc.dart';
import '../blocs/profile/profile_bloc.dart';
import '../blocs/security/security_bloc.dart';
import '../screens/settings/security_settings_screen.dart';
import '../screens/settings/data_management_screen.dart';
import '../screens/settings/about_screen.dart';
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
        builder: (_, state, child) => HomeNavigationShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: RouteConstants.dashboard, builder: (_, _) => const DashboardScreen()),
          GoRoute(path: RouteConstants.timelapseDashboard, name: 'timelapse-dashboard', builder: (_, _) => BlocProvider(create: (_) => GetIt.I<TimelapseBloc>(), child: const TimelapseDashboardScreen())),
          GoRoute(path: RouteConstants.login, builder: (_, _) => const LoginScreen()),
          GoRoute(path: RouteConstants.register, builder: (_, _) => const RegisterScreen()),
          GoRoute(path: RouteConstants.resetPassword, builder: (_, _) => const ResetPasswordScreen()),
          GoRoute(path: RouteConstants.adminBootstrap, builder: (_, _) => const AdminBootstrapScreen()),
          GoRoute(path: '/master-lc', builder: (_, _) => BlocProvider(create: (_) => GetIt.I<MasterLCBloc>(), child: const MasterLCListScreen())),
          GoRoute(path: '/purchase-orders', builder: (_, _) => BlocProvider(create: (_) => GetIt.I<POBloc>(), child: const POListScreen())),
          GoRoute(path: '/master-lc/new', builder: (_, _) => BlocProvider(create: (_) => GetIt.I<MasterLCBloc>(), child: const MasterLCFormScreen())),
          GoRoute(path: '/master-lc/edit/:id', builder: (_, state) => BlocProvider(create: (_) => GetIt.I<MasterLCBloc>(), child: MasterLCFormScreen(id: state.pathParameters['id'], entity: state.extra as MasterLCEntity?))),
          GoRoute(path: '/master-lc/detail/:id', builder: (_, state) => MultiBlocProvider(providers: [BlocProvider(create: (_) => GetIt.I<MasterLCBloc>()), BlocProvider(create: (_) => GetIt.I<POBloc>())], child: MasterLCDetailScreen(id: state.pathParameters['id']!, initialItem: state.extra as MasterLCEntity?))),
          GoRoute(path: '/master-lc/:tag', redirect: (_, state) => '/master-lc/detail/${state.pathParameters['tag']}'),
          GoRoute(path: '/purchase-orders/new', builder: (_, state) => MultiBlocProvider(providers: [BlocProvider(create: (_) => GetIt.I<POBloc>()), BlocProvider(create: (_) => GetIt.I<MasterLCBloc>())], child: POFormScreen(initialTagNo: state.uri.queryParameters['tag']))),
          GoRoute(path: '/purchase-orders/edit/:id', builder: (_, state) => MultiBlocProvider(providers: [BlocProvider(create: (_) => GetIt.I<POBloc>()), BlocProvider(create: (_) => GetIt.I<MasterLCBloc>())], child: POFormScreen(initialItem: state.extra as POEntity?))),
          GoRoute(path: '/purchase-orders/detail/:id', builder: (_, state) => BlocProvider(create: (_) => GetIt.I<POBloc>(), child: PODetailScreen(id: state.pathParameters['id']!, initialItem: state.extra as POEntity?))),
          GoRoute(path: '/cutting', builder: (_, _) => BlocProvider(create: (_) => GetIt.I<CuttingBloc>(), child: const CuttingListScreen())),
          GoRoute(path: '/cutting/new', builder: (_, _) => BlocProvider(create: (_) => GetIt.I<CuttingBloc>(), child: const CuttingFormScreen())),
          GoRoute(path: '/cutting/edit/:id', builder: (_, state) => BlocProvider(create: (_) => GetIt.I<CuttingBloc>(), child: CuttingFormScreen(initialItem: state.extra as CuttingEntity?))),
          GoRoute(path: '/cutting/detail/:id', builder: (_, state) => CuttingDetailScreen(id: state.pathParameters['id']!, initialItem: state.extra as CuttingEntity?)),
          GoRoute(path: '/sewing', builder: (_, _) => BlocProvider(create: (_) => GetIt.I<SewingBloc>(), child: const SewingListScreen())),
          GoRoute(path: '/sewing/new', builder: (_, _) => BlocProvider(create: (_) => GetIt.I<SewingBloc>(), child: const SewingFormScreen())),
          GoRoute(path: '/sewing/edit/:id', builder: (_, state) => BlocProvider(create: (_) => GetIt.I<SewingBloc>(), child: SewingFormScreen(initialItem: state.extra as SewingEntity?))),
          GoRoute(path: '/sewing/detail/:id', builder: (_, state) => SewingDetailScreen(id: state.pathParameters['id']!, initialItem: state.extra as SewingEntity?)),
          GoRoute(path: '/production', builder: (_, _) => BlocProvider(create: (_) => GetIt.I<ProductionBloc>(), child: const ProductionListScreen())),
          GoRoute(path: '/production/new', builder: (_, _) => BlocProvider(create: (_) => GetIt.I<ProductionBloc>(), child: const ProductionFormScreen())),
          GoRoute(path: '/production/edit/:id', builder: (_, state) => BlocProvider(create: (_) => GetIt.I<ProductionBloc>(), child: ProductionFormScreen(initialItem: state.extra as ProductionEntity?))),
          GoRoute(path: '/production/detail/:id', builder: (_, state) => ProductionDetailScreen(id: state.pathParameters['id']!, initialItem: state.extra as ProductionEntity?)),
          GoRoute(path: '/issue', builder: (_, _) => BlocProvider(create: (_) => GetIt.I<IssueBloc>(), child: const IssueListScreen())),
          GoRoute(path: '/issue/new', builder: (_, _) => BlocProvider(create: (_) => GetIt.I<IssueBloc>(), child: const IssueFormScreen())),
          GoRoute(path: '/issue/edit/:id', builder: (_, state) => BlocProvider(create: (_) => GetIt.I<IssueBloc>(), child: IssueFormScreen(initialItem: state.extra as IssueEntity?))),
          GoRoute(path: '/issue/detail/:id', builder: (_, state) => IssueDetailScreen(id: state.pathParameters['id']!, initialItem: state.extra as IssueEntity?)),
          GoRoute(path: RouteConstants.export, builder: (_, _) => BlocProvider(create: (_) => GetIt.I<ExportBloc>(), child: const ExportListScreen())),
          GoRoute(path: '/export/new', builder: (_, _) => BlocProvider(create: (_) => GetIt.I<ExportBloc>(), child: const ExportFormScreen())),
          GoRoute(path: '/export/edit/:id', builder: (_, state) => BlocProvider(create: (_) => GetIt.I<ExportBloc>(), child: ExportFormScreen(initialItem: state.extra as ExportEntity?))),
          GoRoute(path: '/export/detail/:id', builder: (_, state) => ExportDetailScreen(id: state.pathParameters['id']!, initialItem: state.extra as ExportEntity?)),
          GoRoute(path: RouteConstants.reports, builder: (_, _) => const ReportsScreen()),
          GoRoute(path: RouteConstants.productionReport, builder: (_, _) => BlocProvider(create: (_) => GetIt.I<ProductionReportBloc>(), child: const ProductionReportScreen())),
          GoRoute(path: RouteConstants.finishedGoodsReport, builder: (_, _) => BlocProvider(create: (_) => GetIt.I<FinishedGoodsReportBloc>(), child: const FinishedGoodsReportScreen())),
          GoRoute(path: RouteConstants.warehouseReport, name: 'warehouse-report', builder: (_, _) => BlocProvider(create: (_) => GetIt.I<WarehouseReportBloc>(), child: const WarehouseReportScreen())),
          GoRoute(path: RouteConstants.auditLog, builder: (_, _) => const AuditLogScreen()),
          GoRoute(path: RouteConstants.settings, builder: (_, _) => BlocProvider.value(value: GetIt.I<SettingsBloc>(), child: const SettingsScreen())),
          GoRoute(path: '/settings/appearance', builder: (_, _) => BlocProvider.value(value: GetIt.I<SettingsBloc>(), child: const AppearanceScreen())),
          GoRoute(path: '/settings/notifications', builder: (_, _) => BlocProvider.value(value: GetIt.I<SettingsBloc>(), child: const NotificationsScreen())),
          GoRoute(path: '/settings/business', builder: (_, _) => BlocProvider.value(value: GetIt.I<SettingsBloc>(), child: const BusinessSettingsScreen())),
          GoRoute(path: '/settings/factory', builder: (_, _) => BlocProvider.value(value: GetIt.I<SettingsBloc>(), child: const FactoryListScreen())),
          GoRoute(path: '/settings/project', builder: (_, _) => BlocProvider.value(value: GetIt.I<SettingsBloc>(), child: const ProjectListScreen())),
          GoRoute(path: '/settings/brand', builder: (_, _) => BlocProvider.value(value: GetIt.I<SettingsBloc>(), child: const BrandListScreen())),
          GoRoute(path: '/settings/article', builder: (_, _) => BlocProvider.value(value: GetIt.I<SettingsBloc>(), child: const ArticleListScreen())),
          GoRoute(path: '/settings/color', builder: (_, _) => BlocProvider.value(value: GetIt.I<SettingsBloc>(), child: const ColorListScreen())),
          GoRoute(path: '/settings/security', builder: (_, _) => BlocProvider(create: (_) => GetIt.I<SecurityBloc>(), child: const SecuritySettingsScreen())),
          GoRoute(path: '/settings/data', builder: (_, _) => BlocProvider.value(value: GetIt.I<SettingsBloc>(), child: const DataManagementScreen())),
          GoRoute(path: '/settings/about', builder: (_, _) => const AboutScreen()),
          GoRoute(path: RouteConstants.profile, builder: (_, _) => BlocProvider(create: (_) => GetIt.I<ProfileBloc>(), child: const ProfileScreen())),
          GoRoute(path: '/settings/profile', builder: (_, _) => BlocProvider(create: (_) => GetIt.I<ProfileBloc>(), child: const ProfileScreen())),
          GoRoute(path: '/unauthorized', builder: (_, _) => const UnauthorizedScreen()),
          GoRoute(path: RouteConstants.admin, builder: (_, _) => const AdminDashboardScreen()),
          GoRoute(path: RouteConstants.adminDemoData, builder: (_, _) => const DemoDataScreen()),
          GoRoute(path: RouteConstants.adminUsers, builder: (_, _) => BlocProvider(create: (_) => GetIt.I<UserManagementBloc>()..add(LoadUsers()), child: const UserListScreen())),
          GoRoute(path: RouteConstants.adminUsersNew, builder: (_, _) => BlocProvider(create: (_) => GetIt.I<UserManagementBloc>(), child: const UserFormScreen())),
          GoRoute(path: '${RouteConstants.adminUsersEdit}/:id', builder: (_, state) => BlocProvider(create: (_) => GetIt.I<UserManagementBloc>(), child: UserFormScreen(uid: state.pathParameters['id'], initialUser: state.extra as UserEntity?))),
          GoRoute(path: '${RouteConstants.adminUsersDetail}/:id', builder: (_, state) => BlocProvider(create: (_) => GetIt.I<UserManagementBloc>(), child: UserDetailScreen(uid: state.pathParameters['id'] ?? '', initialUser: state.extra as UserEntity?))),
          GoRoute(path: '/admin/roles', builder: (_, _) => BlocProvider(create: (_) => GetIt.I<RoleManagementBloc>()..add(LoadRoles()), child: const RoleListScreen())),
          GoRoute(path: '/admin/roles/create', builder: (_, _) => BlocProvider.value(value: GetIt.I<RoleManagementBloc>(), child: const RoleCreateScreen())),
          GoRoute(path: '/admin/permissions', builder: (_, _) => const PermissionMatrixScreen()),
        ],
      ),
    ],
    errorBuilder: (_, state) => HomeNavigationShell(location: state.uri.path, child: const Scaffold(body: Center(child: Text('Page not found. Use Home to return.')))),
  );
}

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
