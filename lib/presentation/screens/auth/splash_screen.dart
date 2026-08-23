import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AuthBloc>().add(AuthStarted()),
    );
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      final state = context.read<AuthBloc>().state;
      if (state is AuthLoading || state is AuthInitial) {
        context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) => BlocListener<AuthBloc, AuthState>(
    listener: (context, state) {
      if (state is Authenticated) context.go('/dashboard');
      if (state is Unauthenticated || state is AuthError) context.go('/login');
    },
    child: const Scaffold(body: Center(child: CircularProgressIndicator())),
  );
}
