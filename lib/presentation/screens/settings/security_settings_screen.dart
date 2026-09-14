import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/color_palette.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/security/security_bloc.dart';
import '../../widgets/app_drawer.dart';

class SecuritySettingsScreen extends StatelessWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    drawer: const AppDrawer(),
    appBar: AppBar(
      leadingWidth: 96,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/settings'),
          ),
          Builder(
            builder: (drawerContext) => IconButton(
              tooltip: 'Menu',
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(drawerContext).openDrawer(),
            ),
          ),
        ],
      ),
      title: const Text('Security'),
    ),
    body: BlocConsumer<SecurityBloc, SecurityState>(
      listener: (context, state) {
        if (state is SecuritySuccess || state is SecurityFailure) {
          final message = state is SecuritySuccess
              ? state.message
              : (state as SecurityFailure).message;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      },
      builder: (context, securityState) => BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is! Authenticated) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = authState.user;
          final isLoading = securityState is SecurityLoading;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              const _SectionHeader('ACCOUNT SECURITY'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        user.isEmailVerified
                            ? Icons.verified_user_outlined
                            : Icons.warning_amber_outlined,
                        color: user.isEmailVerified
                            ? ColorPalette.success
                            : ColorPalette.warning,
                      ),
                      title: const Text('Email verification'),
                      subtitle: Text(user.email),
                      trailing: Text(
                        user.isEmailVerified ? 'Verified' : 'Not verified',
                        style: TextStyle(
                          color: user.isEmailVerified
                              ? ColorPalette.success
                              : ColorPalette.warning,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        user.isActive
                            ? Icons.lock_outline
                            : Icons.lock_person_outlined,
                        color: user.isActive
                            ? ColorPalette.success
                            : ColorPalette.error,
                      ),
                      title: const Text('Account status'),
                      trailing: Text(
                        user.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: user.isActive
                              ? ColorPalette.success
                              : ColorPalette.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const _SectionHeader('PASSWORD'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Change your password securely',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'We will send a password reset link to your registered email address.',
                        style: TextStyle(color: ColorPalette.muted),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: isLoading
                            ? null
                            : () => context
                                  .read<SecurityBloc>()
                                  .sendPasswordReset(user.email),
                        icon: isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.password_outlined),
                        label: Text(
                          isLoading
                              ? 'Sending reset link...'
                              : 'Send password reset link',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const _SectionHeader('SECURITY NOTE'),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Keep your account safe'),
                  subtitle: Text(
                    'Never share your password or reset link with anyone.',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: const TextStyle(
        color: ColorPalette.muted,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
    ),
  );
}
