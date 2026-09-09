# TODO: Ecommerce App Modernization

Plan: [tasks/plan.md](plan.md) · Status: ALL 20 TASKS DONE. Tasks 1-12 committed; Tasks 13-20 awaiting your commit · Updated 2026-09-08

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

- [x] **Task 4 — Null-safe `Product` model** (S, needs T3) — fixes B8 — DONE (uncommitted)
  - [x] Survives missing `rating`, null/`'free'` price, string price, string id, missing strings
  - [x] Bare-number rating accepted; rating clamped to 0..5
  - [x] Adds `category`, `ratingCount`, `toJson()` round-trip, value equality, `toString`
  - [x] `Product.listFromJson` skips malformed rows instead of failing the whole request
  - [x] `strict-casts` now enabled in `analysis_options.yaml`; `api_service.dart` casts fixed
  - Deferred: `strict-raw-types` waits for Task 10 (raw `FutureBuilder(` in `cart_page.dart`)

- [x] **Task 5 — `ApiService` + `ProductRepository`, timeouts, typed errors** (M, needs T4) — fixes B6, B7, B9 — DONE (uncommitted)
  - [x] `offset` and `q` gone; a test asserts the request carries no query parameters at all
  - [x] `fetchProducts()` (whole catalog) and `fetchCategories()`
  - [x] 10s default timeout; `ApiException` with four kinds (network, timeout, server, decoding), each with its own user-facing message and an `isRetryable` flag
  - [x] `ApiProductRepository` returns sealed `Success` / `EmptyResult` / `Failure` — a network error can no longer masquerade as an empty catalog
  - [x] Injectable `http.Client` and `timeout`; all 21 new tests use `MockClient` or `FakeProductRepository`
  - [x] `test/helpers/fake_repository.dart` added (deferred from Task 3), with `fetchCount` for refresh assertions
  - Interim: `ProductProvider` now replaces its list instead of appending (partial B6 fix) and keeps the error instead of swallowing it; `CartProvider.fetchProducts` marked for deletion in Task 10

- [x] **Task 6 — `LocalStore` persistence service** (S, needs T4) — DONE (uncommitted)
  - [x] Typed read/write for cart, wishlist, session, theme mode, search history, orders, catalog cache + `cachedAt`
  - [x] Every read is total: bad JSON, wrong shape, or junk entries fall back to the default instead of throwing
  - [x] `addSearch` de-duplicates case-insensitively, keeps newest first, caps at 10
  - [x] `clearSession` (logout) and `clearAll` (reset) scoped to the app's own keys
  - [x] No secrets stored — the session holds a display profile only; this app has no backend and never persists a password
  - [x] 22 tests via `SharedPreferences.setMockInitialValues`

### ▣ Checkpoint B — Data Layer
- [x] Unit tests cover parsing, API errors, persistence — 67 tests green
- [x] No test performs a live network call (`MockClient` / `FakeProductRepository` / mocked prefs)
- [x] `flutter analyze` clean with `strict-casts`; `flutter build web` succeeds
- [ ] Human review

---

## Phase 2: Vertical Feature Slices

- [x] **Task 7 — Home browse: first load, paging, states, cards** (M, needs T2, T5) — fixes B1, B6, B9, image gaps — DONE (uncommitted)
  - [x] `CatalogProvider` loads on first build (`loadIfNeeded`) — B1 dead, verified in the real web build
  - [x] Client-side paging, 8 per page, stops at 20 with an end-of-results marker and no duplicates
  - [x] `ErrorStateView` with a working Retry, `EmptyStateView`, static skeleton grid, pull-to-refresh
  - [x] `ProductCard` grid replacing the `ListTile` list: image, 2-line title, formatted price, rating
  - [x] `ProductImage` with placeholder + fallback icon, disk-cached, plus a `debugImageBuilder` test seam
  - [x] Responsive columns (2 phone / 3 tablet / 4 desktop), content clamped to 1200dp on wide windows
  - [x] `formatPrice` via `intl` — `$109.95`, not `$109.9`
  - [x] `MyApp` takes an optional repository so the boot test never reaches the live API
  - [x] Visual check in the built web app: light + dark, desktop 4-col + mobile 2-col, scrolled to the end marker

- [x] **Task 8 — App shell: bottom nav, named routes, cart badge** (M, needs T7) — fixes B2, B3 — DONE (uncommitted)
  - [x] Five destinations reachable (Home, Search, Saved, Cart, Profile); tabs stay alive so scroll position survives a tab switch
  - [x] Adaptive: `NavigationBar` on phones, `NavigationRail` from 840dp — the app ships to web and three desktops
  - [x] `appRoutes` registers `/` and `/login`; `pushReplacementNamed('/')` resolves, so the login redirect can no longer throw
  - [x] Live cart badge; add-to-cart wired on the product card with a confirmation snackbar
  - [x] `lib/app.dart` holds the app root and `lib/routes.dart` the provider graph; `main.dart` is just `runApp`
  - [x] Placeholder-free stand-ins: Saved and Profile show real empty / signed-out states, not "coming soon"
  - Pulled forward from Task 10 out of necessity: the shell hosts `CartPage`, so the `FutureBuilder(future: fetchProducts())`
    request loop (B4) and the private ten-item cache (B5) had to die now. `CartProvider` stores ids only and resolves through
    `CatalogProvider`. Task 10 still owns quantity controls, undo, persistence and the order summary.
  - [x] Verified in the built web app: rail + badge + cart contents + formatted total

- [x] **Task 9 — Product detail modernized** (M, needs T7, T8) — fixes B12 — DONE (uncommitted)
  - [x] `CustomScrollView` with a collapsing image header; the whole page scrolls
  - [x] No overflow at 320dp or at 2.0x text scale (both asserted by tests)
  - [x] `RatingStars` widget with a screen-reader label, review count, half stars
  - [x] `QuantityStepper` (min 1) and a sticky purchase bar that wraps instead of overflowing
  - [x] Add to cart adds the selected quantity; snackbar offers "View cart", which pops and switches the shell to the cart tab
  - [x] Category chip, expandable description, Hero image shared with the grid card
  - [x] `ShellTabController` extracted so pushed pages can drive the shell's tab
  - [x] Detail content clamped to 900dp so desktop lines stay readable

- [x] **Visual polish pass** (extra, requested after Task 9) — DONE (uncommitted)
  - [x] Typography: tighter, heavier headings; roomier body text; consistent label weights
  - [x] Cards: 20dp radius, hairline border instead of a shadow (a drop shadow goes muddy in dark mode)
  - [x] Pill-shaped buttons and inputs; chips on `secondaryContainer`; styled navigation rail
  - [x] `ProductCard` redesigned: rounded white image plate, floating rating pill, filled add button, title/price hierarchy
  - [x] Home rebuilt around a large `SliverAppBar` with an item count; one scroll view for every state, so pull-to-refresh works on the error and empty screens too
  - [x] Empty and error states: icon in a soft tinted disc, headline-sized titles
  - [x] Cart rows redesigned as cards with image, unit price, quantity pill and line total
  - [x] Grid thresholds retuned (2 / 3 / 4 columns) so a desktop window with a rail is not stuck at three oversized cards
  - [x] Image placeholder and fallback switched to fixed neutral greys — theme colors punched a black hole through the white plate in dark mode
  - [x] Verified in the built web app: light + dark, desktop 4-col, mobile 2-col, detail page

- [x] **Task 10 — Cart: quantity controls, persistence, order summary** (M, needs T6, T7, T8) — DONE (uncommitted)
  - [x] Quantity stepper per line; minus on the last unit removes it, with Undo that restores the full quantity
  - [x] Remove button per line, and Clear behind a confirmation dialog
  - [x] Cart persists through `LocalStore` — verified by reloading the built web app, badge still showed 2
  - [x] Order summary: subtotal, delivery, total, plus a free-delivery progress hint
  - [x] Free delivery at $50, otherwise $4.99 — a demo rule, stated in the UI
  - [x] Empty state links back to the catalog through `ShellTabController`
  - [x] Unavailable ids (products the catalog no longer has) stay removable instead of stranding the cart
  - [x] `main()` is now async: `LocalStore` opens before the first frame, so a saved cart is on screen at launch
  - [x] `strict-raw-types` enabled now that the raw `FutureBuilder(` is gone — the last deferred lint
  - [x] 28 new tests (18 provider, 10 widget)
  - B4 and B5 were already fixed in Task 8, when the shell had to host this page

- [x] **Task 11 — Search: client-side, debounced, leak-free** (M, needs T6, T7, T8) — fixes B7, B11 — DONE (uncommitted)
  - [x] Filters the in-memory catalog; "shirt" returns 2 matches, not all 20 — verified in the built web app
  - [x] Case-insensitive partial match across title, category and description; title matches rank first
  - [x] 300 ms debounce, controller disposed, debounce timer cancelled in `dispose`
  - [x] Tearing the page down mid-typing throws nothing (a test asserts it)
  - [x] Recent searches persisted, tappable, clearable; recorded on submit **and** on opening a result — plenty of people never press Enter
  - [x] Clear button, no-results state naming the query, idle state naming the catalog size
  - [x] `ProductProvider` deleted — `CatalogProvider` is now the only product state
  - [x] 13 new tests

- [x] **Task 12 — Category filter and sort** (M, needs T7, T11) — DONE (uncommitted)
  - [x] Category chips (All + the API's four) narrow the grid and update the result count
  - [x] Sort sheet: Featured, price low-high, price high-low, top rated, name A-Z — each order asserted explicitly
  - [x] Filter and sort compose; Reset clears both; changing either resets paging to page one
  - [x] Categories come from the API, falling back to ones derived from the products if that call fails — a failed category call must not fail the screen
  - [x] A selected category that disappears on refresh is dropped instead of filtering everything away
  - [x] `CatalogProvider.allProducts` still exposes the unfiltered catalog, so a filter cannot break cart lookups
  - [x] Search deliberately still spans the whole catalog (it has its own relevance ranking); a test covers searching within the filtered list too
  - [x] 19 new tests. Two real layout bugs found by them: the filter row overflowed 26px at 400dp with a long sort label, and the sort sheet overflowed 60px on a short phone
  - [x] Theme fix: unselected and selected chips were both `secondaryContainer`, so a selected filter looked identical to the rest of the row

- [x] **Task 13 — Auth: login, register with validation, persisted session** (M, needs T6, T8) — DONE (uncommitted)
  - [x] `Validators` as pure functions: name, email, phone (digit count, tolerant of + spaces brackets dashes), password, new password (letters + numbers), confirmation
  - [x] Registration page exists at last — the README has claimed it since the first commit
  - [x] Each field shows its own inline error live and blocks submit; verified in the browser with four bad fields at once
  - [x] Session persists; verified by a full page reload in the built web app
  - [x] Sign out asks first, ends the session, and **keeps the account** — signing out is not deleting your account
  - [x] Signing back in with just email + password restores the registered name and phone
  - [x] No password is stored anywhere, not even hashed; a test asserts the stored session contains no password
  - [x] Every screen says plainly that accounts are local and nothing is sent to a server
  - [x] Profile shows initials avatar, name, email, phone; `UserSession` model with JSON round-trip
  - [x] `LocalStore` gains an `accounts` key, separate from `session`
  - [x] 30 new tests

- [x] **Task 14 — Wishlist** (M, needs T6, T7, T8) — DONE (uncommitted)
  - [x] `WishlistProvider` stores ids only and resolves through `CatalogProvider`, the same as the cart
  - [x] Heart on the product card (home and search results) and in the detail app bar; both drive the same state
  - [x] Newest saved first — `LocalStore` now keeps wishlist order instead of a `Set`
  - [x] Persists across restart; verified by reloading the built web app
  - [x] Move to cart adds the product, removes it from Saved, and offers "View cart"
  - [x] Removing from the Saved tab offers Undo
  - [x] A saved id the catalog no longer has is skipped in the grid but kept in storage — a wishlist can outlive a product
  - [x] Empty state links back to the catalog
  - [x] 20 new tests

### ▣ Checkpoint C — Core Shopping Flow
- [x] End-to-end verified in the built web app: browse, filter, sort, search, detail, add to cart, save, sign in, reload — cart, wishlist and session all intact
- [x] Defects B1-B12 all fixed, each covered by a test
- [x] `flutter analyze` clean under `strict-casts` and `strict-raw-types`; 213 tests green
- [ ] Human review

---

## Phase 3: Real-World Features and Polish

- [x] **Task 15 — Checkout with address form and confirmation** (M, needs T10, T13) — DONE (uncommitted)
  - [x] Auth guard shows the sign-in prompt **in place** rather than throwing the shopper out; the form appears the moment the session exists, so the cart is never lost
  - [x] Address form validates all five fields with its own inline error each; a blocked order keeps the cart intact
  - [x] Prefills from the last address used, falling back to the signed-in profile
  - [x] Placing an order clears the cart, records it, saves the address, and pushes a confirmation with a readable id (`ORD-20260909-DUBB`)
  - [x] `Order` / `OrderLine` / `ShippingAddress` models; lines snapshot the price paid, so a later price change cannot rewrite history
  - [x] `OrderProvider` persists through `LocalStore`; a corrupt stored order degrades to an empty one instead of taking the history down
  - [x] Empty cart cannot be checked out
  - [x] Checkout and confirmation both state outright that no payment is taken and no card details are asked for — and none are
  - [x] `LocalStore` is now provided to the widget tree, so a screen can read or write one key without its own provider
  - [x] 14 new tests; verified end to end in the built web app

- [x] **Task 16 — Order history and reorder** (S, needs T15) — DONE (uncommitted)
  - [x] History list, newest first, with date, item count and total; reachable from Profile with a live order count
  - [x] Order detail shows every line at the price paid, plus the delivery address and totals breakdown
  - [x] Reorder refills the cart at today's prices and switches to the cart tab
  - [x] Reorder skips products the store no longer sells and says how many; an order of only discontinued items adds nothing and says so
  - [x] Empty history state links back to the catalog
  - [x] **No invented delivery status.** There is no fulfilment behind this app, so no "Shipped" badge — a test asserts none of those words appear
  - [x] 10 new tests; verified live: history showed 2 x $79.95 paid while the catalog now sells that product at $109.95, and reorder put it in the cart at $109.95

- [x] **Task 17 — Profile and settings, persisted dark mode** (S, needs T13, T16) — DONE (uncommitted)
  - [x] `SettingsProvider` owns the theme; the app root watches only it, so a cart change does not rebuild the whole app
  - [x] Three-way picker (System / Light / Dark) — a switch would strand anyone who tried Dark with no way back to the device setting
  - [x] Applies instantly and survives restart; verified live with the browser in dark mode and the app held to Light
  - [x] About card with the app version
  - [x] "Erase local data" behind a confirmation — clears cart, wishlist, orders, search history and session **through the providers**, so memory and disk cannot disagree
  - [x] Signed-out profile keeps its sign-in and register calls to action; sign-out still confirms first (Task 13)
  - [x] 10 new tests, including an app-level one asserting `MaterialApp.themeMode` changes and comes back after a restart

- [x] **Task 18 — Offline resilience: catalog cache** (M, needs T6, T7) — DONE (uncommitted)
  - [x] `CatalogProvider` seeds from the cache **synchronously in its constructor**, so a second launch opens on products, not a spinner
  - [x] A seeded start refreshes in the background rather than flashing skeletons over products already on screen
  - [x] A failed refresh keeps the working page and raises an offline banner instead of replacing it with an error
  - [x] Offline with no cache still shows the full error + retry state
  - [x] A successful refresh rewrites the cache and clears the banner; an empty response clears it too rather than pretending
  - [x] `OfflineBanner` says how old the data is in plain words ("12 minutes ago", "3 days ago")
  - [x] `LocalStore.writeCachedCatalog` now writes catalog and timestamp together — a reader that finds one must find the other
  - [x] 12 new tests
  - Deviation: caching lives in `CatalogProvider`, not a repository decorator as the plan sketched. The provider needs a synchronous read for the instant first paint, and splitting the cache across two layers would have meant reading it in both.
  - **Not verified live:** the offline banner. Simulating a dead network in the browser pane could not be made to work, and the pane's gestures/screenshots were flaky. Cache writing was confirmed live; the offline states rest on the three widget tests that drive `HomePage` directly.

- [x] **Task 19 — Accessibility and polish pass** (M, needs T7-T18) — DONE (uncommitted)
  - [x] `test/a11y_test.dart` sweeps all 13 screens at 320dp and again at 2.0x text scale, asserts every `IconButton` carries a tooltip, and measures tap targets
  - [x] **Seven real overflows found and fixed**, all invisible at desktop size:
    - product grid cards overflowed 16px at 2.0x — the aspect ratio now loosens with the text scale
    - checkout city/postal fields overflowed at 320dp — they stack when they do not fit
    - the theme picker overflowed 97px — three segments of icon + label cannot fit a narrow phone at 2x, so it becomes a stacked list
    - checkout section headings, review lines and totals, order-history totals, order-detail lines and the profile phone row all needed `Flexible`
  - [x] Contrast tests widened from 3 pairs to the 7 the app actually paints, in both themes, plus the fixed colors on the white product plate
  - [x] Found by that: the fallback image glyph was **2.4:1** against its placeholder, below the 3:1 WCAG asks of a non-text element. Darkened to 4.1:1
  - [x] Card title and price merged into one spoken node; haptics on add-to-cart and save
  - [x] 29 new tests (289 total)

- [x] **Task 20 — README rewrite** (XS, needs T19) — DONE (uncommitted)
  - [x] Every listed feature now exists. The old one claimed Riverpod (the app uses Provider), clean architecture, sorting by popularity, price-range filters and review display — none of which were ever built
  - [x] Demo scope stated at the top: catalog real and read-only, accounts/orders/delivery simulated, **no payment taken and no card details collected**
  - [x] Setup instructions match the actual remote and directory name
  - [x] Documents the API constraints that shaped the code (ignored `offset` and `q`, 20 products)
  - [x] Accessibility guarantees and known limitations stated, including why orders carry no delivery status

### ▣ Checkpoint D — Complete
- [x] All 20 tasks meet their acceptance criteria
- [x] `flutter analyze` clean under `strict-casts` and `strict-raw-types`
- [x] 289 tests green across 22 files; none touch the network
- [x] `flutter build web` succeeds; app verified running
- [x] README accurate
- [ ] Human review · Tasks 13-20 still awaiting your commit

---

## Defect Index (see plan.md for evidence)

| ID | Defect | Fixed by |
|----|--------|----------|
| B1 | Home never loads products (blank screen) | Task 7 |
| B2 | Login crashes on unregistered route `/` | Task 8 |
| B3 | Cart / Search / Login unreachable | Task 8 |
| B4 | Cart `FutureBuilder` network loop | Task 8 (pulled forward) |
| B5 | Cart shows "Product not found" for id > 10 | Task 8 (pulled forward) |
| B6 | Infinite scroll duplicates (API ignores `offset`) | Tasks 5, 7 |
| B7 | Search returns all 20 products (API ignores `q`) | Tasks 5, 11 — fixed |
| B8 | `Product.fromJson` null crash | Task 4 |
| B9 | Errors swallowed, no timeout, no retry | Tasks 5, 7 |
| B10 | `flutter test` red (default counter test) | Task 3 |
| B11 | `SearchPage` controller leak / setState after dispose | Task 11 — fixed |
| B12 | Product detail overflow | Task 9 |

## Decisions (answered 2026-09-08)

- [x] **Platforms:** all six — Android, iOS, web, Windows, macOS, Linux. Layouts must be responsive, and
      every package chosen must support all six (`shared_preferences`, `cached_network_image`, `intl` do).
- [x] **Auth:** stays a local simulation. No backend, no real credentials, no payment data.
- [x] **Brand color:** `#3D5AFE` (indigo). Seeds both Material 3 schemes.
