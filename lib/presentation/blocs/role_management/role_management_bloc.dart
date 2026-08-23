import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/role/get_all_roles_usecase.dart';
import '../../../domain/usecases/role/create_role_usecase.dart';
import '../../../domain/usecases/role/delete_role_usecase.dart';
import '../../../domain/usecases/role/update_role_permissions_usecase.dart';
import 'role_management_event.dart';
import 'role_management_state.dart';

class RoleManagementBloc extends Bloc<RoleManagementEvent, RoleManagementState> {
  RoleManagementBloc({
    required this.roles, // renamed in this file only? let's keep it roles for less breaking changes
    required this.createRole,
    required this.updatePermissions,
    required this.deleteRole,
  }) : super(RoleManagementInitial()) {
    on<LoadRoles>((event, emit) async {
      emit(RoleManagementLoading());
      final result = await roles();
      result.fold(
        (error) => emit(RoleManagementError(error)),
        (items) => emit(RoleManagementLoaded(items)),
      );
    });

    on<CreateRole>((event, emit) async {
      emit(RoleManagementLoading());
      final result = await createRole(event.name, event.permissions);
      result.fold(
        (error) => emit(RoleManagementError(error)),
        (_) {
          emit(RoleManagementSuccess('Role created'));
          add(LoadRoles());
        },
      );
    });

    on<UpdateRolePermissions>((event, emit) async {
      emit(RoleManagementLoading());
      final result = await updatePermissions(event.roleId, event.permissions);
      result.fold(
        (error) => emit(RoleManagementError(error)),
        (_) {
          emit(RoleManagementSuccess('Role permissions updated'));
          add(LoadRoles());
        },
      );
    });

    on<DeleteRole>((event, emit) async {
      emit(RoleManagementLoading());
      final result = await deleteRole(event.roleId);
      result.fold(
        (error) => emit(RoleManagementError(error)),
        (_) {
          emit(RoleManagementSuccess('Role deleted'));
          add(LoadRoles());
        },
      );
    });
  }

  final GetAllRolesUseCase roles;
  final CreateRoleUseCase createRole;
  final UpdateRolePermissionsUseCase updatePermissions;
  final DeleteRoleUseCase deleteRole;
}
