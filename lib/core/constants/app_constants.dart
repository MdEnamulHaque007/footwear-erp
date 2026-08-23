class AppConstants {
  static const appName = 'Footwear ERP System';
  static const appVersion = '1.0.0';

  static const collectionMasterLC = 'master_lc';
  static const collectionPO = 'purchase_orders';
  static const collectionCutting = 'cuttings';
  static const collectionSewing = 'sewings';
  static const collectionProduction = 'productions';
  static const collectionIssue = 'issues';
  static const collectionExport = 'exports';
  static const collectionAuditLog = 'audit_logs';
  static const collectionUsers = 'users';
  static const collectionRoles = 'roles';
  static const authSplash = '/';
  static const authLogin = '/login';
  static const authRegister = '/register';
  static const authResetPassword = '/reset-password';
  static const dashboardRoute = '/dashboard';
  static const roleAdmin = 'admin';
  static const roleEditor = 'editor';
  static const roleViewer = 'viewer';
  static const permissionView = 'view';
  static const permissionCreate = 'create';
  static const permissionEdit = 'edit';
  static const permissionDelete = 'delete';
  static const moduleMasterLC = 'master_lc';
  static const modulePurchaseOrder = 'purchase_order';
  static const moduleCutting = 'cutting';
  static const moduleSewing = 'sewing';
  static const moduleProduction = 'production';
  static const moduleIssue = 'issue';
  static const moduleExport = 'export';
  static const moduleUserManagement = 'user_management';
  static const moduleRoleManagement = 'role_management';
  static const moduleAuditLog = 'audit_log';
  static const moduleReports = 'reports';

  static const permissionModules = [
    moduleMasterLC,
    modulePurchaseOrder,
    moduleCutting,
    moduleSewing,
    moduleProduction,
    moduleIssue,
    moduleExport,
    moduleUserManagement,
    moduleRoleManagement,
    moduleAuditLog,
    moduleReports,
  ];
  static const permissionActions = [
    permissionView,
    permissionCreate,
    permissionEdit,
    permissionDelete,
  ];

  static const cuttingVoucherPrefix = 'CUT';
  static const sewingVoucherPrefix = 'SEW';
  static const productionVoucherPrefix = 'PRO';
  static const issueVoucherPrefix = 'ISS';
  static const exportVoucherPrefix = 'EXP';
}
