import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';

class RouteGuard {
  static String? redirect(GoRouterState state) {
    final authState = GetIt.I<AuthBloc>().state;
    
    // Check: Is user authenticated?
    if (authState is! Authenticated) {
      final isPublic = state.matchedLocation == '/login' ||
                       state.matchedLocation == '/register' ||
                       state.matchedLocation == '/reset-password';
      if (!isPublic) return '/login'; // Redirect to login
      return null;
    }
    
    // User is authenticated
    final isPublic = state.matchedLocation == '/login' ||
                     state.matchedLocation == '/register' ||
                     state.matchedLocation == '/reset-password';
    if (isPublic) return '/';

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
