import 'package:flutter_bloc/flutter_bloc.dart';
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
      final roleResult = await roleRepository.getAllRoles();

      userResult.fold(
        (error) => emit(DashboardError(error)),
        (users) {
          roleResult.fold(
            (error) => emit(DashboardError(error)),
            (roles) {
              final activeUsers = users.where((u) => u.isActive).length;
              emit(DashboardLoaded(
                totalUsers: users.length,
                totalRoles: roles.length,
                activeUsers: activeUsers,
              ));
            },
          );
        },
      );
    } catch (e) {
      emit(DashboardError('Failed to load dashboard stats'));
    }
  }
}
