import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/usecases/user/delete_user_usecase.dart';
import '../../../domain/usecases/user/get_all_users_usecase.dart';
import '../../../domain/usecases/user/get_user_by_id_usecase.dart';
import '../../../domain/usecases/user/update_user_permissions_usecase.dart';
import '../../../domain/usecases/user/update_user_role_usecase.dart';
import '../../../domain/usecases/user/update_user_status_usecase.dart';
import '../../../domain/usecases/user/update_user_usecase.dart';
import 'user_management_event.dart';
import 'user_management_state.dart';

class UserManagementBloc extends Bloc<UserManagementEvent, UserManagementState> {
  UserManagementBloc({
    required this.getUsers,
    required this.updateRole,
    required this.updatePermissions,
    required this.updateStatus,
    required this.deleteUser,
    this.getUserById,
    this.updateUser,
  }) : super(UserManagementInitial()) {
    on<LoadUsers>(_onLoadUsers);
    on<LoadMoreUsers>(_onLoadMore);
    on<SearchUsers>(_onSearch);
    on<ClearSearchUsers>(_onClearSearch);
    on<RefreshUsers>(_onRefresh);
    on<LoadUserDetail>(_onLoadDetail);
    on<UpdateUserRole>(_onUpdateRole);
    on<UpdateUser>(_onUpdateUser);
    on<UpdateUserPermissions>(_onUpdatePermissions);
    on<UpdateUserStatus>(_onUpdateStatus);
    on<DeleteUser>(_onDelete);
  }

  Future<void> _onLoadUsers(
    LoadUsers event,
    Emitter<UserManagementState> emit,
  ) async {
    _currentPage = 0;
    _hasMore = true;
    emit(UserManagementLoading());
    final result = await getUsers(page: 0, limit: event.limit);
    if (emit.isDone) return;
    result.fold((error) => emit(UserManagementError(error)), (users) {
      _items = users;
      _hasMore = users.length == event.limit;
      emit(_loadedState());
    });
  }

  Future<void> _onLoadMore(
    LoadMoreUsers event,
    Emitter<UserManagementState> emit,
  ) async {
    if (!_hasMore || _isLoadingMore) return;
    _isLoadingMore = true;
    emit(
      UserManagementLoadingMore(List.from(_items), currentPage: _currentPage),
    );
    try {
      final result = await getUsers(page: _currentPage + 1, limit: 20);
      if (emit.isDone) return;
      result.fold(
        (error) {
          // Stop the trigger so a failed page cannot re-fire every frame.
          _hasMore = false;
          emit(UserManagementError(error));
        },
        (users) {
          _currentPage++;
          _items.addAll(users);
          _hasMore = users.length == 20;
          emit(_loadedState());
        },
      );
    } catch (error) {
      if (emit.isDone) return;
      _hasMore = false;
      emit(UserManagementError('$error'));
    } finally {
      _isLoadingMore = false;
    }
  }

  /// Filters the rows already loaded, client-side.
  ///
  /// Matching is case-insensitive across name, email and role.
  Future<void> _onSearch(
    SearchUsers event,
    Emitter<UserManagementState> emit,
  ) async {
    _search = event.query.trim();
    emit(_loadedState());
  }

  Future<void> _onClearSearch(
    ClearSearchUsers event,
    Emitter<UserManagementState> emit,
  ) async {
    _search = '';
    emit(_loadedState());
  }

  Future<void> _onRefresh(
    RefreshUsers event,
    Emitter<UserManagementState> emit,
  ) async {
    add(LoadUsers());
  }

  /// The loaded state, filtered by the active search when one is set.
  UserManagementState _loadedState() => UserSearchLoaded(
    _filtered(),
    hasMore: _hasMore,
    currentPage: _currentPage,
    query: _search,
  );

  List<UserEntity> _filtered() {
    if (_search.isEmpty) return List.from(_items);
    final query = _search.toLowerCase();
    return _items
        .where(
          (user) =>
              user.displayName.toLowerCase().contains(query) ||
              user.email.toLowerCase().contains(query) ||
              user.role.toLowerCase().contains(query),
        )
        .toList();
  }

  Future<void> _onLoadDetail(
    LoadUserDetail event,
    Emitter<UserManagementState> emit,
  ) async {
    // Show the row we already have while the fresh copy loads.
    final initial = event.initialUser;
    if (initial != null) emit(UserDetailLoaded(initial));
    final fetch = getUserById;
    if (fetch == null) {
      if (initial == null) {
        emit(UserManagementError('User details are unavailable'));
      }
      return;
    }
    if (initial == null) emit(UserDetailLoading());
    final result = await fetch(event.uid);
    if (emit.isDone) return;
    result.fold((error) => emit(UserManagementError(error)), (user) {
      if (user == null) {
        emit(UserManagementError('User not found'));
        return;
      }
      emit(UserDetailLoaded(user));
    });
  }

  Future<void> _onUpdateRole(
    UpdateUserRole event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(UserManagementLoading());
    final result = await updateRole(event.uid, event.role);
    if (emit.isDone) return;
    result.fold((error) => emit(UserManagementError(error)), (_) {
      emit(UserManagementSuccess('User role updated'));
      add(LoadUsers());
    });
  }

  Future<void> _onUpdateUser(
    UpdateUser event,
    Emitter<UserManagementState> emit,
  ) async {
    final save = updateUser;
    if (save == null) {
      emit(UserManagementError('User updates are unavailable'));
      return;
    }
    emit(UserManagementLoading());
    final result = await save(event.user);
    if (emit.isDone) return;
    result.fold((error) => emit(UserManagementError(error)), (_) {
      emit(UserManagementSuccess('User updated'));
      add(LoadUsers());
    });
  }

  Future<void> _onUpdatePermissions(
    UpdateUserPermissions event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(UserManagementLoading());
    final result = await updatePermissions(event.uid, event.permissions);
    if (emit.isDone) return;
    result.fold((error) => emit(UserManagementError(error)), (_) {
      emit(UserManagementSuccess('User permissions updated'));
      add(LoadUsers());
    });
  }

  Future<void> _onUpdateStatus(
    UpdateUserStatus event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(UserManagementLoading());
    final result = await updateStatus(event.uid, event.active);
    if (emit.isDone) return;
    result.fold((error) => emit(UserManagementError(error)), (_) {
      emit(UserManagementSuccess('User status updated'));
      add(LoadUsers());
    });
  }

  Future<void> _onDelete(
    DeleteUser event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(UserManagementLoading());
    final result = await deleteUser(event.uid);
    if (emit.isDone) return;
    result.fold((error) => emit(UserManagementError(error)), (_) {
      emit(UserManagementSuccess('User deleted'));
      add(LoadUsers());
    });
  }

  final GetAllUsersUseCase getUsers;
  final UpdateUserRoleUseCase updateRole;
  final UpdateUserPermissionsUseCase updatePermissions;
  final UpdateUserStatusUseCase updateStatus;
  final DeleteUserUseCase deleteUser;
  final GetUserByIdUseCase? getUserById;
  final UpdateUserUseCase? updateUser;

  List<UserEntity> _items = [];
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  String _search = '';
}
