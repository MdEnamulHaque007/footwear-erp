/// ============================================================================
/// ফাইল: lib/presentation/screens/auth/admin_bootstrap_screen.dart
/// স্তর: Presentation Screen | মডিউল: Authentication
/// উদ্দেশ্য: Authentication মডিউলের user interface, input, filter ও user interaction উপস্থাপন করে।
/// প্রধান অংশ: AdminBootstrapScreen, _AdminBootstrapScreenState
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/color_palette.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/usecases/user/bootstrap_admin_profile_usecase.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../routes/route_constants.dart';

/// One-click first-admin bootstrap.
///
/// Solves the bootstrap deadlock: an account created in the Firebase console
/// exists in Firebase Auth but has no `users/{uid}` profile, so every Firestore
/// rule denies it and the account can never authorise itself. This screen
/// writes that missing profile as `admin`.
///
/// The backing Firestore rule permits the write only while no admin profile
/// exists, so this is a genuine one-time initial-setup action — once an admin
/// exists the write is rejected and the screen explains that an existing admin
/// must grant access instead.
class AdminBootstrapScreen extends StatefulWidget {
  const AdminBootstrapScreen({super.key});

  @override
  State<AdminBootstrapScreen> createState() => _AdminBootstrapScreenState();
}

class _AdminBootstrapScreenState extends State<AdminBootstrapScreen> {
  final _nameController = TextEditingController();
  bool _busy = false;
  String? _error;
  UserEntity? _created;

  @override
  void initState() {
    super.initState();
    // Pre-fill from the authenticated account when one is available.
    final authState = GetIt.I<AuthBloc>().state;
    if (authState is Authenticated) {
      _nameController.text = authState.user.displayLabel;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a display name for the administrator.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await GetIt.I<BootstrapAdminProfileUseCase>()(
      displayName: name,
    );
    if (!mounted) return;
    result.fold(
      (error) => setState(() {
        _busy = false;
        _error = error;
      }),
      (user) {
        setState(() {
          _busy = false;
          _created = user;
        });
        // Re-run the auth check so the app picks up the new profile and the
        // route guard stops redirecting back here.
        GetIt.I<AuthBloc>().add(CheckAuthStatus());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrator setup'),
        leadingWidth: 96,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(RouteConstants.login),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: _created != null ? _successView(_created!) : _formView(),
          ),
        ),
      ),
    );
  }

  Widget _formView() {
    final authState = GetIt.I<AuthBloc>().state;
    final email = authState is Authenticated ? authState.user.email : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.admin_panel_settings_outlined,
          size: 64,
          color: ColorPalette.dashboard,
        ),
        const SizedBox(height: 16),
        Text(
          'Create the administrator profile',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'This account is signed in but has no profile document, so no data '
          'can be read or written yet. Creating the administrator profile '
          'grants full access.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (email != null) ...[
          const SizedBox(height: 12),
          Text(
            email,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 24),
        TextField(
          controller: _nameController,
          enabled: !_busy,
          decoration: const InputDecoration(
            labelText: 'Display name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'role: admin   ·   isActive: true',
          textAlign: TextAlign.center,
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _busy ? null : _bootstrap,
          icon: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: Text(_busy ? 'Creating…' : 'Create administrator profile'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _busy
              ? null
              : () => GetIt.I<AuthBloc>().add(LogoutRequested()),
          child: const Text('Sign out'),
        ),
      ],
    );
  }

  Widget _successView(UserEntity user) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
      const SizedBox(height: 16),
      Text(
        'Administrator profile created',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 8),
      Text(
        '${user.displayLabel} now has full access to every module.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: () => context.go(AppConstants.dashboardRoute),
        child: const Text('Go to dashboard'),
      ),
    ],
  );
}
