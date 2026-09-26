/// ============================================================================
/// ফাইল: lib/presentation/screens/auth/splash_screen.dart
/// স্তর: Presentation Screen | মডিউল: Authentication
/// উদ্দেশ্য: Authentication মডিউলের user interface, input, filter ও user interaction উপস্থাপন করে।
/// প্রধান অংশ: SplashScreen, _SplashScreenState
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../routes/route_constants.dart';

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
      if (state is Authenticated) context.go(RouteConstants.dashboard);
      if (state is Unauthenticated || state is AuthError) context.go('/login');
    },
    child: const Scaffold(body: Center(child: CircularProgressIndicator())),
  );
}
