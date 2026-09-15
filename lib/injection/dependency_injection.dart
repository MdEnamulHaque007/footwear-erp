import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/services/firebase/firebase_firestore_service.dart';
import '../data/datasources/remote/auth_remote_datasource.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/role_repository.dart';
import '../data/repositories/user_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../core/services/local/local_settings_service.dart';
import '../domain/repositories/i_auth_repository.dart';
import '../domain/repositories/i_role_repository.dart';
import '../domain/repositories/i_user_repository.dart';
import '../domain/repositories/i_settings_repository.dart';
import '../domain/usecases/user/check_auth_status_usecase.dart';
import '../domain/usecases/user/get_current_user_usecase.dart';
import '../domain/usecases/user/login_usecase.dart';
import '../domain/usecases/user/logout_usecase.dart';
import '../domain/usecases/user/register_usecase.dart';
import '../domain/usecases/user/reset_password_usecase.dart';
import '../domain/usecases/role/create_role_usecase.dart';
import '../domain/usecases/role/delete_role_usecase.dart';
import '../domain/usecases/role/update_role_permissions_usecase.dart';
import '../domain/usecases/role/get_all_roles_usecase.dart';
import '../data/repositories/master_lc_repository.dart';
import '../data/repositories/po_repository.dart';
import '../data/repositories/cutting_repository.dart';
import '../data/repositories/sewing_repository.dart';
import '../data/repositories/production_repository.dart';
import '../data/repositories/issue_repository.dart';
import '../domain/repositories/i_master_lc_repository.dart';
import '../domain/repositories/i_po_repository.dart';
import '../domain/repositories/i_cutting_repository.dart';
import '../domain/repositories/i_sewing_repository.dart';
import '../domain/repositories/i_production_repository.dart';
import '../domain/repositories/i_issue_repository.dart';
import '../domain/usecases/master_lc/create_master_lc_usecase.dart';
import '../domain/usecases/master_lc/get_master_lc_list_usecase.dart';
import '../domain/usecases/master_lc/update_master_lc_usecase.dart';
import '../domain/usecases/master_lc/delete_master_lc_usecase.dart';
import '../domain/usecases/master_lc/get_master_lc_by_tag_usecase.dart';
import '../domain/usecases/master_lc/get_master_lc_by_id_usecase.dart';
import '../domain/usecases/master_lc/get_project_list_usecase.dart';
import '../domain/usecases/master_lc/get_company_list_usecase.dart';
import '../domain/usecases/purchase_order/create_po_usecase.dart';
import '../domain/usecases/purchase_order/get_po_list_usecase.dart';
import '../domain/usecases/purchase_order/get_po_by_tag_usecase.dart';
import '../domain/usecases/purchase_order/get_po_by_id_usecase.dart';
import '../domain/usecases/purchase_order/update_po_usecase.dart';
import '../domain/usecases/purchase_order/delete_po_usecase.dart';
import '../domain/usecases/purchase_order/validate_po_quantity_usecase.dart';
import '../domain/usecases/user/delete_user_usecase.dart';
import '../domain/usecases/user/bootstrap_admin_profile_usecase.dart';
import '../domain/usecases/user/get_all_users_usecase.dart';
import '../domain/usecases/user/get_user_by_id_usecase.dart';
import '../domain/usecases/user/update_user_usecase.dart';
import '../domain/usecases/user/update_user_permissions_usecase.dart';
import '../domain/usecases/user/update_user_role_usecase.dart';
import '../domain/usecases/user/update_user_status_usecase.dart';
import '../domain/usecases/user/update_profile_usecase.dart';
import '../domain/usecases/settings/get_app_settings_usecase.dart';
import '../domain/usecases/settings/get_business_settings_usecase.dart';
import '../domain/usecases/settings/save_app_settings_usecase.dart';
import '../domain/usecases/settings/save_business_settings_usecase.dart';
import '../presentation/blocs/profile/profile_bloc.dart';
import '../presentation/blocs/security/security_bloc.dart';
import '../domain/usecases/cutting/create_cutting_usecase.dart';
import '../domain/usecases/cutting/get_cutting_list_usecase.dart';
import '../domain/usecases/cutting/update_cutting_usecase.dart';
import '../domain/usecases/cutting/delete_cutting_usecase.dart';
import '../domain/usecases/cutting/get_po_no_list_usecase.dart';
import '../domain/usecases/cutting/get_po_by_no_usecase.dart';
import '../domain/usecases/cutting/get_po_list_for_dropdown_usecase.dart';
import '../domain/usecases/cutting/get_cumulative_cutting_usecase.dart';
import '../domain/usecases/cutting/validate_cutting_quantity_usecase.dart';
import '../domain/usecases/cutting/get_cutting_by_id_usecase.dart';
import '../domain/usecases/cutting/get_cutting_po_lines_usecase.dart';
import '../domain/usecases/cutting/get_next_voucher_no_usecase.dart';
import '../domain/usecases/sewing/create_sewing_usecase.dart';
import '../domain/usecases/sewing/get_sewing_list_usecase.dart';
import '../domain/usecases/sewing/update_sewing_usecase.dart';
import '../domain/usecases/sewing/delete_sewing_usecase.dart';
import '../domain/usecases/sewing/get_cumulative_cutting_usecase.dart'
    as sewing_cumulative;
import '../domain/usecases/sewing/get_cumulative_sewing_usecase.dart'
    as sewing_cumulative_sewing;
import '../domain/usecases/sewing/get_po_by_no_usecase.dart';
import '../domain/usecases/sewing/get_po_list_for_dropdown_usecase.dart';
import '../domain/usecases/sewing/get_po_no_list_usecase.dart';
import '../domain/usecases/sewing/validate_sewing_quantity_usecase.dart';
import '../domain/usecases/production/create_production_usecase.dart';
import '../domain/usecases/production/get_production_list_usecase.dart';
import '../domain/usecases/production/update_production_usecase.dart';
import '../domain/usecases/production/delete_production_usecase.dart';
import '../domain/usecases/production/get_article_colors_usecase.dart';
import '../domain/usecases/production/get_production_availability_usecase.dart';
import '../domain/usecases/production/get_production_po_list_usecase.dart';
import '../domain/usecases/production/validate_production_quantity_usecase.dart';
import '../data/repositories/export_repository.dart';
import '../data/repositories/production_report_repository.dart';
import '../data/repositories/finished_goods_report_repository.dart';
import '../data/repositories/warehouse_report_repository.dart';
import '../domain/repositories/i_finished_goods_report_repository.dart';
import '../domain/repositories/i_warehouse_report_repository.dart';
import '../domain/usecases/reports/generate_finished_goods_report_usecase.dart';
import '../domain/usecases/reports/get_warehouse_report_usecase.dart';
import '../domain/repositories/i_production_report_repository.dart';
import '../domain/usecases/reports/generate_production_report_usecase.dart';
import '../presentation/blocs/reports/production_report_bloc.dart';
import '../presentation/blocs/reports/finished_goods_report_bloc.dart';
import '../presentation/blocs/reports/warehouse_report_bloc.dart';
import '../domain/repositories/i_export_repository.dart';
import '../domain/usecases/export/create_export_usecase.dart';
import '../domain/usecases/export/delete_export_usecase.dart';
import '../domain/usecases/export/get_export_article_colors_usecase.dart';
import '../domain/usecases/export/get_export_availability_usecase.dart';
import '../domain/usecases/export/get_export_by_id_usecase.dart';
import '../domain/usecases/export/get_export_list_usecase.dart';
import '../domain/usecases/export/get_export_po_list_usecase.dart';
import '../domain/usecases/export/update_export_usecase.dart';
import '../domain/usecases/export/validate_export_quantity_usecase.dart';
import '../presentation/blocs/export/export_bloc.dart';
import '../domain/usecases/issue/create_issue_usecase.dart';
import '../domain/usecases/issue/get_issue_article_colors_usecase.dart';
import '../domain/usecases/issue/get_issue_availability_usecase.dart';
import '../domain/usecases/issue/get_issue_by_id_usecase.dart';
import '../domain/usecases/issue/get_issue_list_usecase.dart';
import '../domain/usecases/issue/get_issue_po_list_usecase.dart';
import '../domain/usecases/issue/update_issue_usecase.dart';
import '../domain/usecases/issue/delete_issue_usecase.dart';
import '../domain/usecases/issue/validate_issue_quantity_usecase.dart';
import '../data/repositories/dashboard_repository.dart';
import '../data/repositories/timelapse_repository.dart';
import '../domain/repositories/i_dashboard_repository.dart';
import '../domain/repositories/i_timelapse_repository.dart';
import '../domain/usecases/dashboard/get_comparison_data_usecase.dart';
import '../domain/usecases/dashboard/get_comparison_matrix_usecase.dart';
import '../domain/usecases/dashboard/get_dashboard_stats_usecase.dart';
import '../domain/usecases/dashboard/get_factory_comparison_usecase.dart';
import '../domain/usecases/dashboard/get_module_distribution_usecase.dart';
import '../domain/usecases/dashboard/get_production_trend_usecase.dart';
import '../domain/usecases/dashboard/get_quick_stats_usecase.dart';
import '../domain/usecases/dashboard/get_recent_activities_usecase.dart';
import '../domain/usecases/timelapse/get_timelapse_data_usecase.dart';
import '../presentation/blocs/dashboard/dashboard_bloc.dart';
import '../presentation/blocs/timelapse/timelapse_bloc.dart';
import '../presentation/blocs/auth/auth_bloc.dart';
import '../presentation/blocs/role_management/role_management_bloc.dart';
import '../presentation/blocs/user_management/user_management_bloc.dart';
import '../presentation/blocs/master_lc/master_lc_bloc.dart';
import '../presentation/blocs/purchase_order/po_bloc.dart';
import '../presentation/blocs/cutting/cutting_bloc.dart';
import '../presentation/blocs/sewing/sewing_bloc.dart';
import '../presentation/blocs/production/production_bloc.dart';
import '../presentation/blocs/issue/issue_bloc.dart';
import '../presentation/blocs/settings/settings_bloc.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupLocator() async {
  getIt.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseFirestore.instance,
  );
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton<FirebaseFirestoreService>(
    FirebaseFirestoreService.new,
  );
  getIt.registerLazySingleton<AuthRemoteDataSource>(AuthRemoteDataSource.new);
  getIt.registerLazySingleton<IAuthRepository>(
    () => AuthRepository(getIt<AuthRemoteDataSource>()),
  );
  getIt.registerLazySingleton<IUserRepository>(UserRepository.new);
  getIt.registerLazySingleton<LocalSettingsService>(LocalSettingsService.new);
  getIt.registerLazySingleton<ISettingsRepository>(
    () => SettingsRepository(
      firestore: getIt<FirebaseFirestore>(),
      auth: getIt<FirebaseAuth>(),
      localService: getIt<LocalSettingsService>(),
    ),
  );
  getIt.registerLazySingleton<IRoleRepository>(RoleRepository.new);
  getIt.registerLazySingleton<IMasterLCRepository>(MasterLCRepository.new);
  getIt.registerLazySingleton<IPORepository>(PORepository.new);
  getIt.registerLazySingleton<ICuttingRepository>(CuttingRepository.new);
  getIt.registerLazySingleton<ISewingRepository>(SewingRepository.new);
  getIt.registerLazySingleton<IProductionRepository>(ProductionRepository.new);
  getIt.registerLazySingleton<IIssueRepository>(IssueRepository.new);
  getIt.registerLazySingleton<IExportRepository>(ExportRepository.new);
  getIt.registerLazySingleton<IProductionReportRepository>(
    ProductionReportRepository.new,
  );
  getIt.registerLazySingleton<IFinishedGoodsReportRepository>(
    FinishedGoodsReportRepository.new,
  );
  getIt.registerLazySingleton<IWarehouseReportRepository>(
    WarehouseReportRepository.new,
  );
  getIt.registerLazySingleton(() => LoginUseCase(getIt<IAuthRepository>()));
  getIt.registerLazySingleton(() => RegisterUseCase(getIt<IAuthRepository>()));
  getIt.registerLazySingleton(() => LogoutUseCase(getIt<IAuthRepository>()));
  getIt.registerLazySingleton(
    () => GetCurrentUserUseCase(getIt<IAuthRepository>()),
  );
  getIt.registerLazySingleton(
    () => ResetPasswordUseCase(getIt<IAuthRepository>()),
  );
  getIt.registerLazySingleton(
    () => CheckAuthStatusUseCase(getIt<IAuthRepository>()),
  );
  getIt.registerLazySingleton(
    () => UpdateProfileUseCase(getIt<IAuthRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetAppSettingsUseCase(getIt<ISettingsRepository>()),
  );
  getIt.registerLazySingleton(
    () => SaveAppSettingsUseCase(getIt<ISettingsRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetBusinessSettingsUseCase(getIt<ISettingsRepository>()),
  );
  getIt.registerLazySingleton(
    () => SaveBusinessSettingsUseCase(getIt<ISettingsRepository>()),
  );
  getIt.registerLazySingleton(
    () => AuthBloc(
      login: getIt<LoginUseCase>(),
      register: getIt<RegisterUseCase>(),
      logout: getIt<LogoutUseCase>(),
      resetPassword: getIt<ResetPasswordUseCase>(),
      checkStatus: getIt<CheckAuthStatusUseCase>(),
      repository: getIt<IAuthRepository>(),
    ),
  );
  getIt.registerLazySingleton(
    () => CreateMasterLCUseCase(getIt<IMasterLCRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetMasterLCListUseCase(getIt<IMasterLCRepository>()),
  );
  getIt.registerLazySingleton(
    () => UpdateMasterLCUseCase(getIt<IMasterLCRepository>()),
  );
  getIt.registerLazySingleton(
    () => DeleteMasterLCUseCase(getIt<IMasterLCRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetMasterLCByTagUseCase(getIt<IMasterLCRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetProjectListUseCase(getIt<IMasterLCRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetCompanyListUseCase(getIt<IMasterLCRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetMasterLCByIdUseCase(getIt<IMasterLCRepository>()),
  );
  getIt.registerFactory(
    () => MasterLCBloc(
      getList: getIt<GetMasterLCListUseCase>(),
      create: getIt<CreateMasterLCUseCase>(),
      update: getIt<UpdateMasterLCUseCase>(),
      delete: getIt<DeleteMasterLCUseCase>(),
      getById: getIt<GetMasterLCByIdUseCase>(),
      getPOByTag: getIt<GetPOByTagUseCase>(),
      getProjects: getIt<GetProjectListUseCase>(),
      getCompanies: getIt<GetCompanyListUseCase>(),
    ),
  );
  getIt.registerLazySingleton(() => GetPOListUseCase(getIt<IPORepository>()));
  getIt.registerLazySingleton(() => GetPOByTagUseCase(getIt<IPORepository>()));
  getIt.registerLazySingleton(() => GetPOByIdUseCase(getIt<IPORepository>()));
  getIt.registerLazySingleton(
    () => ValidatePOQuantityUseCase(
      getIt<IPORepository>(),
      getIt<IMasterLCRepository>(),
    ),
  );
  getIt.registerLazySingleton(
    () => CreatePOUseCase(
      getIt<IPORepository>(),
      getIt<ValidatePOQuantityUseCase>(),
    ),
  );
  getIt.registerLazySingleton(
    () => UpdatePOUseCase(
      getIt<IPORepository>(),
      getIt<ValidatePOQuantityUseCase>(),
    ),
  );
  getIt.registerLazySingleton(() => DeletePOUseCase(getIt<IPORepository>()));
  getIt.registerFactory(
    () => POBloc(
      getList: getIt<GetPOListUseCase>(),
      getByTag: getIt<GetPOByTagUseCase>(),
      create: getIt<CreatePOUseCase>(),
      update: getIt<UpdatePOUseCase>(),
      delete: getIt<DeletePOUseCase>(),
      validateQuantity: getIt<ValidatePOQuantityUseCase>(),
      getMasterLCByTag: getIt<GetMasterLCByTagUseCase>(),
    ),
  );
  getIt.registerLazySingleton(
    () => GetAllUsersUseCase(getIt<IUserRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetUserByIdUseCase(getIt<IUserRepository>()),
  );
  getIt.registerLazySingleton(
    () => UpdateUserUseCase(getIt<IUserRepository>()),
  );
  getIt.registerLazySingleton(
    () => UpdateUserRoleUseCase(getIt<IUserRepository>()),
  );
  getIt.registerLazySingleton(
    () => UpdateUserPermissionsUseCase(getIt<IUserRepository>()),
  );
  getIt.registerLazySingleton(
    () => UpdateUserStatusUseCase(getIt<IUserRepository>()),
  );
  getIt.registerLazySingleton(
    () => DeleteUserUseCase(getIt<IUserRepository>()),
  );
  getIt.registerLazySingleton(
    () => BootstrapAdminProfileUseCase(getIt<IUserRepository>()),
  );
  getIt.registerLazySingleton<IDashboardRepository>(DashboardRepository.new);
  getIt.registerLazySingleton<ITimelapseRepository>(TimelapseRepository.new);
  getIt.registerLazySingleton(
    () => GetDashboardStatsUseCase(getIt<IDashboardRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetRecentActivitiesUseCase(getIt<IDashboardRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetQuickStatsUseCase(getIt<IDashboardRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetProductionTrendUseCase(getIt<IDashboardRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetFactoryComparisonUseCase(getIt<IDashboardRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetModuleDistributionUseCase(getIt<IDashboardRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetComparisonDataUseCase(getIt<IDashboardRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetComparisonMatrixUseCase(getIt<IDashboardRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetTimelapseDataUseCase(getIt<ITimelapseRepository>()),
  );
  getIt.registerFactory(
    () => DashboardBloc(
      getStats: getIt<GetDashboardStatsUseCase>(),
      getRecentActivities: getIt<GetRecentActivitiesUseCase>(),
      getQuickStats: getIt<GetQuickStatsUseCase>(),
      getProductionTrend: getIt<GetProductionTrendUseCase>(),
      getFactoryComparison: getIt<GetFactoryComparisonUseCase>(),
      getModuleDistribution: getIt<GetModuleDistributionUseCase>(),
      getComparisonData: getIt<GetComparisonDataUseCase>(),
      getComparisonMatrix: getIt<GetComparisonMatrixUseCase>(),
    ),
  );
  getIt.registerFactory(
    () => TimelapseBloc(
      getTimelapseData: getIt<GetTimelapseDataUseCase>(),
    ),
  );
  getIt.registerLazySingleton(
    () => CreateRoleUseCase(getIt<IRoleRepository>()),
  );
  getIt.registerLazySingleton(
    () => UpdateRolePermissionsUseCase(getIt<IRoleRepository>()),
  );
  getIt.registerLazySingleton(
    () => DeleteRoleUseCase(getIt<IRoleRepository>()),
  );
  getIt.registerFactory(
    () => UserManagementBloc(
      getUsers: getIt<GetAllUsersUseCase>(),
      updateRole: getIt<UpdateUserRoleUseCase>(),
      updatePermissions: getIt<UpdateUserPermissionsUseCase>(),
      updateStatus: getIt<UpdateUserStatusUseCase>(),
      deleteUser: getIt<DeleteUserUseCase>(),
      getUserById: getIt<GetUserByIdUseCase>(),
      updateUser: getIt<UpdateUserUseCase>(),
    ),
  );
  getIt.registerLazySingleton(
    () => GetAllRolesUseCase(getIt<IRoleRepository>()),
  );
  getIt.registerFactory(
    () => RoleManagementBloc(
      roles: getIt<GetAllRolesUseCase>(),
      createRole: getIt<CreateRoleUseCase>(),
      updatePermissions: getIt<UpdateRolePermissionsUseCase>(),
      deleteRole: getIt<DeleteRoleUseCase>(),
    ),
  );
  getIt.registerLazySingleton(
    () => CreateCuttingUseCase(
      getIt<ICuttingRepository>(),
      getIt<ValidateCuttingQuantityUseCase>(),
    ),
  );
  getIt.registerLazySingleton(
    () => GetCuttingListUseCase(getIt<ICuttingRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetNextVoucherNoUseCase(getIt<ICuttingRepository>()),
  );
  getIt.registerLazySingleton(
    () => UpdateCuttingUseCase(getIt<ICuttingRepository>()),
  );
  getIt.registerLazySingleton(
    () => DeleteCuttingUseCase(getIt<ICuttingRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetPONoListUseCase(getIt<ICuttingRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetPOByNoUseCase(getIt<ICuttingRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetPOListForDropdownUseCase(getIt<ICuttingRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetCumulativeCuttingUseCase(getIt<ICuttingRepository>()),
  );
  getIt.registerLazySingleton(
    () => ValidateCuttingQuantityUseCase(getIt<ICuttingRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetCuttingByIdUseCase(getIt<ICuttingRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetCuttingPOLinesUseCase(getIt<ICuttingRepository>()),
  );
  getIt.registerLazySingleton(
    () => ValidateSewingQuantityUseCase(getIt<ISewingRepository>()),
  );
  getIt.registerLazySingleton(
    () => CreateSewingUseCase(
      getIt<ISewingRepository>(),
      getIt<ValidateSewingQuantityUseCase>(),
    ),
  );
  getIt.registerLazySingleton(
    () => GetSewingListUseCase(getIt<ISewingRepository>()),
  );
  getIt.registerLazySingleton(
    () => UpdateSewingUseCase(
      getIt<ISewingRepository>(),
      getIt<ValidateSewingQuantityUseCase>(),
    ),
  );
  getIt.registerLazySingleton(
    () => DeleteSewingUseCase(getIt<ISewingRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetSewingPONoListUseCase(getIt<ISewingRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetSewingPOByNoUseCase(getIt<ISewingRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetSewingPOListForDropdownUseCase(getIt<ISewingRepository>()),
  );
  getIt.registerLazySingleton(
    () => sewing_cumulative.GetCumulativeCuttingUseCase(
      getIt<ISewingRepository>(),
    ),
  );
  getIt.registerLazySingleton(
    () => sewing_cumulative_sewing.GetCumulativeSewingUseCase(
      getIt<ISewingRepository>(),
    ),
  );
  getIt.registerLazySingleton(
    () => CreateProductionUseCase(
      getIt<IProductionRepository>(),
      ValidateProductionQuantityUseCase(
        getIt<ISewingRepository>(),
        getIt<IProductionRepository>(),
      ),
    ),
  );
  getIt.registerLazySingleton(
    () => GetProductionListUseCase(getIt<IProductionRepository>()),
  );
  getIt.registerLazySingleton(
    () => UpdateProductionUseCase(
      getIt<IProductionRepository>(),
      ValidateProductionQuantityUseCase(
        getIt<ISewingRepository>(),
        getIt<IProductionRepository>(),
      ),
    ),
  );
  getIt.registerLazySingleton(
    () => DeleteProductionUseCase(getIt<IProductionRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetProductionPOListUseCase(getIt<IProductionRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetArticleColorsUseCase(getIt<IProductionRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetProductionAvailabilityUseCase(
      getIt<ISewingRepository>(),
      getIt<IProductionRepository>(),
    ),
  );
  getIt.registerLazySingleton(
    () => CreateIssueUseCase(
      getIt<IIssueRepository>(),
      ValidateIssueQuantityUseCase(getIt<IIssueRepository>()),
    ),
  );
  getIt.registerLazySingleton(
    () => GetIssueListUseCase(getIt<IIssueRepository>()),
  );
  getIt.registerLazySingleton(
    () => UpdateIssueUseCase(
      getIt<IIssueRepository>(),
      ValidateIssueQuantityUseCase(getIt<IIssueRepository>()),
    ),
  );
  getIt.registerLazySingleton(
    () => DeleteIssueUseCase(getIt<IIssueRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetIssuePOListUseCase(getIt<IIssueRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetIssueArticleColorsUseCase(getIt<IIssueRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetIssueAvailabilityUseCase(getIt<IIssueRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetIssueByIdUseCase(getIt<IIssueRepository>()),
  );
  getIt.registerLazySingleton(
    () => CreateExportUseCase(
      getIt<IExportRepository>(),
      ValidateExportQuantityUseCase(getIt<IExportRepository>()),
    ),
  );
  getIt.registerLazySingleton(
    () => GetExportListUseCase(getIt<IExportRepository>()),
  );
  getIt.registerLazySingleton(
    () => UpdateExportUseCase(
      getIt<IExportRepository>(),
      ValidateExportQuantityUseCase(getIt<IExportRepository>()),
    ),
  );
  getIt.registerLazySingleton(
    () => DeleteExportUseCase(getIt<IExportRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetExportPOListUseCase(getIt<IExportRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetExportArticleColorsUseCase(getIt<IExportRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetExportAvailabilityUseCase(getIt<IExportRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetExportByIdUseCase(getIt<IExportRepository>()),
  );
  getIt.registerLazySingleton(
    () => GenerateProductionReportUseCase(getIt<IProductionReportRepository>()),
  );
  getIt.registerLazySingleton(
    () => GenerateFinishedGoodsReportUseCase(
      getIt<IFinishedGoodsReportRepository>(),
    ),
  );
  getIt.registerLazySingleton(
    () => GetWarehouseReportUseCase(getIt<IWarehouseReportRepository>()),
  );
  getIt.registerFactory(
    () => CuttingBloc(
      getList: getIt<GetCuttingListUseCase>(),
      create: getIt<CreateCuttingUseCase>(),
      update: getIt<UpdateCuttingUseCase>(),
      delete: getIt<DeleteCuttingUseCase>(),
      getPONos: getIt<GetPONoListUseCase>(),
      getPOList: getIt<GetPOListForDropdownUseCase>(),
      getPOByNo: getIt<GetPOByNoUseCase>(),
      getCumulative: getIt<GetCumulativeCuttingUseCase>(),
      validateQuantity: getIt<ValidateCuttingQuantityUseCase>(),
      repository: getIt<ICuttingRepository>(),
    ),
  );
  getIt.registerFactory(
    () => SewingBloc(
      getList: getIt<GetSewingListUseCase>(),
      create: getIt<CreateSewingUseCase>(),
      update: getIt<UpdateSewingUseCase>(),
      delete: getIt<DeleteSewingUseCase>(),
      getPOList: getIt<GetSewingPOListForDropdownUseCase>(),
      getPOByNo: getIt<GetSewingPOByNoUseCase>(),
      getCumulativeCutting:
          getIt<sewing_cumulative.GetCumulativeCuttingUseCase>(),
      getCumulativeSewing:
          getIt<sewing_cumulative_sewing.GetCumulativeSewingUseCase>(),
      validateQuantity: getIt<ValidateSewingQuantityUseCase>(),
      repository: getIt<ISewingRepository>(),
    ),
  );
  getIt.registerFactory(
    () => ProductionBloc(
      getList: getIt<GetProductionListUseCase>(),
      create: getIt<CreateProductionUseCase>(),
      update: getIt<UpdateProductionUseCase>(),
      delete: getIt<DeleteProductionUseCase>(),
      getPOList: getIt<GetProductionPOListUseCase>(),
      getArticleColors: getIt<GetArticleColorsUseCase>(),
      getAvailability: getIt<GetProductionAvailabilityUseCase>(),
      validateQuantity: ValidateProductionQuantityUseCase(
        getIt<ISewingRepository>(),
        getIt<IProductionRepository>(),
      ),
      repository: getIt<IProductionRepository>(),
    ),
  );
  getIt.registerFactory(
    () => IssueBloc(
      getList: getIt<GetIssueListUseCase>(),
      create: getIt<CreateIssueUseCase>(),
      update: getIt<UpdateIssueUseCase>(),
      delete: getIt<DeleteIssueUseCase>(),
      getPOList: getIt<GetIssuePOListUseCase>(),
      getArticleColors: getIt<GetIssueArticleColorsUseCase>(),
      getAvailability: getIt<GetIssueAvailabilityUseCase>(),
      validateQuantity: ValidateIssueQuantityUseCase(getIt<IIssueRepository>()),
      repository: getIt<IIssueRepository>(),
    ),
  );
  getIt.registerLazySingleton<SettingsBloc>(
    () => SettingsBloc(
      getAppSettings: getIt<GetAppSettingsUseCase>(),
      saveAppSettings: getIt<SaveAppSettingsUseCase>(),
      getBusinessSettings: getIt<GetBusinessSettingsUseCase>(),
      saveBusinessSettings: getIt<SaveBusinessSettingsUseCase>(),
    ),
  );
  getIt.registerFactory(
    () => ProfileBloc(updateProfile: getIt<UpdateProfileUseCase>()),
  );
  getIt.registerFactory(
    () => SecurityBloc(resetPassword: getIt<ResetPasswordUseCase>()),
  );
  getIt.registerFactory(
    () => ProductionReportBloc(
      generate: getIt<GenerateProductionReportUseCase>(),
    ),
  );
  getIt.registerFactory(
    () => FinishedGoodsReportBloc(
      generate: getIt<GenerateFinishedGoodsReportUseCase>(),
    ),
  );
  getIt.registerFactory(
    () => WarehouseReportBloc(
      getReport: getIt<GetWarehouseReportUseCase>(),
    ),
  );
  getIt.registerFactory(
    () => ExportBloc(
      getList: getIt<GetExportListUseCase>(),
      create: getIt<CreateExportUseCase>(),
      update: getIt<UpdateExportUseCase>(),
      delete: getIt<DeleteExportUseCase>(),
      getPOList: getIt<GetExportPOListUseCase>(),
      getArticleColors: getIt<GetExportArticleColorsUseCase>(),
      getAvailability: getIt<GetExportAvailabilityUseCase>(),
      validateQuantity: ValidateExportQuantityUseCase(
        getIt<IExportRepository>(),
      ),
      repository: getIt<IExportRepository>(),
    ),
  );
}
