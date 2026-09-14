import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/config/dev_config.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'injection/dependency_injection.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/settings/settings_bloc.dart';
import 'presentation/blocs/settings/settings_event.dart';
import 'presentation/blocs/settings/settings_state.dart';
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
  if (firebaseInitializationError == null && kIsWeb) {
    try {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    } catch (error) {
      debugPrint('Unable to set web auth persistence: $error');
    }
  }
  if (firebaseInitializationError == null && DevConfig.useFirebaseEmulator) {
    // 🔴 Debug-only (see `DevConfig.useFirebaseEmulator`): point Auth and
    // Firestore at the local emulator suite without touching production data.
    try {
      FirebaseAuth.instance.useAuthEmulator(
        DevConfig.emulatorHost,
        DevConfig.authEmulatorPort,
      );
      FirebaseFirestore.instance.useFirestoreEmulator(
        DevConfig.emulatorHost,
        DevConfig.firestoreEmulatorPort,
      );
      debugPrint(
        'Using Firebase emulators at ${DevConfig.emulatorHost} '
        '(auth :${DevConfig.authEmulatorPort}, '
        'firestore :${DevConfig.firestoreEmulatorPort})',
      );
    } catch (error) {
      debugPrint('Unable to connect to Firebase emulators: $error');
    }
  }
  await Hive.initFlutter();
  await setupLocator();
  GetIt.I<SettingsBloc>().add(const LoadAppSettings());
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
      providers: [
        BlocProvider.value(value: GetIt.I<AuthBloc>()),
        BlocProvider.value(value: GetIt.I<SettingsBloc>()),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, _) {
          final settings = context.read<SettingsBloc>().currentAppSettings;
          return MaterialApp.router(
            title: AppConstants.appName,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: _themeMode(settings.themeMode),
            locale: _locale(settings.languageCode),
            supportedLocales: const [Locale('en'), Locale('bn'), Locale('zh')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(_textScale(settings.fontSize)),
              ),
              child: child ?? const SizedBox.shrink(),
            ),
            routerConfig: AppRoutes.router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }

  ThemeMode _themeMode(String value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  Locale _locale(String languageCode) => switch (languageCode) {
    'bn' => const Locale('bn'),
    'zh' => const Locale('zh'),
    _ => const Locale('en'),
  };

  double _textScale(String value) => switch (value) {
    'small' => 0.9,
    'large' => 1.15,
    _ => 1,
  };
}
