import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/role_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/repositories/i_user_repository.dart';
import '../../../domain/repositories/i_role_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final IUserRepository userRepository;
  final IRoleRepository roleRepository;
  
  DashboardBloc(this.userRepository, this.roleRepository) : super(DashboardInitial()) {
    on<LoadDashboardStats>(_onLoadStats);
  }
  
  Future<void> _onLoadStats(
    LoadDashboardStats event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      final userResult = await userRepository.getAllUsers();
      if (emit.isDone) return;
      final roleResult = await roleRepository.getAllRoles();
      if (emit.isDone) return;

      final users = userResult.fold<List<UserEntity>>(
        (_) => <UserEntity>[],
        (value) => value,
      );
      final roles = roleResult.fold<List<RoleEntity>>(
        (_) => <RoleEntity>[],
        (value) => value,
      );
      final userError = userResult.fold<String?>((error) => error, (_) => null);
      final roleError = roleResult.fold<String?>((error) => error, (_) => null);
      if (userError != null) {
        emit(DashboardError(userError));
      } else if (roleError != null) {
        emit(DashboardError(roleError));
      } else {
        final activeUsers = users.where((u) => u.isActive).length;
        emit(DashboardLoaded(
          totalUsers: users.length,
          totalRoles: roles.length,
          activeUsers: activeUsers,
        ));
      }
    } catch (e) {
      if (emit.isDone) return;
      emit(DashboardError('Failed to load dashboard stats'));
    }
  }
}
