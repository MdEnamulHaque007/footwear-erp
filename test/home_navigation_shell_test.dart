/// ============================================================================
/// ফাইল: test/home_navigation_shell_test.dart
/// স্তর: Test | মডিউল: ERP Common
/// উদ্দেশ্য: Home Navigation Shell Test অংশের প্রত্যাশিত আচরণ স্বয়ংক্রিয়ভাবে যাচাই করে এবং regression প্রতিরোধ করে।
/// প্রধান অংশ: top-level configuration ও helper declarations
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:footwear/presentation/routes/home_navigation_shell.dart';
import 'package:footwear/presentation/routes/route_constants.dart';

void main() {
  GoRouter makeRouter(String initialLocation) => GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (_, state, child) =>
            HomeNavigationShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: RouteConstants.dashboard,
            builder: (_, _) => const Scaffold(body: Text('Dashboard')),
          ),
          GoRoute(
            path: '/:page',
            builder: (_, _) => const Scaffold(body: Text('Module')),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, _) => const Scaffold(body: Text('Form')),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (_, state) => HomeNavigationShell(
      location: state.uri.path,
      child: const Scaffold(body: Text('Not found')),
    ),
  );

  for (final path in [
    '/master-lc',
    '/purchase-orders',
    '/cutting',
    '/sewing',
    '/production',
    '/issue',
    '/admin',
    '/unauthorized',
    '/purchase-orders/new',
    '/missing/deep/link',
  ]) {
    testWidgets('Home returns from direct link $path', (tester) async {
      final router = makeRouter(path);
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(NavigationDestination, 'Home'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/');
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.widgetWithText(NavigationDestination, 'Home'), findsOneWidget);
    });
  }

  for (final path in ['/', '/login', '/register', '/reset-password']) {
    testWidgets('Bottom navigation visibility is correct on $path', (tester) async {
      final router = makeRouter(path);
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      final expected = path == '/' ? findsOneWidget : findsNothing;
      expect(find.widgetWithText(NavigationDestination, 'Home'), expected);
    });
  }

  testWidgets('Home clears pushed form navigation', (tester) async {
    final router = makeRouter('/purchase-orders');
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.push('/purchase-orders/new');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'Home'));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsOneWidget);
    expect(router.canPop(), isFalse);
  });
}
