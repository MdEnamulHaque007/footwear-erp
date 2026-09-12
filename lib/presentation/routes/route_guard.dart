import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';

class RouteGuard {
  static const _publicPaths = {'/login', '/register', '/reset-password'};

  static bool _isPublicPath(String location) => _publicPaths.contains(location);

  static String? redirect(GoRouterState state) {
    final authState = GetIt.I<AuthBloc>().state;

    // Check: Is user authenticated?
    if (authState is! Authenticated) {
      if (!_isPublicPath(state.matchedLocation)) return '/login'; // Redirect to login
      return null;
    }

    // User is authenticated
    if (_isPublicPath(state.matchedLocation)) return '/';

    // Check: Is this an admin route?
    final isAdminRoute = state.matchedLocation.startsWith('/admin');
    if (isAdminRoute) {
      final user = authState.user;
      if (user.role != 'admin') {
        return '/unauthorized';
      }
    }

    return null; // Allow navigation
  }
}
