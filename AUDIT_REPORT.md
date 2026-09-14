# Footwear ERP — Project Audit Report

**Date:** 2026-09-12
**Auditor:** Cline (automated code audit)
**Project:** `E:\footwear` — Flutter **web** application, Clean Architecture + Firebase
**Toolchain verified:** Flutter 3.41.6 (stable) · Dart 3.11.4
**Supersedes:** the 2026-08-22 audit (see §12 for what changed)

---

## 1. Executive summary

This is a **working, analyzable Flutter application with a solid skeleton and two fully
fleshed-out vertical slices**, but it is still **mid-build**: roughly a quarter of the
`lib/` tree is unreferenced (dead) code, about half of the runtime dependencies are
unused, several business rules required by the domain (the cut → sew → produce → issue
quantity chain) are only partially enforced, and the **Firestore security rules still
allow self-service privilege escalation**.

The good news: `flutter analyze` is **completely clean**, all **26 tests pass**, git is in
a clean, fully-committed state, and the Master LC / Purchase Order modules are genuinely
complete (entity → model → repo → use cases → BLoC → screens → routes → DI).

| Dimension | Verdict |
|---|---|
| Builds & analyzes | ✅ Clean — `flutter analyze` → **No issues found** (223 files, 23.3 s) |
| Tests | 🟡 26 tests, **all pass** — but coverage is thin and misses the bug classes the project already hit |
| Architecture | 🟡 Clean layering and consistent patterns; a few convention splits remain |
| Feature completeness | 🟡 Master LC + PO complete; Cutting/Sewing/Production/Issue functional but shallow; Export/Reports/Audit Log are stubs or absent |
| **Security (Firestore rules)** | 🔴 **Privilege escalation still open** — fix before any real data |
| Business-rule correctness | 🔴 Quantity-chain validation is bypassable on create (over-allocation) and missing entirely on update |
| Dead code | 🟡 **62 of 223 files (28%) never imported** |
| Dependency hygiene | 🔴 ~20 of 24 runtime deps unused (2 of them "used" only by dead files) |
| Dev-only backdoor | 🟠 Debug builds auto-login as a hardcoded **admin** with full permissions |
| CI | 🔴 None |

**Top priority:** close the privilege-escalation hole in [firestore.rules](firestore.rules)
(§4), then fix the quantity-chain validation (§5) — those are the two issues that turn
into real-world losses (unauthorised admin, and over-production against a PO).

---

## 2. Scope & method

- Read the full `lib/` tree (223 hand-written `.dart` files), `firestore.rules`,
  `firestore.indexes.json`, `firebase.json`, `.firebaserc`, `pubspec.yaml`,
  `analysis_options.yaml`, `.gitignore`, `test/`, and the platform folders' config.
- Ran, and report the raw results of:
  - `flutter --version` → 3.41.6 / Dart 3.11.4
  - `flutter analyze --no-pub` → **No issues found! (ran in 23.3s)**
  - `flutter test` → **26 tests, All tests passed!**
  - `git status` / `git ls-files` → clean tree, 365 tracked files, HEAD `0d82bc3`
- Cross-checked imports, route provisioning, DI registrations, Firestore field names,
  and index coverage by static analysis of the source (not inferred).

---

## 3. Codebase metrics

| Metric | Value |
|---|---|
| Hand-written `.dart` files in `lib/` | **223** |
| Total source size | ~359 KB |
| Largest file | [po_form_screen.dart](lib/presentation/screens/purchase_order/po_form_screen.dart) (16 KB) |
| `*.g.dart` generated files | **0** (the fake ones from the previous audit are gone) |
| Files never imported anywhere | **62 (28%)** — ~18 KB |
| `domain/usecases/*` classes | 53 |
| Tests | 4 files / **26 tests** (all passing) |
| `flutter analyze` | **0 issues** |
| Runtime deps declared / actually imported | 24 / **12** |
| CI configuration | **none** (`.github/` does not exist) |

---

## 4. Security findings

File: [firestore.rules](firestore.rules)

### 🔴 HIGH-1 — Privilege escalation via unrestricted user-document creation (STILL OPEN)
```firestore
match /users/{userId} {
  allow create: if signedIn() && request.auth.uid == userId;   // line 21 — no content validation
```
The create rule only asserts *who* is writing, never *what* is written. Because the
`admin()` helper (line 14-18) trusts `users/{uid}.data.role`, any attacker who registers
a Firebase account can then write their own `users/{uid}` document directly through the
REST/SDK API with `role: "admin"` (and/or a fully-permissive `permissions` map) —
completely bypassing [auth_remote_datasource.dart:43-58](lib/data/datasources/remote/auth_remote_datasource.dart),
which is the only place the client sets `role: viewer`. They are then an admin
permanently, in the UI *and* in the rules.

**Fix (required before real data):** constrain the create payload, e.g.
```firestore
allow create: if signedIn()
  && request.auth.uid == userId
  && request.resource.data.role == 'viewer'
  && request.resource.data.isActive == true
  && request.resource.data.permissions == {};
```
and move all role/permission writes to an admin-only path (or Firebase custom claims).

### 🔴 HIGH-2 — No role/permission enforcement on business collections
```firestore
match /{collection}/{documentId} {
  allow read, write: if activeUser() && collection in [ ... ];   // lines 40-51
```
Any *active* user — including a `viewer` whose `permissions` map is empty — can create,
update and **delete** Master LC, PO, Cutting, Sewing, Production and Issue records.
The client enforces permissions with `UserEntity.hasPermission()`
([user_entity.dart:24-27](lib/domain/entities/user_entity.dart)) and
[permission_utils.dart](lib/core/utils/permission_utils.dart), but the server does not,
so the client-side check is cosmetic. Rule-level checks against the user's `permissions`
map (or custom claims) are needed.

### 🟡 MEDIUM-3 — No write-content validation, no App Check
No rule validates document shape, field types, numeric ranges, foreign keys or
ownership on write. For a quantity-driven ERP this pushes **all** data integrity onto
client code — and §5 shows that client validation is itself incomplete. There is also no
Firebase **App Check**, so the public web API key combined with HIGH-1/HIGH-2 is a
remotely-exploitable surface.

### 🟡 MEDIUM-4 — `audit_logs` is not immutable
```firestore
match /audit_logs/{logId} {
  allow create: if activeUser();
  allow read, update, delete: if admin();   // lines 35-38
```
An audit log that admins can update/delete is not an audit log. Make it create-only
(`allow update, delete: if false`). Note also that no audit-log writer exists in the app:
`AppConstants.collectionAuditLog = 'audit_logs'` (line 12) vs
`AppConstants.moduleAuditLog = 'audit_log'` (line 36) — a latent key mismatch.

### ✅ Fixed since the previous audit
The catch-all `match /{collection}/{documentId}` no longer lists `users`, `roles` or
`audit_logs`, so the earlier "access-widening" finding is closed.

### 🟠 HIGH-5 — Debug backdoor authenticates as a hardcoded admin
- [dev_config.dart:9-11](lib/core/config/dev_config.dart) — `enabled => kDebugMode`,
  `autoLogin = true`.
- [dev_config.dart:14-54](lib/core/config/dev_config.dart) — `devUser` is `role: 'admin'`
  with `view/create/edit/delete = true` for **every** module.
- [auth_bloc.dart:79-82](lib/presentation/blocs/auth/auth_bloc.dart) — when auto-login is
  enabled, a failed/missing auth check **falls back to the dev admin** rather than failing.
- [login_screen.dart:79-87](lib/presentation/screens/auth/login_screen.dart) — a
  "Skip login (dev)" button grants the same full-admin session.

Because `kDebugMode` is compile-time `false` in release builds, this does not ship to
production — but **every debug/staging/profile build is a full-admin bypass with no
password**, and the auto-login fallback masks real auth misconfiguration during QA.

### 🟡 Config — committed Firebase options contradict the README
[firebase_options.dart:23-30](lib/firebase_options.dart) contains live values for project
`footwear-9d10e` and **is tracked in git** (`git ls-files` confirms), while the README
states that platform credentials "are intentionally gitignored". For Flutter web the API
key is public by design, so this is not a secret leak — but the intent mismatch should be
resolved, and everything must still be locked down by the rules above (which currently
are not). `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist`
are correctly absent/gitignored.

---

## 5. Correctness & business-logic findings

The domain is a chain: **PO → Cutting → Sewing → Production → Issue → Export**. Each stage
must consume no more than the previous stage produced. Several links in that rule are
enforced; several are not.

### 🔴 HIGH-6 — Update paths skip validation entirely (Cutting / Sewing / Production)
```dart
// lib/domain/usecases/cutting/update_cutting_usecase.dart
Future<Either<String, void>> call(CuttingEntity item) => _repository.update(item);
```
Same shape in [update_sewing_usecase.dart](lib/domain/usecases/sewing/update_sewing_usecase.dart)
and [update_production_usecase.dart](lib/domain/usecases/production/update_production_usecase.dart).
Only [update_issue_usecase.dart](lib/domain/usecases/issue/update_issue_usecase.dart) calls
`validateUpdate(...)`. So a record that passes validation on create can be **edited to any
quantity afterwards**, with no cumulative check at all. `ValidateCuttingQuantityUseCase`
already accepts an `excludingId` for exactly this case
([validate_cutting_quantity_usecase.dart:14](lib/domain/usecases/cutting/validate_cutting_quantity_usecase.dart)) —
it is simply never used by the update path.

### 🔴 HIGH-7 — Cumulative limits compare a single record against the whole of the previous stage
```dart
// lib/domain/usecases/sewing/create_sewing_usecase.dart
final error = await _validate(
  poTagNo: item.poTagNo,
  sewingDate: item.sewingDate,
  candidateQuantity: item.quantity,   // `alreadySewn` is NOT passed → defaults to 0
);
```
`ValidateSewingQuantityUseCase` computes
`alreadySewn + candidateQuantity > cumulativeCutting`
([validate_sewing_quantity_usecase.dart:21](lib/domain/usecases/sewing/validate_sewing_quantity_usecase.dart)),
but `alreadySewn` defaults to `0` and is **never supplied** by the create use case. The
same is true for `alreadyProduced`
([create_production_usecase.dart:12-16](lib/domain/usecases/production/create_production_usecase.dart))
and `alreadyIssued`
([create_issue_usecase.dart:12-16](lib/domain/usecases/issue/create_issue_usecase.dart)).

Net effect: if Cutting produced 100 units, a user can create **five** Sewing vouchers of
100 each and every one passes. The rule only holds if each stage is entered exactly once.
Only the Cutting create path is correct, because `ValidateCuttingQuantityUseCase`
re-queries the cumulative total for the same PO line
([validate_cutting_quantity_usecase.dart:19-25](lib/domain/usecases/cutting/validate_cutting_quantity_usecase.dart)).

**Fix:** pass the already-recorded cumulative for the *same* stage (excluding the record
being edited) into every `Validate*QuantityUseCase` call, mirroring
`ValidateIssueQuantityUseCase.validateUpdate`
([validate_issue_quantity_usecase.dart:38-62](lib/domain/usecases/issue/validate_issue_quantity_usecase.dart)),
which is the correct pattern already in the codebase.

### 🟠 HIGH-8 — Cumulative repository getters throw, and two BLoCs don't catch
The cumulative getters are the only repository methods that do **not** use the
`Either<String, T>` convention — they return a raw `Future<int>` and let
`FirebaseException` propagate:

- [cutting_repository.dart:198-210 and 213-236](lib/data/repositories/cutting_repository.dart)
- [production_repository.dart:97-113](lib/data/repositories/production_repository.dart)
- [issue_repository.dart:97-114](lib/data/repositories/issue_repository.dart)
- `SewingRepository.getCumulativeSewingQuantity` (same shape)

`ValidateSewingQuantityUseCase.call` and `ValidateProductionQuantityUseCase.call` do not
guard those awaits, and the event handlers `SewingBloc.on<CreateSewing>`
([sewing_bloc.dart:47-55](lib/presentation/blocs/sewing/sewing_bloc.dart)),
`on<UpdateSewing>`, `ProductionBloc.on<CreateProduction>`
([production_bloc.dart:47-55](lib/presentation/blocs/production/production_bloc.dart)) and
`on<UpdateProduction>` have **no try/catch**. A Firestore error (offline, permission
denied, missing index) therefore becomes an uncaught async error and the screen stays
stuck on its loading spinner forever. `ValidateIssueQuantityUseCase` *does* wrap its call
in `on Exception`
([validate_issue_quantity_usecase.dart:32-34, 59-61](lib/domain/usecases/issue/validate_issue_quantity_usecase.dart)) —
so the handling is inconsistent even within the same feature family.

### 🟡 MEDIUM-9 — Mutable pagination cursor on `registerLazySingleton` repositories
```dart
DocumentSnapshot<Map<String, dynamic>>? _lastDoc;   // instance field
```
[master_lc_repository.dart:16](lib/data/repositories/master_lc_repository.dart) (and the
same pattern in the PO, Cutting, Sewing, Production and Issue repositories) stores the
keyset cursor on a **singleton**. Every screen and BLoC shares one cursor, so two
concurrent list loads — e.g. a list screen plus a detail screen, or two open browser tabs
on Flutter web — can read from each other's position and skip or repeat rows. The cursor
belongs in the BLoC state, or the repositories should be factories.

### 🟡 MEDIUM-10 — Validation ordering and negative "available" messages
In `ValidateSewingQuantityUseCase` and `ValidateProductionQuantityUseCase` the database
call happens **before** the `candidateQuantity <= 0` guard
([validate_sewing_quantity_usecase.dart:16-20](lib/domain/usecases/sewing/validate_sewing_quantity_usecase.dart)),
so invalid input still costs a Firestore read and the zero-quantity message differs
between modules. The messages also interpolate `cumulative - alreadyRecorded`, which goes
negative once a stage is over its limit. And `ValidatePOQuantityUseCase` has **no sign
guard at all** — the test suite documents that as intended behaviour
([validate_po_quantity_test.dart:90-100](test/unit/validate_po_quantity_test.dart) asserts a
`-5` quantity is accepted).

### 🟡 MEDIUM-11 — Duplicated / denormalised Firestore fields
`CuttingModel` persists **both** `tagNo` and `poTagNo`, and **both** `quantity` and
`cuttingQuantity`, each with read-time fallbacks
([cutting_model.dart:45-87](lib/data/models/cutting/cutting_model.dart)). Two cumulative
methods read `quantity`
([cutting_repository.dart:208](lib/data/repositories/cutting_repository.dart)) while a third
reads `cuttingQuantity ?? quantity`
([cutting_repository.dart:231-233](lib/data/repositories/cutting_repository.dart)) — i.e. the
same quantity is queried under two different field names. This works today only because
`CuttingEntity`'s constructor aliases them
([cutting_entity.dart:20-21](lib/domain/entities/cutting_entity.dart)); it is a latent
source of "right in the UI, wrong in the validation" bugs. `POModel` has the same
`poQuantity ?? quantity` fallback.

### 🟡 LOW-12 — Form-level gaps in Cutting / Sewing / Production / Issue
- Voucher numbers are **typed by hand** in every form, yet `AppConstants` defines
  `cuttingVoucherPrefix`/`sewingVoucherPrefix`/… and nothing generates or uniqueness-checks
  them → duplicate voucher numbers are possible. The originally specified
  `generate_voucher_no` use case does not exist.
- Sewing/Production/Issue forms use `DateTime.now()` with no date picker and set
  `entryPerson: ''`
  ([sewing_form_screen.dart:63-71](lib/presentation/screens/sewing/sewing_form_screen.dart)).
- Those forms pop the route **immediately** after dispatching create
  ([sewing_form_screen.dart:74](lib/presentation/screens/sewing/sewing_form_screen.dart)), so a
  validation error surfaces on the list screen after navigation instead of on the form.
- `sl` is `DateTime.now().millisecondsSinceEpoch` and lists are `orderBy('sl')`, so ordering
  depends on clock skew rather than a stored sequence number.

### 🟡 LOW-13 — Raw exceptions across layers in the Cutting detail screen
`CuttingDetailScreen._load` throws `Exception(error)` out of an `Either.fold` to feed a
`FutureBuilder`
([cutting_detail_screen.dart:28, 37](lib/presentation/screens/cutting/cutting_detail_screen.dart)).
It is contained, but it breaks the project's own "no exceptions across layers" rule and
discards the specific error message.

### ✅ Verified NOT a bug
`DateFormat('dd/MM/yyyy', 'en_US')` is used in
[dashboard_screen.dart:187-193](lib/presentation/screens/dashboard/dashboard_screen.dart)
without `initializeDateFormatting`. This works — I verified it with a throwaway test
against the actual `intl 0.18.1` dependency (`en_US` is the built-in default locale) — so
no change is needed.

---

## 6. Architecture & consistency

**Good:** clean `core / data / domain / presentation / injection` layering, `dartz`
`Either` for most repository calls, GetIt DI, BLoC per feature, `go_router` with a single
router, a central `RouteGuard`, and consistent naming across the four implemented modules.
[AuthBloc](lib/presentation/blocs/auth/auth_bloc.dart) correctly disposes its
`authStateChanges` subscription (lines 171-174).

**Inconsistencies:**

1. **Three different ways to supply a BLoC.**
   - Route-level `BlocProvider` — the majority (correct).
   - Screen self-provides — [admin_dashboard_screen.dart:15](lib/presentation/screens/admin/admin_dashboard_screen.dart).
   - `BlocProvider.value(GetIt.I<RoleManagementBloc>())` for `/admin/roles/create`
     ([app_routes.dart:255-258](lib/presentation/routes/app_routes.dart)). Because
     `RoleManagementBloc` is registered with `registerFactory`, `GetIt.I<>()` builds a
     **new** instance that is never disposed by a `value` provider, and it starts with no
     roles loaded. Pick one convention (route-level `create:` is the safest).

2. **Route strings are not centralised.**
   [route_constants.dart](lib/presentation/routes/route_constants.dart) holds only
   `dashboard`, `login`, `register`, `resetPassword`; every other path is a hardcoded
   literal in [app_routes.dart](lib/presentation/routes/app_routes.dart), the drawer and the
   screens. `AppConstants` duplicates four of them (`authSplash`, `authLogin`,
   `authRegister`, `authResetPassword`, `dashboardRoute`) — two sources of truth.

3. **Dead links to unbuilt modules.** The dashboard and drawer navigate to routes that do
   not exist, so users hit the `errorBuilder` "Page not found" screen:
   - `/export` — [dashboard_screen.dart:111-117](lib/presentation/screens/dashboard/dashboard_screen.dart),
     [app_drawer.dart:56-61](lib/presentation/widgets/app_drawer.dart)
   - `/reports` — [app_drawer.dart:85](lib/presentation/widgets/app_drawer.dart)
   - `/audit-log` — [app_drawer.dart:86](lib/presentation/widgets/app_drawer.dart)

4. **Leftover/dead routing code.**
   - [route_generator.dart](lib/presentation/routes/route_generator.dart) — `RouteGenerator.onGenerateRoute`
     always returns `null`; never referenced (Navigator 1.0 leftover).
   - [splash_screen.dart](lib/presentation/screens/auth/splash_screen.dart) — a working screen that
     is not registered in the router (`initialLocation` is `/`); dead.
   - `GoRoute(path: '/dashboard', redirect: ...)` is still duplicated alongside
     `RouteConstants.dashboard` ([app_routes.dart:57](lib/presentation/routes/app_routes.dart)).

5. **Stub / absent modules.** Export has no entity, model, repository, use case, BLoC or
   screen (only `AppConstants.collectionExport`, `moduleExport` and rules entries). Reports
   is a `Cubit<int>` ([report_bloc.dart:3-4](lib/presentation/blocs/report/report_bloc.dart))
   plus static `Text` screens, unrouted. Audit Log is constants + rules only. The
   Permission Matrix screen renders non-interactive placeholder checkboxes
   ([permission_matrix_screen.dart:19-30](lib/presentation/screens/role_management/permission_matrix_screen.dart)).

6. **Small style issues.** [main.dart:51-52](lib/main.dart) wraps a single provider in
   `MultiBlocProvider`; [auth_bloc.dart:111-121](lib/presentation/blocs/auth/auth_bloc.dart)
   has inconsistent indentation inside `_onLogin`; the
   `// ✅ FIXED: Admin permissions added for all modules` comment in
   [dev_config.dart:13](lib/core/config/dev_config.dart) is a leftover changelog note in
   source.

---

## 7. Dead code & dependency hygiene

### 62 of 223 `lib/` files (28%) are never imported

Verified by resolving every `import` target across `lib/`. The main clusters:

| Area | Dead files |
|---|---|
| `core/services/**` (Firebase auth/storage/cloud-functions, Hive, SharedPrefs, cache, notifications) | 8 |
| `core/widgets/**` (cards, common, forms, tables) | 14 |
| `core/utils/validators`, `formatters`, `helpers`, `extensions`, `constants` | 12 |
| `presentation/screens/report/**` (+ `blocs/report/*`) | 8 |
| `screens/user_management/{user_form,user_edit,role_management}_screen.dart`, `role_management/role_edit_screen.dart` | 4 |
| `screens/dashboard/{config, widgets/*}` | 5 |
| `screens/{master_lc,purchase_order}/widgets/*_card.dart` | 2 |
| `widgets/{empty_state,permission_checkbox_widget,status_badge}.dart` | 3 |
| `routes/route_generator.dart`, `screens/auth/splash_screen.dart` | 2 |
| `domain/usecases/role/{assign_permission_to_role,check_permission}_usecase.dart` | 2 |
| misc | 2 |

Dead code is not free: it inflates review surface, and two of the dead files are what make
`firebase_storage` and `shared_preferences` look "used".

### Dependencies: only 12 of 24 runtime packages are actually imported

Imported (by count of import sites): `flutter` (74), `dartz` (58), `flutter_bloc` (37),
`go_router` (21), `cloud_firestore` (19), `intl` (9), `get_it` (6), `firebase_auth` (5),
`hive_flutter` (2), `firebase_core` (2), plus `firebase_storage` (1) and
`shared_preferences` (1) **which only appear inside dead files** and are therefore
effectively unused.

**Declared but never imported anywhere:** `cupertino_icons`, `firebase_messaging`,
`equatable`, `dio`, `retrofit`, `json_annotation`, `freezed_annotation`, `timezone`,
`flutter_screenutil`, `responsive_builder`, `flutter_svg`, `formz`, `excel`, `pdf`,
`printing`, `fl_chart`, `flutter_local_notifications`, `connectivity_plus`, `image_picker`,
`url_launcher`.

**Dev dependencies with nothing to generate:** `build_runner`, `json_serializable`,
`freezed`, `hive_generator`, `retrofit_generator` — there are **no** `@JsonSerializable`,
`@freezed` or `@HiveType` annotations and **no `.g.dart` files** anywhere. The previous
audit's "fake generated files" are gone, but the codegen toolchain was left in place.

Several majors are also behind what is already in the local pub cache (`intl ^0.18.1` while
`0.20.2` is downloaded; also `go_router ^12.x`, `fl_chart ^0.66`, `freezed ^2.x`,
`flutter_local_notifications ^15.x`). Run `flutter pub outdated` and bump deliberately.

---

## 8. Testing & CI

- 4 test files / **26 tests**, all passing:
  - [home_navigation_shell_test.dart](test/home_navigation_shell_test.dart) — 15 widget tests
    proving the "Home" control returns from deep links (good regression coverage).
  - [validate_po_quantity_test.dart](test/unit/validate_po_quantity_test.dart) — 6 unit tests,
    including one that **encodes the missing negative-quantity guard as expected behaviour**.
  - [validate_issue_quantity_test.dart](test/unit/validate_issue_quantity_test.dart) — 3 unit tests.
  - [widget_test.dart](test/widget_test.dart) — 1 test for `AuthValidator`.
- **Gaps that matter:** no BLoC tests; no widget test that pumps a list screen through its
  `GoRoute` to prove the `BlocProvider` wiring (exactly the `ProviderNotFoundException`
  class of bug this project already hit); no repository tests against `FakeFirebaseFirestore`;
  no tests for the cumulative chain rules (HIGH-6/HIGH-7); and no `firestore.rules` tests
  (the emulator suite is not set up).
- **No CI:** `.github/` does not exist, so nothing enforces `flutter analyze` / `flutter test`
  even though the README documents both.

---

## 9. Prioritized remediation plan

**P0 — Security (before any real/production data)**
1. Close HIGH-1: reject client-set `role`/`permissions` at user-document creation; move
   privilege writes to an admin-only path or Firebase custom claims.
2. Enforce HIGH-2: check the caller's `permissions` map (or claims) in the business-collection
   rules instead of `activeUser()` alone.
3. Make `audit_logs` create-only; add write-content validation; enable **App Check**;
   reconcile `audit_log` / `audit_logs`.
4. Make the debug backdoor explicit and safe: default `DevConfig.autoLogin` to `false`, never
   fall back to the dev admin on an auth error, and gate the skip button behind an
   environment flag rather than `kDebugMode`.

**P1 — Business-rule correctness**
5. Fix HIGH-7: pass the already-recorded cumulative (same stage, excluding the edited record)
   into `CreateSewing/Production/Issue` — copy the `validateUpdate` pattern.
6. Fix HIGH-6: route `UpdateCutting/UpdateSewing/UpdateProduction` through their validators
   (Cutting's `excludingId` support is already there).
7. Fix HIGH-8: return `Either` from the cumulative repository getters (or wrap them with
   `RepositoryGuard`) and add try/catch to the sewing/production create/update handlers.
8. Move the `candidateQuantity <= 0` guard before the network call in every validator; add
   the missing sign guard to `ValidatePOQuantityUseCase` and update its test.
9. Move the pagination cursor out of the singleton repositories.

**P2 — Dead code, navigation, dependencies**
10. Delete the 62 unreferenced files (or start using the good ones — `LoadingWidget`,
    `EmptyState`, `StatusBadge`, `CustomTextField` etc. are reasonable to adopt), and remove
    `route_generator.dart` + `splash_screen.dart`.
11. Centralise every route in `RouteConstants`, use it everywhere, and drop both the
    duplicate `/dashboard` route and the duplicated constants in `AppConstants`.
12. Remove or implement the `/export`, `/reports` and `/audit-log` links so navigation never
    reaches "Page not found".
13. Prune the ~20 unused runtime deps and the 5 unused codegen dev deps; then run
    `flutter pub outdated` and bump majors.

**P3 — Quality gates**
14. Add tests for the cumulative chain rules, one BLoC test per module, and a route-level
    widget test per list screen.
15. Add a CI workflow running `flutter analyze` and `flutter test` on push/PR.

---

## 10. Bottom line

This has moved a long way from the previous audit's "architectural scaffold": it now
**analyzes cleanly, builds, and passes 26 tests**, Master LC and PO are complete vertical
slices, and Cutting/Sewing/Production/Issue are functional module-by-module (entity, model,
repository, use cases, BLoC, screens, routes, DI). The remaining work is concentrated, not
diffuse: **two rule files' worth of authorization**, **three use-case wiring bugs in the
quantity chain**, **one debug backdoor**, and a cleanup pass over 62 dead files and ~25
unused packages. Fix the authorization rules and the chain validation first — those are the
findings that cause real loss — then do the cleanup, which is mechanical and low-risk.

---

## 11. Changes since the 2026-08-22 audit

| Prior finding | Status now |
|---|---|
| Firestore rules: privilege escalation on `users` create (HIGH-1) | ❌ **Still open** (§4 HIGH-1) |
| Firestore rules: `users`/`roles`/`audit_logs` in the catch-all (HIGH-2) | ✅ Fixed — removed from the catch-all |
| `audit_logs` mutable | ❌ Still open |
| No write-content validation / no App Check | ❌ Still open |
| 54 one-line stubs + 86 files ≤ 3 lines | ✅ Resolved — those files are gone; 62 files remain *unreferenced* but are real code |
| 10 fake `.g.dart` "generated" files | ✅ Removed — zero `.g.dart` files now |
| ~20 of 24 deps unused | ❌ Unchanged (now 20 of 24 unused + 5 dead codegen dev deps) |
| Duplicate `/dashboard` route | ❌ Still present |
| `route_generator.dart` dead routing code | ❌ Still present |
| Unused `SplashScreen` | ❌ Still present (not routed) |
| One trivial test | ✅ Improved — 26 tests across 4 files, all passing |
| No CI | ❌ Still none |
| Cutting/Sewing/Production/Issue/Export unimplemented | 🟡 Mostly implemented — Export still absent, Reports/Audit Log still stubs |
| `ProviderNotFoundException` on Master LC / PO routes | ✅ Fixed — every BLoC-consuming screen is now provided by its route |

*Not carried over from the prior report (now verified as non-issues): the "24 declared /
~4 used" dependency count is now 12 used; the `audit_log`/`audit_logs` mismatch remains a
latent key mismatch but no writer exists yet, so it is not yet a live bug.*

