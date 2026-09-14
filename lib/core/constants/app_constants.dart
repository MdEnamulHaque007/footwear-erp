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

  /// Sequence documents backing the auto-generated Sl. fields (SRS Rule 1).
  static const collectionCounters = '_counters';
  static const authSplash = '/';
  static const authLogin = '/login';
  static const authRegister = '/register';
  static const authResetPassword = '/reset-password';
  static const dashboardRoute = '/dashboard';
  static const roleAdmin = 'admin';
  static const roleEditor = 'editor';
  static const roleViewer = 'viewer';

  /// Roles offered in the User Management role dropdown, in display order.
  static const assignableRoles = [roleAdmin, roleEditor, roleViewer];
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

  /// Predefined Project list for the Master LC form's dropdown.
  ///
  /// SRS requires Project/Company to be selected from predefined lists. These
  /// are the seed values; the dropdown also merges any Project already saved in
  /// the `master_lc` collection so the list grows with real data instead of
  /// requiring a code change (Option A + C hybrid).
  static const List<String> predefinedProjects = ['IALT', 'UPTOP'];

  /// Predefined Company list for the Master LC form's dropdown. Merged with the
  /// Companies already saved in the `master_lc` collection at runtime.
  static const List<String> predefinedCompanies = [
    'AERO CLUB',
    'AVISEN INT.Co.LTD.',
    'BEVAFORM SERVICE + HANDELS GES.M.B.H.',
    'BOSEN IMPORT & EXPORT CO. LIMITED',
    'BRIGHT HEART CORPORATION LIMITED',
    'GOLDEN UNION DIFFUSION SRL-VIA DEI',
    'HANG YUE TONG COMPANY LTD.',
    'INDO RUBBER & PLASTIC WORKS PVT.LTD',
    'IVY-ATLAS INTERNATIONAL LIMITED',
    'IVY-ATLAS INTERNATIONAL LTD.',
    'LEA INTERNATIONAL GROUP LTD.',
    'LIFESTYLE',
    'MIRZA INTERNATIONAL LIMITED',
    'NOVI FOOTWEAR LTD.',
    'REAYOU IND.HONGKONG LTD.',
    'REDTAPE LIMITED',
    'RICH-COOP CO.LTD.',
    'RTS FASHION FZE',
    'SKYLINE GROUP ASIA LIMITED',
    'TONSEN INTERNATIONAL CORPORATION LTD.',
    'Trent Ltd.',
    'UPTOP TRADING LTD.',
    'WIDEWAY DEVELOPMENT GROUP CO., LIMITED',
    'WOODLAND GCCFZCO',
    'XIAMEN UNIBEST IMPORT & EXPORT CO,.LTD.',
  ];
}
