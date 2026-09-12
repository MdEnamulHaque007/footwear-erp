import 'package:get_it/get_it.dart';

import '../core/services/firebase/firebase_firestore_service.dart';
import '../data/datasources/remote/auth_remote_datasource.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/role_repository.dart';
import '../data/repositories/user_repository.dart';
import '../domain/repositories/i_auth_repository.dart';
import '../domain/repositories/i_role_repository.dart';
import '../domain/repositories/i_user_repository.dart';
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
import '../domain/usecases/purchase_order/create_po_usecase.dart';
import '../domain/usecases/purchase_order/get_po_list_usecase.dart';
import '../domain/usecases/purchase_order/get_po_by_tag_usecase.dart';
import '../domain/usecases/purchase_order/update_po_usecase.dart';
import '../domain/usecases/purchase_order/delete_po_usecase.dart';
import '../domain/usecases/purchase_order/validate_po_quantity_usecase.dart';
import '../domain/usecases/user/delete_user_usecase.dart';
import '../domain/usecases/user/get_all_users_usecase.dart';
import '../domain/usecases/user/update_user_permissions_usecase.dart';
import '../domain/usecases/user/update_user_role_usecase.dart';
import '../domain/usecases/user/update_user_status_usecase.dart';
import '../domain/usecases/cutting/create_cutting_usecase.dart';
import '../domain/usecases/cutting/get_cutting_list_usecase.dart';
import '../domain/usecases/cutting/update_cutting_usecase.dart';
import '../domain/usecases/cutting/delete_cutting_usecase.dart';
import '../domain/usecases/cutting/get_po_no_list_usecase.dart';
import '../domain/usecases/cutting/get_po_by_no_usecase.dart';
import '../domain/usecases/cutting/get_po_list_for_dropdown_usecase.dart';
import '../domain/usecases/cutting/get_cumulative_cutting_usecase.dart';
import '../domain/usecases/cutting/validate_cutting_quantity_usecase.dart';
import '../domain/usecases/sewing/create_sewing_usecase.dart';
import '../domain/usecases/sewing/get_sewing_list_usecase.dart';
import '../domain/usecases/sewing/update_sewing_usecase.dart';
import '../domain/usecases/sewing/delete_sewing_usecase.dart';
import '../domain/usecases/sewing/validate_sewing_quantity_usecase.dart';
import '../domain/usecases/production/create_production_usecase.dart';
import '../domain/usecases/production/get_production_list_usecase.dart';
import '../domain/usecases/production/update_production_usecase.dart';
import '../domain/usecases/production/delete_production_usecase.dart';
import '../domain/usecases/production/validate_production_quantity_usecase.dart';
import '../domain/usecases/issue/create_issue_usecase.dart';
import '../domain/usecases/issue/get_issue_list_usecase.dart';
import '../domain/usecases/issue/update_issue_usecase.dart';
import '../domain/usecases/issue/delete_issue_usecase.dart';
import '../domain/usecases/issue/validate_issue_quantity_usecase.dart';
import '../presentation/blocs/auth/auth_bloc.dart';
import '../presentation/blocs/role_management/role_management_bloc.dart';
import '../presentation/blocs/user_management/user_management_bloc.dart';
import '../presentation/blocs/master_lc/master_lc_bloc.dart';
import '../presentation/blocs/purchase_order/po_bloc.dart';
import '../presentation/blocs/dashboard/dashboard_bloc.dart';
import '../presentation/blocs/cutting/cutting_bloc.dart';
import '../presentation/blocs/sewing/sewing_bloc.dart';
import '../presentation/blocs/production/production_bloc.dart';
import '../presentation/blocs/issue/issue_bloc.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupLocator() async {
  getIt.registerLazySingleton<FirebaseFirestoreService>(
    FirebaseFirestoreService.new,
  );
  getIt.registerLazySingleton<AuthRemoteDataSource>(AuthRemoteDataSource.new);
  getIt.registerLazySingleton<IAuthRepository>(
    () => AuthRepository(getIt<AuthRemoteDataSource>()),
  );
  getIt.registerLazySingleton<IUserRepository>(UserRepository.new);
  getIt.registerLazySingleton<IRoleRepository>(RoleRepository.new);
  getIt.registerLazySingleton<IMasterLCRepository>(MasterLCRepository.new);
  getIt.registerLazySingleton<IPORepository>(PORepository.new);
  getIt.registerLazySingleton<ICuttingRepository>(CuttingRepository.new);
  getIt.registerLazySingleton<ISewingRepository>(SewingRepository.new);
  getIt.registerLazySingleton<IProductionRepository>(ProductionRepository.new);
  getIt.registerLazySingleton<IIssueRepository>(IssueRepository.new);
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
    ),
  );
  getIt.registerLazySingleton(() => GetPOListUseCase(getIt<IPORepository>()));
  getIt.registerLazySingleton(() => GetPOByTagUseCase(getIt<IPORepository>()));
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
    () => CreateSewingUseCase(
      getIt<ISewingRepository>(),
      ValidateSewingQuantityUseCase(getIt<ICuttingRepository>()),
    ),
  );
  getIt.registerLazySingleton(
    () => GetSewingListUseCase(getIt<ISewingRepository>()),
  );
  getIt.registerLazySingleton(
    () => UpdateSewingUseCase(getIt<ISewingRepository>()),
  );
  getIt.registerLazySingleton(
    () => DeleteSewingUseCase(getIt<ISewingRepository>()),
  );
  getIt.registerLazySingleton(
    () => CreateProductionUseCase(
      getIt<IProductionRepository>(),
      ValidateProductionQuantityUseCase(getIt<ISewingRepository>()),
    ),
  );
  getIt.registerLazySingleton(
    () => GetProductionListUseCase(getIt<IProductionRepository>()),
  );
  getIt.registerLazySingleton(
    () => UpdateProductionUseCase(getIt<IProductionRepository>()),
  );
  getIt.registerLazySingleton(
    () => DeleteProductionUseCase(getIt<IProductionRepository>()),
  );
  getIt.registerLazySingleton(
    () => CreateIssueUseCase(
      getIt<IIssueRepository>(),
      ValidateIssueQuantityUseCase(
        getIt<IProductionRepository>(),
        getIt<IIssueRepository>(),
      ),
    ),
  );
  getIt.registerLazySingleton(
    () => GetIssueListUseCase(getIt<IIssueRepository>()),
  );
  getIt.registerLazySingleton(
    () => UpdateIssueUseCase(
      getIt<IIssueRepository>(),
      ValidateIssueQuantityUseCase(
        getIt<IProductionRepository>(),
        getIt<IIssueRepository>(),
      ),
    ),
  );
  getIt.registerLazySingleton(
    () => DeleteIssueUseCase(getIt<IIssueRepository>()),
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
    ),
  );
  getIt.registerFactory(
    () => ProductionBloc(
      getList: getIt<GetProductionListUseCase>(),
      create: getIt<CreateProductionUseCase>(),
      update: getIt<UpdateProductionUseCase>(),
      delete: getIt<DeleteProductionUseCase>(),
    ),
  );
  getIt.registerFactory(
    () => IssueBloc(
      getList: getIt<GetIssueListUseCase>(),
      create: getIt<CreateIssueUseCase>(),
      update: getIt<UpdateIssueUseCase>(),
      delete: getIt<DeleteIssueUseCase>(),
    ),
  );
  getIt.registerFactory(
    () => DashboardBloc(getIt<IUserRepository>(), getIt<IRoleRepository>()),
  );
}
