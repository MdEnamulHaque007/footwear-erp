# Footwear ERP System

A Flutter web application scaffold organized around Clean Architecture.

## Structure

- `core/`: constants, utilities, theme, shared widgets, and services
- `data/`: models, repositories, and remote/local data sources
- `domain/`: entities, repository contracts, and use cases
- `presentation/`: BLoCs, screens, widgets, and GoRouter routes
- `injection/`: GetIt dependency registration

The default route currently renders the dashboard shell. Feature files are intentionally lightweight contracts ready for the Firebase/authentication implementation.

## Firebase setup

Firebase project credentials are environment-specific and are not committed to this repository. Configure the target project with FlutterFire, which creates `lib/firebase_options.dart`:

```text
flutterfire configure
```

Then update the bootstrap in `lib/main.dart` to pass `DefaultFirebaseOptions.currentPlatform` to `Firebase.initializeApp` when the generated options file is available. Android also needs the generated `android/app/google-services.json`; iOS and web require their platform-specific Firebase configuration.

## Development

```text
flutter pub get
dart analyze
flutter test
```

Run `dart run build_runner build` after adding JSON/Hive model annotations.
