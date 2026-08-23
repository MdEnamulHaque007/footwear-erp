import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/user/delete_user_usecase.dart';
import '../../../domain/usecases/user/get_all_users_usecase.dart';
import '../../../domain/usecases/user/update_user_permissions_usecase.dart';
import '../../../domain/usecases/user/update_user_role_usecase.dart';
import '../../../domain/usecases/user/update_user_status_usecase.dart';
import 'user_management_event.dart';
import 'user_management_state.dart';

class UserManagementBloc extends Bloc<UserManagementEvent, UserManagementState> {
  UserManagementBloc({
    required this.getUsers,
    required this.updateRole,
    required this.updatePermissions,
    required this.updateStatus,
    required this.deleteUser,
  }) : super(UserManagementInitial()) {
    on<LoadUsers>((event, emit) async {
      emit(UserManagementLoading());
      final result = await getUsers();
      result.fold(
        (error) => emit(UserManagementError(error)),
        (users) => emit(UserManagementLoaded(users)),
      );
    });

    on<UpdateUserRole>((event, emit) async {
      emit(UserManagementLoading());
      final result = await updateRole(event.uid, event.role);
      result.fold(
        (error) => emit(UserManagementError(error)),
        (_) {
          emit(UserManagementSuccess('User role updated'));
          add(LoadUsers());
        },
      );
    });

    on<UpdateUserPermissions>((event, emit) async {
      emit(UserManagementLoading());
      final result = await updatePermissions(event.uid, event.permissions);
      result.fold(
        (error) => emit(UserManagementError(error)),
        (_) {
          emit(UserManagementSuccess('User permissions updated'));
          add(LoadUsers());
        },
      );
    });

    on<UpdateUserStatus>((event, emit) async {
      emit(UserManagementLoading());
      final result = await updateStatus(event.uid, event.active);
      result.fold(
        (error) => emit(UserManagementError(error)),
        (_) {
          emit(UserManagementSuccess('User status updated'));
          add(LoadUsers());
        },
      );
    });

    on<DeleteUser>((event, emit) async {
      emit(UserManagementLoading());
      final result = await deleteUser(event.uid);
      result.fold(
        (error) => emit(UserManagementError(error)),
        (_) {
          emit(UserManagementSuccess('User deleted'));
          add(LoadUsers());
        },
      );
    });
  }

  final GetAllUsersUseCase getUsers;
  final UpdateUserRoleUseCase updateRole;
  final UpdateUserPermissionsUseCase updatePermissions;
  final UpdateUserStatusUseCase updateStatus;
  final DeleteUserUseCase deleteUser;
}
