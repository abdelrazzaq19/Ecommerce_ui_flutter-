# TODO: Ecommerce App Modernization

Plan: [tasks/plan.md](plan.md) · Status: Phase 0 complete (Tasks 1-3) · Updated 2026-09-08

Verify commands: `flutter analyze` · `flutter test` · `flutter run -d chrome`

---

## Phase 0: Foundation

- [x] **Task 1 — Clean `pubspec.yaml` and upgrade dependencies** (S, no deps) — DONE
  - [x] Removed the ~55-line commented duplicate manifest
  - [x] `http ^1.5.0`, `flutter_lints ^6.0.0`, added `shared_preferences ^2.5.0`, `intl ^0.20.0`, `cached_network_image ^3.4.1`
  - [x] `flutter pub get` resolves; `flutter analyze` clean
  - [x] `assets/images/` declared; `analysis_options.yaml` tightened (`prefer_single_quotes`, `unawaited_futures`)
  - Deferred: `strict-casts` / `strict-raw-types` move to Task 4 — they only flag the unsafe `Product.fromJson` that Task 4 rewrites

- [x] **Task 2 — Material 3 design system and theme tokens** (S, needs T1) — DONE
  - [x] `AppTheme.light` / `AppTheme.dark`, `useMaterial3: true`, seeded from brand `#3D5AFE`
  - [x] `app_tokens.dart`: `AppSpacing`, `AppRadius`, `AppElevation`, `AppDurations`, `AppSizes`, `AppBreakpoints`
  - [x] Component themes centralised (app bar, card, buttons, inputs, chips, nav bar, snackbar, sheets, dividers, list tiles)
  - [x] Tests assert Material 3, brand hue, WCAG AA contrast on primary/surface/error pairs, dark scaffold, 4dp grid, 48dp tap floor
  - [x] `themeMode: ThemeMode.system` wired in `main.dart` (persisted selector lands in Task 17)
  - Visual light/dark sweep deferred to Task 7 — the home page is still blank until B1 is fixed, so there is nothing to look at yet

- [x] **Task 3 — Real test harness replacing the counter test** (S, needs T1) — DONE
  - [x] `flutter test` green, 3 tests (fixes B10)
  - [x] `test/helpers/pump_app.dart` + `test/helpers/fake_products.dart` exist
  - [x] Moved the provider graph from `main()` into `MyApp` so `const MyApp()` is pumpable
  - Deferred: `fake_repository.dart` lands with Task 5, when `ProductRepository` exists to fake

### ▣ Checkpoint A — Foundation
- [ ] `flutter analyze` clean · `flutter test` green · app launches light + dark
- [ ] Human review

---

## Phase 1: Data Layer Correctness

- [ ] **Task 4 — Null-safe `Product` model** (S, needs T3) — fixes B8
  - [ ] Survives missing `rating` / null `price` / string `price`
  - [ ] Adds `category`, `ratingCount`, `toJson()` round-trip

- [ ] **Task 5 — `ApiService` + `ProductRepository`, timeouts, typed errors** (M, needs T4) — fixes B6, B7, B9
  - [ ] Drop the ignored `offset` and `q` params; add `fetchAllProducts()` and `fetchCategories()`
  - [ ] 10s timeout; `ApiException` with distinct messages for 500 / timeout / malformed JSON
  - [ ] Injectable `http.Client`; no live network in tests

- [ ] **Task 6 — `LocalStore` persistence service** (S, needs T4)
  - [ ] Typed keys for cart, wishlist, session, theme, search history, orders, catalog cache
  - [ ] Corrupt JSON returns the default instead of throwing

### ▣ Checkpoint B — Data Layer
- [ ] Unit tests cover parsing, API errors, persistence · no live network calls
- [ ] Human review

---

## Phase 2: Vertical Feature Slices

- [ ] **Task 7 — Home browse: first load, paging, states, cards** (M, needs T2, T5) — fixes B1, B6, B9, image gaps
  - [ ] Products appear on first launch with no interaction
  - [ ] Client-side paging stops at 20 with no duplicates
  - [ ] Error state with working Retry; pull-to-refresh; image placeholder + fallback

- [ ] **Task 8 — App shell: bottom nav, named routes, cart badge** (M, needs T7) — fixes B2, B3
  - [ ] Five destinations reachable, each keeps its scroll position
  - [ ] `pushReplacementNamed('/')` resolves; badge updates live

- [ ] **Task 9 — Product detail modernized** (M, needs T7, T8) — fixes B12
  - [ ] No overflow at 320 dp or 2.0x text scale
  - [ ] Quantity stepper + Add to Cart snackbar with "View cart"

- [ ] **Task 10 — Cart: loop fix, quantity controls, persistence, currency** (M, needs T6, T7, T8) — fixes B4, B5, price formatting
  - [ ] Zero network requests on open; settles in one frame
  - [ ] Increment/decrement, remove with Undo, empty state
  - [ ] Prices as `$1,234.50`; cart survives restart

- [ ] **Task 11 — Search: client-side, debounced, leak-free** (M, needs T6, T7, T8) — fixes B7, B11
  - [ ] "shirt" returns matches only, not all 20; case-insensitive partial match
  - [ ] 300 ms debounce, controller disposed, `mounted` guarded
  - [ ] Persisted recent-search chips

- [ ] **Task 12 — Category filter and sort** (M, needs T7, T11)
  - [ ] Category chips narrow the grid and update the count
  - [ ] Price asc/desc, rating, name A-Z all verifiably correct and composable with search

- [ ] **Task 13 — Auth: login, register with validation, persisted session** (M, needs T6, T8)
  - [ ] Name/email/phone/password rules each block submit with inline errors
  - [ ] Session survives restart; logout clears it
  - [ ] Labelled as a local demo account

- [ ] **Task 14 — Wishlist** (M, needs T6, T7, T8)
  - [ ] Heart toggles on card and detail; persists across restart; move-to-cart works

### ▣ Checkpoint C — Core Shopping Flow
- [ ] End-to-end: browse, filter, search, detail, add to cart, restart, cart intact
- [ ] Defects B1-B12 all fixed, each covered by a test
- [ ] Human review

---

## Phase 3: Real-World Features and Polish

- [ ] **Task 15 — Checkout with address form and confirmation** (M, needs T10, T13)
  - [ ] Auth guard routes to login and resumes
  - [ ] Address validation blocks Place Order; success clears the cart and shows an order id
  - [ ] States plainly that it is a demo order — no payment, no card details collected

- [ ] **Task 16 — Order history and reorder** (S, needs T15)
  - [ ] Orders persist, newest first; detail shows purchased prices; Reorder refills the cart

- [ ] **Task 17 — Profile and settings, persisted dark mode** (S, needs T13, T16)
  - [ ] System/Light/Dark applies instantly and survives restart; logout confirms first

- [ ] **Task 18 — Offline resilience: catalog cache** (M, needs T6, T7)
  - [ ] Second launch renders from cache; offline shows cached data with a banner
  - [ ] Offline with no cache shows error + retry

- [ ] **Task 19 — Accessibility and polish pass** (M, needs T7-T18)
  - [ ] Semantics labels on all icon-only controls; 48x48 dp targets
  - [ ] No overflow at 320 dp or 2.0x text scale; AA contrast in both themes

- [ ] **Task 20 — README rewrite** (XS, needs T19)
  - [ ] Every listed feature exists; setup works from a clean clone; demo scope stated

### ▣ Checkpoint D — Complete
- [ ] All acceptance criteria met · analyze clean · tests green · manual full-flow pass
- [ ] Ready for review

---

## Defect Index (see plan.md for evidence)

| ID | Defect | Fixed by |
|----|--------|----------|
| B1 | Home never loads products (blank screen) | Task 7 |
| B2 | Login crashes on unregistered route `/` | Task 8 |
| B3 | Cart / Search / Login unreachable | Task 8 |
| B4 | Cart `FutureBuilder` network loop | Task 10 |
| B5 | Cart shows "Product not found" for id > 10 | Task 10 |
| B6 | Infinite scroll duplicates (API ignores `offset`) | Tasks 5, 7 |
| B7 | Search returns all 20 products (API ignores `q`) | Tasks 5, 11 |
| B8 | `Product.fromJson` null crash | Task 4 |
| B9 | Errors swallowed, no timeout, no retry | Tasks 5, 7 |
| B10 | `flutter test` red (default counter test) | Task 3 |
| B11 | `SearchPage` controller leak / setState after dispose | Task 11 |
| B12 | Product detail overflow | Task 9 |

## Decisions (answered 2026-09-08)

- [x] **Platforms:** all six — Android, iOS, web, Windows, macOS, Linux. Layouts must be responsive, and
      every package chosen must support all six (`shared_preferences`, `cached_network_image`, `intl` do).
- [x] **Auth:** stays a local simulation. No backend, no real credentials, no payment data.
- [x] **Brand color:** `#3D5AFE` (indigo). Seeds both Material 3 schemes.
