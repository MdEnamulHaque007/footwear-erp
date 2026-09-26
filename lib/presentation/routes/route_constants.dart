/// ============================================================================
/// ফাইল: lib/presentation/routes/route_constants.dart
/// স্তর: Navigation | মডিউল: Application Routing
/// উদ্দেশ্য: Route path, navigation shell, redirect এবং authorization guard পরিচালনা করে।
/// প্রধান অংশ: RouteConstants
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
class RouteConstants {
  static const dashboard = '/';
  static const timelapseDashboard = '/dashboard/timelapse';
  static const login = '/login';
  static const register = '/register';
  static const resetPassword = '/reset-password';
  static const adminBootstrap = '/admin-bootstrap';
  static const export = '/export';
  static const reports = '/reports';
  static const productionReport = '/reports/production';
  static const finishedGoodsReport = '/reports/finished-goods';
  static const warehouseReport = '/reports/warehouse';
  static const auditLog = '/audit-log';
  static const settings = '/settings';
  static const profile = '/profile';
  static const admin = '/admin';
  static const adminDemoData = '/admin/demo-data';
  static const adminUsers = '/admin/users';
  static const adminUsersNew = '/admin/users/new';
  static const adminUsersEdit = '/admin/users/edit';
  static const adminUsersDetail = '/admin/users/detail';
  static const cutting = '/cutting';
  static const cuttingNew = '/cutting/new';
  static const cuttingEdit = '/cutting/edit/:id';
  static const cuttingDetail = '/cutting/detail/:id';
  static const sewing = '/sewing';
  static const sewingNew = '/sewing/new';
  static const sewingEdit = '/sewing/edit/:id';
  static const sewingDetail = '/sewing/detail/:id';
  static const production = '/production';
  static const productionNew = '/production/new';
  static const productionEdit = '/production/edit/:id';
  static const productionDetail = '/production/detail/:id';
  static const issue = '/issue';
  static const issueNew = '/issue/new';
  static const issueEdit = '/issue/edit/:id';
  static const issueDetail = '/issue/detail/:id';
  static const exportNew = '/export/new';
  static const exportEdit = '/export/edit/:id';
  static const exportDetail = '/export/detail/:id';
}
