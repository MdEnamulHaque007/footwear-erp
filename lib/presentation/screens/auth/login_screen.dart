import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../../core/config/dev_config.dart';
import '../../../core/utils/validators/auth_validator.dart';
import '../../routes/route_constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Login')),
    body: BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) context.go(RouteConstants.dashboard);
        if (state is AuthError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 16),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) => ElevatedButton(
                onPressed: state is AuthLoading
                    ? null
                    : () {
                        if (AuthValidator.validateEmail(email.text) == null &&
                            AuthValidator.validatePassword(password.text) ==
                                null) {
                          context.read<AuthBloc>().add(
                            LoginRequested(email.text, password.text),
                          );
                        }
                      },
                child: state is AuthLoading
                    ? const CircularProgressIndicator()
                    : const Text('Login'),
              ),
            ),
            TextButton(
              onPressed: () => context.go('/register'),
              child: const Text('Create account'),
            ),
            TextButton(
              onPressed: () => context.go('/reset-password'),
              child: const Text('Forgot password?'),
            ),
            if (DevConfig.bypassAuth) ...[
              const Divider(height: 32),
              OutlinedButton.icon(
                onPressed: () =>
                    context.read<AuthBloc>().add(DevSkipLoginRequested()),
                icon: const Icon(Icons.developer_mode),
                label: const Text('Skip login (dev)'),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
