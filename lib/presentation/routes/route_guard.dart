import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import '../../core/config/dev_config.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';
import 'route_constants.dart';

class RouteGuard {
  static const _publicPaths = {
    '/login',
    '/register',
    '/reset-password',
    // Reachable by an authenticated account that has no profile yet: the
    // bootstrap screen is the only way out of that state, so it must not be
    // redirected away.
    RouteConstants.adminBootstrap,
  };

  static bool _isPublicPath(String location) => _publicPaths.contains(location);

  static String? redirect(GoRouterState state) {
    // 🔴 Debug-only bypass (see `DevConfig.bypassAuth`): every route — including
    // `/login`, `/register` and `/admin/**` — is reachable without
    // authentication. Never active in a release build because both
    // `DevConfig.bypassAuth` and [kDebugMode] are `false` there.
    if (DevConfig.bypassAuth && kDebugMode) return null;

    final authState = GetIt.I<AuthBloc>().state;

    // Check: Is user authenticated?
    if (authState is! Authenticated) {
      if (!_isPublicPath(state.matchedLocation)) {
        return '/login'; // Redirect to login
      }
      return null;
    }

    // User is authenticated
    //
    // A signed-in account whose profile could not be loaded (no `users/{uid}`
    // document) holds no role, so every Firestore rule would deny it. Send it
    // to the one-time administrator bootstrap instead of letting it land on a
    // dashboard where every list fails with "Missing or insufficient
    // permissions". The bootstrap page itself is exempt so it cannot redirect
    // to itself.
    if (authState.user.role.isEmpty) {
      return state.matchedLocation == RouteConstants.adminBootstrap
          ? null
          : RouteConstants.adminBootstrap;
    }

    if (_isPublicPath(state.matchedLocation)) return '/';

    // Check: Is this an admin route?
    final isAdminRoute =
        state.matchedLocation.startsWith('/admin') ||
        state.matchedLocation == RouteConstants.auditLog;
    if (isAdminRoute) {
      final user = authState.user;
      if (user.role != 'admin') {
        return '/unauthorized';
      }
    }

    return null; // Allow navigation
  }
}
