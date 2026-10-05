# NEXA Admin Lite

A compact Flutter administration app built against the NEXA Admin Lite PRD. One
Android application, one Admin role, Firebase as the backend.

---

## 1. Project overview

The app lets an administrator sign in with Firebase Authentication and then
manage the operational side of a small field business:

| Module | What it does |
| --- | --- |
| Authentication | Email/password sign-in, forgot password, session persistence, route guard |
| Dashboard | Live KPI tiles (employees, attendance, leads, approvals, collections) with pull-to-refresh |
| Employees | List, search by name, filter by status, create/edit, activate/deactivate, profile photo |
| Branches & Geofence | Create branches with latitude/longitude/radius, shown on a map with the geofence circle |
| Attendance | Day and status filters, plus a GPS test check-in evaluated against the branch geofence |
| Customers / Leads | List, search by name or mobile, status filter, create/edit, detail view |
| Documents | Capture or pick an ID proof, preview it, upload it, and keep the metadata in Firestore |
| Approvals | Expense list with approve/reject, a mandatory rejection reason, and duplicate-tap protection |
| Notifications | An approval alert that deep links to the relevant expense |
| Audit log | Append-only record of every significant administrative action |

---

## 2. Versions

| Tool | Version used |
| --- | --- |
| Flutter | 3.49.0-0.2.pre (main channel) |
| Dart SDK constraint | `^3.14.0-46.0.dev` |
| Android `minSdk` | 23 (required by Firebase) |
| Android `compileSdk` | Flutter default |

---

## 3. Packages used, and why

| Package | Why |
| --- | --- |
| `flutter_riverpod` | State management. Its `AsyncValue` models loading, data and error as one value, which maps directly onto Firestore streams and futures. |
| `go_router` | Declarative routing. A single `redirect` enforces the auth guard, and a `StatefulShellRoute` keeps each tab's navigation stack independent. |
| `firebase_core`, `firebase_auth`, `cloud_firestore` | Backend: identity and data. |
| `firebase_storage` | Retained as an alternative upload backend (see Section 7). |
| `firebase_messaging`, `flutter_local_notifications` | Push delivery, plus the tray notification that FCM does not show while the app is in the foreground. |
| `flutter_map`, `latlong2` | Map rendering with OpenStreetMap tiles (see Section 7). |
| `geolocator` | GPS position, permission handling and the distance calculation used by the geofence. |
| `image_picker` | Camera and gallery capture for photos and documents. |
| `dio` | Multipart upload with byte-level progress for the Cloudinary backend. |
| `connectivity_plus` | Drives the offline banner. |
| `intl` | Date and currency formatting. |

---

## 4. Firebase services used

- **Authentication** — email/password.
- **Cloud Firestore** — all business data; offline persistence is enabled.
- **Cloud Messaging** — approval alerts.
- **Cloud Storage** — rules are written and committed, but Cloudinary is the
  active upload backend (see Section 7).

---

## 5. Firebase setup

1. Create a Firebase project.
2. Register an Android app whose package name is
   `com.example.nexa_admin_lite`.
3. Download `google-services.json` into `android/app/`. **This file is
   gitignored and is not part of the repository.**
4. Under **Authentication → Sign-in method**, enable **Email/Password**, then
   add an admin user under the **Users** tab.
5. Create a **Firestore database**.
6. Deploy the rules:
   ```bash
   firebase deploy --only firestore:rules,firestore:indexes --project <your-project-id>
   ```

### Cloudinary setup (upload backend)

1. Create a free Cloudinary account.
2. Open **Settings → Upload → Upload presets → Add upload preset**, and set
   **Signing mode** to **Unsigned**. Leave the asset folder blank, because the
   app supplies a folder per upload.
3. Copy `dart_define.example.json` to `dart_define.json` and fill in your cloud
   name and preset name. **`dart_define.json` is gitignored.**

If those values are absent, the app automatically falls back to Firebase
Storage; no code change is needed.

---

## 6. Running and building

```bash
flutter pub get

# Run on a connected device
flutter run --dart-define-from-file=dart_define.json

# Release APK
flutter build apk --release --dart-define-from-file=dart_define.json
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## 7. Deviations from the PRD, and why

The PRD invites schema and tooling changes as long as they are justified here.
Two were necessary, and both come down to the same constraint: the Firebase
project is on the free Spark plan, and the services in question require a
billed Google Cloud account.

### Maps: OpenStreetMap instead of Google Maps

`google_maps_flutter` needs a Maps SDK API key, and that needs billing enabled.
`flutter_map` renders OpenStreetMap tiles with no key and no billing, and it
supports the marker and the radius circle the PRD asks for. The geofence maths
is unaffected either way, because distance comes from `geolocator`, not from the
map.

### Uploads: Cloudinary instead of Firebase Storage

Enabling Cloud Storage on a project created after late 2024 requires the Blaze
plan, which in India additionally requires a refundable prepayment before any
billing account can be attached. Rather than leave the upload features unbuilt,
uploads go to Cloudinary's free tier using an unsigned preset.

The important part is that this is a **configuration choice, not an
architectural one**:

- `lib/services/file_storage.dart` defines a single `FileStorage` interface.
- `FirebaseFileStorage` and `CloudinaryFileStorage` both implement it.
- `fileStorageProvider` picks one at runtime based on build configuration.
- No screen knows which backend is in use.

`storage.rules` is written, committed and explained in Section 9. Switching back
to Firebase Storage means removing two `--dart-define` values and deploying
those rules; no Dart code changes.

---

## 8. Firestore collection structure

```
users/{uid}
  uid, email, role: "admin", createdAt, lastLoginAt, fcmTokens: [string]

employees/{id}
  name, nameLower, mobile, email, designation,
  branchId, branchName, status: "active" | "inactive",
  photoUrl, createdAt

branches/{id}
  name, nameLower, latitude, longitude, radiusMeters

attendance/{yyyy-MM-dd}_{employeeId}
  employeeId, employeeName, branchId, branchName,
  date: "yyyy-MM-dd", status: "present" | "rejected",
  distanceMeters, radiusMeters, latitude, longitude, checkInAt

customers/{id}
  name, nameLower, mobile, email, address,
  status: New | Contacted | Interested | Converted | Rejected,
  createdAt

documents/{id}
  customerId, type, fileUrl, fileName, uploadedAt

expenses/{id}
  employeeId, employeeName, amount, category, description,
  status: "pending" | "approved" | "rejected",
  receiptUrl, rejectionReason, createdAt, decidedAt, decidedBy

collections/{id}
  amount, date: "yyyy-MM-dd"

audit_logs/{id}
  action, entity, summary, adminId, adminEmail, timestamp
```

### Schema decisions

- **`nameLower`** stores a lowercase copy of the name. Firestore has no
  case-insensitive search, so this makes ordered search feasible without a
  separate search service.
- **`date` as a `yyyy-MM-dd` string** keeps "records for one day" a simple
  equality query rather than a timestamp range, which keeps the index small.
- **Deterministic attendance document IDs** (`{date}_{employeeId}`) make one
  check-in per employee per day a structural guarantee rather than something to
  police in application code.
- **`collections`** is not in the PRD's suggested model, but the dashboard
  requires a "today's collections" figure, which needs somewhere to live.
- **Rejected check-ins are stored, not discarded**, so an out-of-range attempt
  leaves evidence that it was refused.

---

## 9. Security rules explained

### Firestore (`firestore.rules`)

- **Admin identity is proved by data, not by the UI.** `isAdmin()` reads
  `/users/{uid}` and requires `role == "admin"`. Hiding a button changes
  nothing; the rule is evaluated on the server.
- **Self-registration is bounded.** A signed-in user may create only their own
  profile document, and only with `role == "admin"`. An update may not change
  the role field, so the value cannot be escalated afterwards.
- **Business collections are admin-only** for both read and write.
- **`audit_logs` is append-only.** Create is allowed when `adminId` matches the
  caller; update and delete are denied outright, so history cannot be rewritten.
- **Default deny.** A catch-all `match /{document=**}` denies anything not
  matched above, so a new collection is closed until a rule opens it.

### Storage (`storage.rules`)

- Every path requires authentication.
- Uploads are restricted by content type (`image/*`) and by size: 5 MB for
  profile photos, 10 MB for documents and receipts.
- Paths are scoped per entity (`employees/{id}/`, `customers/{id}/`,
  `expenses/{id}/`), and everything else is denied.

---

## 10. Architecture

```
lib/
  core/        theme, colours, validators, routing, build config
  models/      immutable data classes with Firestore mapping
  services/    all backend access (auth, Firestore, storage, location, FCM)
  state/       Riverpod providers that bind services to the UI
  screens/     one folder per feature
  widgets/     reusable UI (bento tiles, glass nav bar, async view, map)
```

**The rule the code follows:** screens never touch Firebase directly. A screen
watches a provider, and the provider delegates to a service that owns the
Firestore or Storage call. That keeps query logic in one place per collection
and makes each service replaceable, which is exactly what let the storage
backend change without editing a single screen.

**State management — Riverpod.** Chosen because `AsyncValue` already encodes
loading, data and error, which are three of the states the PRD requires on every
screen. The shared `AsyncView` widget consumes that directly, so the loading
spinner, the error card and the retry button are written once and reused rather
than hand-rolled per screen.

### Points worth a closer look

- **Geofence evaluation** (`services/attendance_service.dart`) reads the GPS
  position, measures the great-circle distance to the branch, and compares it
  against the configured radius. Both outcomes are recorded.
- **Location failures** (`services/location_service.dart`) are modelled as an
  enum — services off, permission denied, permission permanently denied,
  timeout — so each produces its own message and, where useful, a button that
  opens the relevant settings screen instead of a generic error.
- **Duplicate approvals** (`services/expense_service.dart`) are prevented by a
  Firestore transaction that re-reads the document and aborts unless the status
  is still `pending`. Disabling the button only hides the problem; the
  transaction is what makes a second decision impossible, including from a
  second device.
- **Offline** is handled by Firestore's own cache, with a banner so the
  administrator knows that writes may not yet have reached the server.

---

## 11. Known limitations

- **Firebase Storage is not the active upload backend.** Cloudinary is, for the
  billing reason in Section 7. `storage.rules` is written and committed but
  cannot be deployed until Storage is enabled on the project.
- **Expenses are raised from inside the admin app.** In production they would
  come from an employee app, which is explicitly out of scope; the in-app form
  exists so the approval workflow can be exercised end to end.
- **The approval notification is raised locally.** The full FCM path —
  foreground, background and terminated handling, token registration and the
  tap-to-detail deep link — is implemented and works with a message sent from
  the Firebase console. Automatically pushing one when an expense is created
  would need a Cloud Function, which requires the same billing upgrade.
- **Collections data has no entry screen.** The dashboard reads the
  `collections` collection, but documents have to be added through the console.
- **Search is client-side**, filtering an already-streamed list. That is fine at
  this scale and avoids a search service, but it would need revisiting for large
  collections.
