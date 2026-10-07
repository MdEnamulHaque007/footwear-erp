# Activity Log

Open **Activity Log** from the drawer or bottom navigation. The existing
`/audit-log` URL still works. The page is restricted to administrators.

## Recorded operations

- Successful Firestore creates, changes and deletes in Master LC, PO, Cutting,
  Sewing, Lasting/Production, FG Issue, Export, users, roles, business settings
  and private app preferences are recorded by a second-generation Cloud Function.
- This includes transactions, batches and external Firestore imports. There is
  one history entry per changed document, not one entry per batch.
- Public repository reads, dropdown lookups, validations, dashboards, reports
  and profile reads are app-reported. Nested reads inside a public read produce
  one entry. Read errors are marked `failure`, without copying error payloads.
- A write that fails, or writes exactly the same document without changing any
  field, generates no Firestore change event. Authentication sign-in/out and
  changes that exist only in local device storage are not Firestore CRUD events.
- Audit-log reads/writes and internal sequence counters are deliberately excluded
  to avoid recursive logging. Existing history is not backfilled.

Write entries include server event time, authenticated principal when available,
module, document ID/path, record label, changed fields and before/after snapshots.
Service-account/system imports retain the source principal rather than claiming
that an ERP user performed the action. Snapshot values are bounded and common
secret fields are redacted. Truncated snapshots are explicitly marked.

Read entries include actor UID, operation, result count and status. They are
client-reported telemetry, not proof that a database read occurred. Rules bind
UID/email to the signed-in identity and require a server timestamp; clients
cannot manufacture trusted `firestore_trigger` C/U/D entries. A failed/offline
read-log submission does not fail the business read and is not guaranteed to be
retained. Unauthenticated reads and debug-bypass reads have no authenticated
actor and are not persisted.

## Page

Newest first, 50 entries per page, with Load more, refresh, module/action filters,
exact user UID filter, inclusive local date range, empty/error states and details
with before/after values. Filters run on the database, not just the loaded page.
The user UID can be copied from activity details. History is fetched on open,
filter change, refresh and Load more; it is not a live subscription.

## Deployment

The Flutter web build alone does **not** activate the write trigger.
Use the Firebase project configured for this app (currently `footwear-9d10e`):

```sh
npm ci --prefix functions
firebase deploy --project footwear-9d10e --only firestore:rules,firestore:indexes,functions:recordActivity
flutter build web
```

Publish `build/web` through the project's hosting workflow. Cloud Functions
requires a Firebase project with billing enabled. Wait until Firestore indexes
finish building, then perform create/update/delete operations and refresh the
Activity Log page. Trigger delivery is asynchronous, so writes may appear after
a short delay. Deploy to a test project first when validating release behavior.

Do not deploy the project's debug-bypass Firestore rules. This feature does not
repair the existing first-admin bootstrap rule; review that separately before
production release. Existing broad business permissions remain unchanged.

## Verification

```sh
npm test --prefix functions
npm run check --prefix functions
npm run test:integration --prefix functions
flutter test test/unit/activity_log_service_test.dart test/activity_log_screen_test.dart
```

Integration tests use a local demo project and emulator, never production data.
They check append-only rules, rejected forged records and the production trigger
handler against actual create/update/delete snapshots, including retry dedupe.
They invoke the trigger handler explicitly; production Eventarc delivery is not
reproduced by those tests.

## Checks performed in this workspace

- 11 Node unit tests passed.
- 3 Firestore/Auth emulator integration tests passed.
- Node syntax checks, JSON validation and `git diff --check` passed.
- The added and changed Dart files were parsed/formatted successfully.
- Flutter tests and analyzer were not completed: automatic approval review
  blocked the Flutter startup/dependency process because it attempted cloud
  metadata endpoint access. No production deployment or GitHub push was made.
