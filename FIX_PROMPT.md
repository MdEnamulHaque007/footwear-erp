# Fix Prompt — Footwear ERP: page-load errors on Master LC, PO, Cutting, Sewing, Production, Issue, Export

> Paste everything below (from "You are working on…") into your coding agent. It is self-contained.

---

You are working on a **Flutter** app (a footwear/garment production ERP) that uses **clean architecture** (`lib/domain`, `lib/data`, `lib/presentation`) with `flutter_bloc`, `go_router`, `get_it` (DI), `dartz` (`Either<String, T>` for error handling), `cloud_firestore`, and Hive.

Key files:
- DI container: `lib/injection/dependency_injection.dart` (uses `GetIt`)
- Router: `lib/presentation/routes/app_routes.dart` (uses `go_router`)
- Fully-implemented **reference modules** to copy patterns from: **Master LC** and **Purchase Order (PO)**.

## Problem to fix
Opening these 7 pages currently fails:
- **Master LC** and **PO** → app throws `ProviderNotFoundException` the moment the page opens.
- **Cutting, Sewing, Production, Issue, Export** → only blank placeholder pages (modules are unimplemented stubs).

There are **two distinct root causes**, fixed in two phases.

---

## Phase 1 — Fix the runtime crash (Master LC + PO). Do this first; it is small and self-contained.

Root cause: in `lib/presentation/routes/app_routes.dart` the `/master-lc` and `/purchase-orders` routes build their list screens **without a `BlocProvider`**, but `MasterLCListScreen` and `POListScreen` call `context.read<MasterLCBloc>()` / `context.read<POBloc>()` in `initState` and use `BlocConsumer`. With no provider ancestor, Flutter throws `ProviderNotFoundException`. (The `/master-lc/new` and `/admin/users` routes already show the correct pattern.)

`MasterLCBloc` and `POBloc` are **already registered** in `dependency_injection.dart` via `registerFactory`, so no DI change is needed here.

Change this:
```dart
GoRoute(path: '/master-lc',       builder: (_, _) => const MasterLCListScreen()),
GoRoute(path: '/purchase-orders', builder: (_, _) => const POListScreen()),
```
into this:
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
Make sure `flutter_bloc`, `get_it`, and the two BLoC classes are imported in `app_routes.dart` (they already are for other routes). After this, both pages load correctly.

---

## Phase 2 — Implement the 5 stub modules: Cutting, Sewing, Production, Issue, Export

Right now each of these modules is only a skeleton: the entity has just `id`, the model has just `id`, the repository is an empty class, the usecases are no-op stubs (`GetCuttingList.call()` returns `[]`), the BLoC is a placeholder `Cubit<int>`, the event/state files are empty `sealed class`es, and the list/form screens show placeholder `Text`. None of these are registered in DI.

**Approach:** implement one module at a time as a full vertical slice, **mirroring the Master LC reference implementation exactly**. Keep `flutter analyze` clean after each module before moving on.

### Reference files to copy the pattern from (Master LC)
- Entity: `lib/domain/entities/master_lc_entity.dart`
- Model (+ generated `.g.dart`): `lib/data/models/master_lc/master_lc_model.dart`
- Repo interface: `lib/domain/repositories/i_master_lc_repository.dart`
- Repo impl (Firestore, keyset pagination): `lib/data/repositories/master_lc_repository.dart`
- Usecases: `lib/domain/usecases/master_lc/*_usecase.dart`
- BLoC / events / states: `lib/presentation/blocs/master_lc/master_lc_{bloc,event,state}.dart`
- List screen: `lib/presentation/screens/master_lc/master_lc_list_screen.dart`
- DI registration block: `lib/injection/dependency_injection.dart` (the Master LC section)
- Route wiring: the `/master-lc` route in `app_routes.dart` (after Phase 1)

### For EACH module X in {Cutting, Sewing, Production, Issue, Export}, deliver:
1. **Entity** `XEntity` with real, immutable `final` fields (nullable `id`). Fields per the workflow section below.
2. **Model** `XModel` with `fromSnapshot(DocumentSnapshot)`, `fromEntity(XEntity)`, and `toFirestore()`. If it uses `json_serializable`, regenerate with:
   `dart run build_runner build --delete-conflicting-outputs`
3. **Repository interface** `IXRepository` with these signatures (mirror `IMasterLCRepository`):
   - `Future<Either<String, List<XModel>>> getXList({int page = 0, int limit = 20})`
   - `Future<Either<String, void>> createX(XEntity item)`
   - `Future<Either<String, void>> update(XEntity item)`
   - `Future<Either<String, void>> delete(String id)`
4. **Repository impl** `XRepository implements IXRepository` — Firestore-backed, keyset pagination (`orderBy`, `startAfterDocument`, a `_lastDoc` cursor reset on page 0), every method wrapped in `try / on FirebaseException / catch` returning `Left(...)` / `Right(...)`. Add a collection-name constant `AppConstants.collectionX` in `lib/core/constants/app_constants.dart` (mirror `collectionMasterLC`).
5. **Usecases** `GetXListUseCase`, `CreateXUseCase`, `UpdateXUseCase`, `DeleteXUseCase` — thin wrappers returning `Either`, constructed with the repo interface (mirror the `master_lc` usecases). Replace/repurpose the existing stub usecase files in `lib/domain/usecases/<module>/`. Also implement the workflow usecases already stubbed there (see below) where they exist.
6. **BLoC** `XBloc extends Bloc<XEvent, XState>` — **replace the `Cubit<int>` stub** — with handlers for `LoadXList`, `LoadMoreX`, `CreateX`, `UpdateX`, `DeleteX`, using `result.fold(...)` exactly like `MasterLCBloc` (including `_currentPage`, `_hasMore`, `_items` pagination bookkeeping).
7. **Events** (`sealed class XEvent`): `LoadXList`, `LoadMoreX`, `CreateX(item)`, `UpdateX(item)`, `DeleteX(id)`.
   **States** (`sealed class XState`): `XInitial`, `XLoading`, `XLoaded(List<XEntity> items)`, `XError(String message)`, `XSuccess(String message)`.
8. **List screen** — replace the placeholder with a real screen copied from `MasterLCListScreen` (StatefulWidget, `initState` dispatches `LoadXList` via `context.read<XBloc>()` in a post-frame callback, scroll-to-load-more, `BlocConsumer`, `ListView.builder`, empty state text, FAB that opens the form). Wire the existing `X_form_screen.dart` and the existing `available_*_list.dart` widget where relevant.
9. **DI**: in `setupLocator()` register the repo (`registerLazySingleton<IXRepository>`), the usecases (`registerLazySingleton`), and the BLoC (`registerFactory`) — mirror the Master LC block.
10. **Route**: wrap the module's list route in `BlocProvider(create: (_) => GetIt.I<XBloc>(), child: const XListScreen())`, same as `/master-lc` after Phase 1.

### Domain workflow (garment production chain) — informs entity fields & validation
The stages form a chain: **PO → Cutting → Sewing → Production → Issue → Export**. Each stage consumes quantity produced by the previous stage and must not exceed the remaining available quantity for that PO.

Suggested entity fields (confirm against the real business spec before finalizing — do not invent beyond what's needed):
- **Cutting**: `id, voucherNo, date, poNo, tagNo, article, cuttingQuantity`
- **Sewing**: `id, voucherNo, date, cuttingVoucherNo, poNo, sewingQuantity`
- **Production**: `id, voucherNo, date, sewingVoucherNo, poNo, productionQuantity`
- **Issue**: `id, voucherNo, date, productionVoucherNo, poNo, issueQuantity`
- **Export**: `id, voucherNo, date, issueVoucherNo, poNo, exportQuantity, invoiceNo`

The repo/usecase folders already contain stubs that hint at required logic — implement them:
- `get_available_po_for_cutting` / `get_available_cutting` / `get_available_sewing` / `get_available_production` / `get_available_issue` → remaining quantity available from the previous stage.
- `validate_*_quantity` → reject amounts exceeding the available/remaining quantity.
- `generate_voucher_no` → unique per-module voucher number.
- `get_cumulative_cutting` → sum of quantities already recorded for a PO.

---

## Constraints
- Match the existing code style: **functional error handling with `dartz` `Either`** — do not throw exceptions across layers; catch at the repository and return `Left`/`Right`.
- Provide each route's BLoC from `GetIt.I<XBloc>()` (a `registerFactory`), not by constructing the BLoC inline.
- Do **not** break the Master LC or PO modules.
- Keep imports clean; no unused imports; no analyzer warnings.

## Verification (all must pass before you consider this done)
1. `flutter analyze` → **zero** errors/warnings.
2. `flutter test` → existing tests pass. Add a widget test per page that pumps the list screen **wrapped in its `BlocProvider`** and asserts it builds with **no `ProviderNotFoundException`**.
3. Manual smoke test: log in, then open all 7 pages (Master LC, PO, Cutting, Sewing, Production, Issue, Export). Each must:
   - open without throwing,
   - show a loading spinner then either data or an empty-state message ("No records"),
   - open its create form from the FAB.
4. Audit routes: grep each screen for `context.read<`, `context.watch<`, `BlocBuilder<`, `BlocConsumer<`, `BlocListener<`; for every BLoC referenced, confirm its route (or an ancestor) provides that BLoC via `BlocProvider`. No screen should reference a BLoC that isn't provided above it.

Report back a summary of files changed/created per module and the results of steps 1–4.
