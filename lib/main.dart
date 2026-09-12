import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'injection/dependency_injection.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? firebaseInitializationError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    firebaseInitializationError = error.toString();
    debugPrint('Firebase initialization failed: $error');
  }
  await Hive.initFlutter();
  await setupLocator();
  runApp(MyApp(firebaseInitializationError: firebaseInitializationError));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.firebaseInitializationError});

  final String? firebaseInitializationError;

  @override
  Widget build(BuildContext context) {
    if (firebaseInitializationError != null) {
      return MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        home: Scaffold(
          appBar: AppBar(title: const Text(AppConstants.appName)),
          body: Center(
            child: Text(
              'Firebase initialization failed.\n$firebaseInitializationError',
            ),
          ),
        ),
      );
    }
    return MultiBlocProvider(
      providers: [BlocProvider.value(value: GetIt.I<AuthBloc>())],
      child: MaterialApp.router(
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        routerConfig: AppRoutes.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
