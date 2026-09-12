# Footwear ERP System

Production management software for footwear manufacturing.

## Tech Stack

- Flutter (web and mobile)
- Firebase Authentication, Firestore, and Storage
- BLoC and GetIt
- GoRouter
- Clean Architecture

## Features

- Authentication with role-based access
- Master LC management
- Multi-line Purchase Orders with validation
- PO-driven Cutting with detail view
- Admin user, role, and permission management
- Colorful dashboard and module navigation

## Quick Start

### Prerequisites

- Flutter 3.41+
- Node.js 18+
- Firebase CLI 13+

### Setup

```bash
git clone https://github.com/MdEnamulHaque007/footwear-erp.git
cd footwear-erp
flutter pub get
flutterfire configure
flutter run -d chrome
```

Configure Firebase Authentication and Firestore for the target project before
running the application. Platform-specific credentials such as
`google-services.json` and `GoogleService-Info.plist` are intentionally
gitignored.

## Project Structure

```text
lib/
├── core/          # Constants, theme, utilities, and services
├── data/          # Models and repositories
├── domain/        # Entities and use cases
├── presentation/  # BLoCs, screens, widgets, and routes
└── injection/     # GetIt dependency registration
```

## Development

```bash
flutter pub get
flutter analyze
flutter test
```

## Security

Firestore rules and role-based access control are included. Do not commit
environment files, service-account keys, platform Firebase credential files, or
signing keys.

## Contact

[Md Enamul Haque](https://github.com/MdEnamulHaque007)
