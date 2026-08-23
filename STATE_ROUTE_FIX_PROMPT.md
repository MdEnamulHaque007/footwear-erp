# Fix Prompt — Footwear ERP: State Management + Route Management

> Paste everything below (from "You are working on…") into your coding agent. It is self-contained. This prompt is scoped to the **state-management ↔ routing wiring** only (not the full data-layer build-out of the stub modules).

---

You are working on a **Flutter** footwear/garment ERP.
- **State management:** `flutter_bloc`, with every BLoC/Cubit created through `get_it` (a `GetIt` service locator configured in `lib/injection/dependency_injection.dart`).
- **Navigation:** `go_router` — a single router in `lib/presentation/routes/app_routes.dart`, consumed by `MaterialApp.router` in `lib/main.dart`.
- **Auth-driven redirects:** `RouteGuard.redirect` + a `GoRouterRefreshStream` that bridges `AuthBloc`'s state stream into a `Listenable`. `AuthBloc` is provided app-wide by a `MultiBlocProvider` in `main.dart`.

## The problem
Opening the **Master LC** and **Purchase Order** pages throws `ProviderNotFoundException` — i.e. the state management is not correctly wired into the routes. The root cause is a mismatch between how a screen obtains its BLoC and how the router builds that screen.

### Exact diagnosis (already audited — trust this)
There are three ways a BLoC is made available in this codebase, and two of them are used correctly:
- **(A) Route-level provider** — the `GoRoute` wraps the screen: `BlocProvider(create: (_) => GetIt.I<XBloc>(), child: const XScreen())`. Used correctly by `/master-lc/new`, `/purchase-orders/new`, `/admin/users`, `/admin/roles`, `/admin/roles/create`.
- **(B) Screen-level self-provide** — the screen wraps its own body in `BlocProvider(create: (_) => GetIt.I<XBloc>())`. Used by `AdminDashboardScreen` (route `/admin`).
- **Global** — `AuthBloc` is provided once in `main.dart`, so all auth screens (`login`, `register`, `reset-password`, `splash`) work.

**The bug:** exactly two routes build a BLoC-consuming screen with NEITHER (A) nor (B):
```dart
GoRoute(path: '/master-lc',       builder: (_, _) => const MasterLCListScreen()),   // ❌ no provider
GoRoute(path: '/purchase-orders', builder: (_, _) => const POListScreen()),         // ❌ no provider
```
But `MasterLCListScreen` calls `context.read<MasterLCBloc>()` in `initState` and uses `BlocConsumer<MasterLCBloc, …>`; `POListScreen` does the same with `POBloc`. With no provider ancestor, Flutter throws `ProviderNotFoundException` the instant the page builds.

These are the **only two broken routes** — an audit of every `context.read/watch<…>` and `Bloc(Builder|Consumer|Listener)<…>` in `lib/presentation/screens/` confirms all other BLoC-consuming screens are correctly provided, and the 5 stub screens (Cutting/Sewing/Production/Issue/Export) plus the detail/dashboard screens do not consume a BLoC yet.

---

## Phase 1 — Fix the actual crash
In `lib/presentation/routes/app_routes.dart`, wrap both routes using pattern (A). `MasterLCBloc` and `POBloc` are already registered as factories in `dependency_injection.dart`, so **no DI change is needed**.

Change:
```dart
GoRoute(path: '/master-lc',       builder: (_, _) => const MasterLCListScreen()),
GoRoute(path: '/purchase-orders', builder: (_, _) => const POListScreen()),
```
to:
```dart
GoRoute(
  path: '/master-lc',
  builder: (_, _) => BlocProvider(
    create: (_) => GetIt.I<MasterLCBloc>(),
    child: const MasterLCListScreen(),
  ),
),
GoRoute(
  path: '/purchase-orders',
  builder: (_, _) => BlocProvider(
    create: (_) => GetIt.I<POBloc>(),
    child: const POListScreen(),
  ),
),
```
`flutter_bloc`, `get_it`, `MasterLCBloc`, and `POBloc` are already imported in `app_routes.dart`. After this change, both pages load (spinner → data or empty state).

---

## Phase 2 — Make the state/route wiring consistent so this class of bug can't recur
1. **Standardize on ONE convention.** Recommended: route-level provider (A) for all feature routes. Either migrate `AdminDashboardScreen`'s self-provide (B) to its `/admin` route for consistency, or explicitly document (B) as the standard — just be consistent across the app.
2. **Centralize all route paths in `RouteConstants`.** Today only `dashboard`, `login`, `register`, `resetPassword` are constants; the rest are hardcoded strings (`'/master-lc'`, `'/purchase-orders'`, `'/cutting'`, `'/admin/users'`, …). Add a constant for every route, use them in `app_routes.dart`, and use them in every `context.go(...)` / `context.push(...)` call. This kills typo-driven navigation bugs.
3. **Remove the duplicate dashboard route.** Both `RouteConstants.dashboard` (`'/'`) and `'/dashboard'` map to `DashboardScreen`. Keep one; if `'/dashboard'` must stay, make it redirect to `'/'`.
4. **Delete dead routing code.** `lib/presentation/routes/route_generator.dart` defines `onGenerateRoute` that always `return null;` — it's a leftover from Navigator 1.0 and is unused (routing is entirely `go_router`). Remove the file and any references.
5. **Pre-empt the stub-module routes.** `/cutting`, `/sewing`, `/production`, `/issue`, `/export` currently build placeholder screens that don't use a BLoC, so they don't crash. When those modules are implemented, their list screens WILL consume a BLoC — at that point (a) register the real `Bloc` in `dependency_injection.dart`, then (b) wrap the route in `BlocProvider(create: (_) => GetIt.I<XBloc>())`. Add a `// TODO: wrap in BlocProvider once XBloc is implemented` comment on each of these routes now.
6. **`splash_screen.dart`** consumes `AuthBloc` but is not registered in the router (`initialLocation` is `'/'`). Either wire it as the initial route or remove it to avoid confusion.

---

## Enforce the convention (prevent recurrence)
Document this rule (README/CONTRIBUTING):
> Any screen that calls `context.read/watch<XBloc>()` or uses `BlocBuilder/BlocConsumer/BlocListener<XBloc>` MUST have `XBloc` provided by its `GoRoute` (via `BlocProvider` + `GetIt.I<XBloc>()`) or provide it itself. Never build such a screen bare in the router.

Add a guard test: for the BLoC-consuming feature screens, pump the screen through its route entry and assert it does **not** throw `ProviderNotFoundException`. At minimum add widget tests that pump `MasterLCListScreen` and `POListScreen` inside their `BlocProvider` and expect a `CircularProgressIndicator` (loading) rather than an exception.

## Verification (all must pass before done)
1. `flutter analyze` → **0** issues.
2. `flutter test` → existing tests pass + the new no-crash tests pass.
3. Manual: log in, then open **Master LC** and **Purchase Orders** → each loads with no red error screen (spinner → data or "No records"). Open Cutting/Sewing/Production/Issue/Export → placeholder pages show, no crash. Use in-app navigation links → they land on the correct pages.
4. Re-run the audit: `grep -rnE "context\.(read|watch)<|Bloc(Builder|Consumer|Listener)<" lib/presentation/screens/` and confirm every referenced BLoC is provided by that screen's route (pattern A), by the screen itself (pattern B), or globally (`AuthBloc`).

Report the list of changed files and the results of steps 1–4.
