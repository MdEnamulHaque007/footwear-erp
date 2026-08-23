# Footwear ERP — Project Audit Report

**Date:** 2026-08-22
**Auditor:** Claude Code (automated code audit)
**Project:** `E:\footwear` — Flutter **web** application, Clean Architecture + Firebase
**Toolchain verified:** Flutter 3.41.6 (stable) · Dart 3.11.4

---

## 1. Executive summary

This repository is an **early-stage architectural scaffold**, not a working ERP. It has a clean, professional folder structure and one genuinely functional vertical slice (authentication + a handful of CRUD screens wired to Firestore), but roughly a third of its source files are empty placeholders and most of its declared capabilities do not exist yet.

**Overall maturity: ~20–25% implemented.** The skeleton is sound; the flesh is mostly missing.

| Dimension | Verdict |
|---|---|
| Builds & analyzes | ✅ Clean — `dart analyze` = 0 errors (1 warning, 12 info lints) |
| Runs | ✅ Dev server serves at `http://localhost:8080`; app bootstraps, no console errors |
| Architecture | 🟡 Good layering, but **applied inconsistently** |
| Feature completeness | 🔴 ~1 of ~9 business modules actually implemented |
| **Security (Firestore rules)** | 🔴 **Privilege-escalation and access-widening flaws — fix before any real data** |
| Dependency hygiene | 🔴 ~20 of 24 major deps unused; 10 fake "generated" files |
| Testing | 🔴 One trivial test; effectively no coverage |

**Top priority:** the Firestore security rules contain a **privilege-escalation vulnerability** (§4). Address that before this project touches production data.

---

## 2. Scope & method

Examined the full `lib/` tree (253 hand-written `.dart` files), `firestore.rules`, `pubspec.yaml`/`.lock`, `analysis_options.yaml`, `.gitignore`, and `test/`. Ran `dart analyze` and launched the app via a Flutter web dev server to confirm it boots. Findings below cite `file:line` and are verified against the source, not inferred.

> Note: this working copy is **not a git repository** (no `.git`), so there is no version-control history or safety net here.

---

## 3. Codebase metrics

| Metric | Value |
|---|---|
| Hand-written `.dart` files (excl. generated) | 253 |
| Total hand-written LOC | ~3,650 (avg **~14 lines/file**) |
| One-line stub files (`class X {}` / empty) | **54** |
| Files ≤ 3 lines | **86 (~34% of all files)** |
| `.g.dart` "generated" files | 10 — **all fake placeholders** (see §6.3) |
| Major deps declared vs. imported anywhere | 24 declared / **~4 used** |
| Tests | 1 (trivial) |
| `dart analyze` | 0 errors · 1 warning · 12 info |

---

## 4. Security findings (Firestore rules) — highest priority

File: [firestore.rules](firestore.rules)

### 🔴 HIGH-1 — Privilege escalation via unrestricted user-document creation
```
match /users/{uid} {
  allow create: if signedIn() && request.auth.uid == uid;   // line 14 — NO field validation
  ...
}
```
The create rule only checks that a user creates *their own* document — it places **no constraint on the document's contents**. Because `isAdmin()` (line 6) trusts `users/{uid}.data.role`, any newly-registered user can create their own profile with `role: 'admin'` (or a fully-permissive `permissions` map) using the Firebase SDK/REST directly, bypassing the client code in [auth_remote_datasource.dart:43](lib/data/datasources/remote/auth_remote_datasource.dart) that sets `role: viewer`. They are then an admin permanently. The `update` rule (lines 15–19) correctly restricts later edits to `lastLogin` only — but the hole is at **creation**, so no later escalation is even needed.

**Fix:** forbid client-set privilege fields at creation — e.g. require `request.resource.data.role == 'viewer'` and that `permissions` is empty/absent — and manage roles/permissions exclusively via an admin-only path, a Cloud Function, or Firebase Auth **custom claims** (which also removes the per-request `get()` cost below).

### 🔴 HIGH-2 — Catch-all rule silently widens access to restricted collections
```
match /{collection}/{id} {           // lines 27–32
  allow read:   if hasPermission(collection, 'view');
  allow update: if hasPermission(collection, 'edit');
  allow delete: if hasPermission(collection, 'delete');
}
```
Firestore **OR-combines** every `match` block whose path matches a request. The generic block above matches `users`, `roles`, and `audit_logs` too, so it *adds* permission-based access on top of the specific, intentionally-narrow rules:
- A non-admin holding a generic `users.view` permission can read **every user's** profile (the specific rule intended self-or-admin only).
- Similarly `roles.view/edit/delete` reaches the admin-only `/roles` collection.
- **Audit-log integrity is broken:** the `/audit_logs` block (lines 23–26) deliberately omits update/delete, but the catch-all grants them to anyone with `audit_logs.edit`/`.delete`, so logs are **not immutable**.

**Fix:** exclude `users`, `roles`, and `audit_logs` from the catch-all (e.g. an explicit allow-list of business collections instead of `{collection}`), and make `audit_logs` create-only.

### 🟡 MEDIUM-3 — Permission-key naming inconsistency
Line 24 checks module `'audit_log'` (singular) while the catch-all uses the collection name `'audit_logs'` (plural, line 28). Whichever key the `permissions` map actually uses, one of the two rules silently never matches. Standardize the module keys against the collection names.

### 🟡 MEDIUM-4 — No write-content validation; no App Check
No rule validates document shape, quantities, foreign keys, or ownership on write. For a quantity-driven ERP (cutting → sewing → production → issue → export) all integrity currently depends on client code — most of which is unimplemented (§5). There is also no Firebase **App Check**, so a public web API key + HIGH-1 = a real, remotely-exploitable surface.

### ℹ️ INFO-5 — `get()` on every rule evaluation
`isAdmin()`/`hasPermission()` each `get()` the caller's user doc per evaluation → extra reads (billing) and latency on every request. Migrating role/permissions to **custom claims** eliminates this and closes HIGH-1 at the same time.

### 🟡 Config — committed Firebase options contradict the README
[firebase_options.dart:24-31](lib/firebase_options.dart) is present with real values for project `footwear-9d10e` and is **not** in [.gitignore](.gitignore), directly contradicting the README (“credentials … are not committed”). For Flutter **web** the API key is public-by-design (not a secret leak), but the intent mismatch should be resolved and the file's provenance made deliberate.

---

## 5. Feature completeness

Only a single vertical slice is wired end-to-end in [dependency_injection.dart](lib/injection/dependency_injection.dart) and backed by real code:

| Module | Entity | Model | Repo | Use cases | BLoC | Screens | DI-wired | Status |
|---|---|---|---|---|---|---|---|---|
| Auth | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **Working** |
| User management | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **Working** |
| Role management | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **Working** |
| Master LC | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **Working** |
| Purchase Order | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **Working** |
| Cutting | ✅ | ✅ | 🔴 `{}` | 🔴 stubs | 🔴 stub | ✅ screen | ❌ | **Placeholder** |
| Sewing | ✅ | ✅ | 🔴 `{}` | 🔴 stubs | 🔴 stub | ✅ screen | ❌ | **Placeholder** |
| Production | ✅ | ✅ | 🔴 `{}` | 🔴 stubs | 🔴 stub | ✅ screen | ❌ | **Placeholder** |
| Issue | ✅ | ✅ | 🔴 `{}` | 🔴 stubs | 🔴 stub | ✅ screen | ❌ | **Placeholder** |
| Export | ✅ | ✅ | 🔴 `{}` | 🔴 stubs | 🔴 stub | ✅ screen | ❌ | **Placeholder** |
| Audit log | ✅ | ✅ | 🔴 `{}` | 🔴 stubs | 🔴 stub | ✅ screen | ❌ | **Placeholder** |
| Dashboard | — | — | — | — | 🔴 stub | ✅ static shell | ❌ | **Shell only** |
| Report | — | — | — | — | 🔴 stub | ✅ screens | ❌ | **Placeholder** |

Example placeholder: [cutting_repository.dart](lib/data/repositories/cutting_repository.dart) is literally `class CuttingRepository {}`; the cutting/sewing/production/issue/export BLoC `*_event.dart` and `*_state.dart` files are 1 line each.

**Reachable dead ends:** the router exposes `/cutting`, `/sewing`, `/production`, `/issue`, `/export` ([app_routes.dart:84-91](lib/presentation/routes/app_routes.dart)) even though those modules aren't implemented or DI-wired — navigating there leads to empty/incomplete screens.

---

## 6. Architecture & code quality

### 6.1 Layering is inconsistent
The README prescribes `domain → repository → datasource`. Auth follows it ([auth_repository.dart](lib/data/repositories/auth_repository.dart) → [auth_remote_datasource.dart](lib/data/datasources/remote/auth_remote_datasource.dart)), **but all four working CRUD repos bypass the datasource layer and call `FirebaseFirestore.instance` directly** ([master_lc_repository.dart:9](lib/data/repositories/master_lc_repository.dart), plus `po_`, `role_`, `user_` repos). The corresponding datasource files (`master_lc_remote_datasource.dart`, `po_*`, etc.) are **1-line stubs**. Decide on one pattern — either route repos through datasources, or delete the empty datasource layer.

### 6.2 Duplicate & dead use-case files
Two parallel naming schemes coexist. The `*_usecase.dart` variants are real and DI-wired; the shorter twins are empty dead code:
- Real: `create_master_lc_usecase.dart` → `CreateMasterLCUseCase` (wired).
- Dead: [create_master_lc.dart](lib/domain/usecases/master_lc/create_master_lc.dart) → `class CreateMasterLC { call() async {} }`.

The same duplication exists for `login_user`/`register_user`/`get_current_user` vs. their `*_usecase` twins, most PO/Master-LC verbs, plus explicit `usecase_placeholder.dart` / `datasource_placeholder.dart` files. This is confusing scaffolding that should be deleted.

### 6.3 Fake "generated" files
All 10 `*.g.dart` files are hand-written decoys containing:
```
// Generated serialization placeholder. Run build_runner when model annotations are added.
```
Models actually hand-map Firestore (`fromSnapshot`/`toFirestore`, e.g. [master_lc_model.dart](lib/data/models/master_lc/master_lc_model.dart)) and use **no** `json_serializable`/`freezed` annotations. `build_runner` has never run. When it eventually does, it will overwrite these files — and their presence today misleads readers into thinking codegen is set up.

### 6.4 Dead splash / other smells
- `SplashScreen` is imported but unused (the real initial route is `/dashboard`) — the sole analyzer **warning** ([app_routes.dart:9](lib/presentation/routes/app_routes.dart)). Either wire it as the initial route or remove it.
- Entities extend neither `Equatable` nor use `freezed` despite both being declared — value-equality is not implemented.
- Dense single-line formatting, verbose field-by-field model rebuilds in `update()`, and leftover "if needed" comments in repos.
- 12 info-level lints (mostly `curly_braces_in_flow_control_structures`, `unnecessary_underscores`).

---

## 7. Dependencies

**~20 of 24 major dependencies are imported nowhere in `lib/`.** Unused: `dio`, `retrofit`, `excel`, `pdf`, `printing`, `fl_chart`, `firebase_messaging`, `image_picker`, `connectivity_plus`, `timezone`, `flutter_local_notifications`, `responsive_builder`, `flutter_svg`, `formz`, `flutter_screenutil`, `url_launcher`, `equatable`, `json_annotation`, `freezed_annotation`, `hive`/`hive_flutter`. Only `cloud_firestore`, `firebase_auth`, `firebase_core`, `get_it`, `flutter_bloc`, `go_router`, `dartz`, and (barely) `intl`/`shared_preferences`/`firebase_storage` are actually used.

Consequences: larger build/attack surface, slower `pub get`, and dev-only codegen deps (`build_runner`, `freezed`, `json_serializable`, `hive_generator`, `retrofit_generator`) that currently do nothing.

Several packages are also pinned several majors behind current (`intl ^0.18.1`, `go_router ^12.1.3`, `fl_chart ^0.66.0`, `freezed ^2.x`, `flutter_local_notifications ^15.x`). Run `flutter pub outdated` and bump deliberately.

```bash
flutter pub outdated
```

---

## 8. Testing & CI

- One test only: [test/widget_test.dart](test/widget_test.dart) exercises `AuthValidator`. No repository, BLoC, model, or widget tests.
- No CI configuration found. The README documents `flutter pub get / dart analyze / flutter test` but nothing enforces it.

---

## 9. Runtime verification

Launched via a generated `.claude/launch.json` (`flutter run -d web-server --web-port 8080`):
- ✅ First compile succeeded (~136 s); server returns **HTTP 200** and serves the Flutter bootstrap.
- ✅ App bootstraps — `<flutter-view>` present, runtime title updated to “Footwear ERP System”, **no console/Dart errors**.
- Initial route is `/dashboard` (a static shell) behind `RouteGuard`; unauthenticated users are redirected to `/login`. (Full UI rendering can't be captured headlessly because Flutter web draws into a shadow-DOM canvas and the Browser pane must be open for screenshots — open it to view the live app.)

---

## 10. Prioritized remediation plan

**P0 — Security (before any real/production data)**
1. Close HIGH-1: forbid client-set `role`/`permissions` at user-doc creation; move privileges to admin-only writes or custom claims.
2. Fix HIGH-2: remove `users`/`roles`/`audit_logs` from the catch-all match; make `audit_logs` immutable (create-only).
3. Add write-content validation to the rules; enable Firebase **App Check**; reconcile the `audit_log`/`audit_logs` key mismatch.

**P1 — Correctness & hygiene**
4. Delete dead/duplicate use-case files, all `*_placeholder.dart`, and the unused `SplashScreen` import.
5. Remove (or gate) routes to unimplemented modules so users don't hit dead ends.
6. Decide the serialization strategy: either adopt `json_serializable` and actually run `build_runner`, or keep manual mapping and drop the codegen deps + delete the fake `.g.dart` files.

**P2 — Consistency, deps, tests**
7. Prune the ~20 unused dependencies (or implement the features that need them); run `flutter pub outdated` and bump majors.
8. Choose one data-access pattern (datasource layer vs. direct-Firestore) and apply it uniformly.
9. Add tests (validators, repos against a fake Firestore, BLoCs) and a CI job running `dart analyze` + `flutter test`.
10. Standardize repository method naming (`getMasterLCList`/`byTag`/`createMasterLC`/`update`/`delete` are inconsistent).

---

## 11. Bottom line

A well-organized **starting point** with a working auth + CRUD slice and a clean build — but it is ~20–25% of an ERP, carries misleading scaffolding (fake generated files, duplicate stubs, unused deps), and, most importantly, ships **Firestore rules that allow self-service admin escalation**. Fix the security rules first; then either implement or prune the placeholder modules so the codebase's apparent scope matches its real scope.
