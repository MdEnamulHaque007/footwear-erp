/// ============================================================================
/// ফাইল: lib/main.dart
/// স্তর: Application Entry | মডিউল: App Bootstrap
/// উদ্দেশ্য: Flutter binding, Firebase, dependency injection ও মূল application widget চালু করে।
/// প্রধান অংশ: MyApp
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
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

/// অ্যাপের মূল এন্ট্রি পয়েন্ট ফাংশন।
/// এখানে সব ইনিশিয়ালাইজেশন কাজ সম্পন্ন করে অ্যাপ চালু করা হয়।
Future<void> main() async {
  // Flutter বাইন্ডিং নিশ্চিত করা — প্লাগইন ও অ্যাসিঙ্ক অপারেশনের আগে জরুরি
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase ইনিশিয়ালাইজেশন ব্যর্থ হলে এরর মেসেজ রাখার জন্য
  String? firebaseInitializationError;

  try {
    // Firebase অ্যাপ ইনিশিয়ালাইজ — প্ল্যাটফর্ম অনুসারে DefaultFirebaseOptions ব্যবহার
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    // ব্যর্থ হলে এরর সেভ ও কনসোলে প্রিন্ট
    firebaseInitializationError = error.toString();
    debugPrint('Firebase initialization failed: $error');
  }

  // ওয়েব হলে Auth persistence LOCAL করা যাতে পেজ রিফ্রেশে সেশন না হারায়
  if (firebaseInitializationError == null && kIsWeb) {
    try {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    } catch (error) {
      debugPrint('Unable to set web auth persistence: $error');
    }
  }

  // ডেভেলপমেন্ট এমুলেটর ব্যবহার করতে চাইলে (DevConfig থেকে কন্ট্রোল)
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

  // Hive লোকাল স্টোরেজ ইনিশিয়ালাইজ (ক্যাশিং ও অফলাইন ডেটার জন্য)
  await Hive.initFlutter();

  // GetIt DI কনটেইনার সেটআপ — সব ডিপেন্ডেন্সি রেজিস্টার করা হয়
  await setupLocator();

  // অ্যাপ সেটিংস লোড ইভেন্ট পাঠানো (থিম, ভাষা ইত্যাদি)
  GetIt.I<SettingsBloc>().add(const LoadAppSettings());

  // অ্যাপ রান করা
  runApp(MyApp(firebaseInitializationError: firebaseInitializationError));
}

/// মূল অ্যাপ্লিকেশন উইজেট।
/// Firebase এরর থাকলে এরর স্ক্রিন, নইলে পুরো ERP অ্যাপ চালু করে।
class MyApp extends StatelessWidget {
  const MyApp({super.key, this.firebaseInitializationError});

  /// Firebase ইনিশিয়ালাইজেশন ব্যর্থ হলে এরর মেসেজ এখানে থাকে
  final String? firebaseInitializationError;

  @override
  Widget build(BuildContext context) {
    // Firebase ব্যর্থ হলে শুধু এরর দেখানোর জন্য সাধারণ MaterialApp
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

    // সফল কেসে AuthBloc ও SettingsBloc প্রোভাইড করে MaterialApp.router
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: GetIt.I<AuthBloc>()),
        BlocProvider.value(value: GetIt.I<SettingsBloc>()),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, _) {
          // বর্তমান ইউজার সেটিংস থেকে থিম/ভাষা/ফন্ট নেওয়া
          final settings = context.read<SettingsBloc>().currentAppSettings;
          return MaterialApp.router(
            title: AppConstants.appName,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: _themeMode(settings.themeMode),
            locale: _locale(settings.languageCode),
            // সমর্থিত ভাষা: ইংরেজি, বাংলা, চীনা
            supportedLocales: const [Locale('en'), Locale('bn'), Locale('zh')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            // ফন্ট সাইজ অনুযায়ী টেক্সট স্কেল
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(_textScale(settings.fontSize)),
              ),
              child: child ?? const SizedBox.shrink(),
            ),
            // GoRouter দিয়ে নেভিগেশন
            routerConfig: AppRoutes.router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }

  /// স্ট্রিং ভ্যালু থেকে ThemeMode নির্ধারণ
  ThemeMode _themeMode(String value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  /// ভাষা কোড থেকে Locale অবজেক্ট তৈরি
  Locale _locale(String languageCode) => switch (languageCode) {
    'bn' => const Locale('bn'),
    'zh' => const Locale('zh'),
    _ => const Locale('en'),
  };

  /// ফন্ট সাইজ স্ট্রিং থেকে টেক্সট স্কেল ফ্যাক্টর
  double _textScale(String value) => switch (value) {
    'small' => 0.9,
    'large' => 1.15,
    _ => 1,
  };
}
