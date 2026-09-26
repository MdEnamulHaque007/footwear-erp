/// ============================================================================
/// ফাইল: lib/presentation/blocs/role_management/role_management_bloc.dart
/// স্তর: Presentation BLoC | মডিউল: Role Management
/// উদ্দেশ্য: Role Management screen-এর event গ্রহণ করে state তৈরি এবং UI update নিয়ন্ত্রণ করে।
/// প্রধান অংশ: RoleManagementBloc
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
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
      if (emit.isDone) return;
      result.fold(
        (error) => emit(RoleManagementError(error)),
        (items) => emit(RoleManagementLoaded(items)),
      );
    });

    on<CreateRole>((event, emit) async {
      emit(RoleManagementLoading());
      final result = await createRole(event.name, event.permissions);
      if (emit.isDone) return;
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
      if (emit.isDone) return;
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
      if (emit.isDone) return;
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
