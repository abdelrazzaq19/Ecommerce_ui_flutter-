# Implementation Plan: Ecommerce App — UI/UX Modernization, Bug Fixes, Real-World Features

**Project:** `C:\Users\ASUS\projects\Ecommerce` (Flutter 3.47.2 / Dart 3.13.2, Provider + http, FakeStore API)
**Date:** 2026-09-08
**Status:** Approved. Phase 0 in progress — Tasks 1 and 3 complete.

---

## Overview

The app is an early-stage Flutter e-commerce client (518 lines across 11 Dart files) backed by
`https://fakestoreapi.com`. `flutter analyze` is clean, but the app is effectively non-functional at
runtime: the home page never triggers its first product fetch, the login page navigates to an
unregistered route, and the cart page starts an unbounded network loop. The UI is default Material 2
`ListTile` scaffolding with no design system.

This plan does three things in dependency order:

1. **Foundation** — modern theme/design system, dependency upgrade, a real test harness.
2. **Correctness** — fix the runtime-breaking defects in the data layer and navigation.
3. **Product** — modernize every screen and add features a real shopper expects (persistent cart,
   wishlist, checkout, order history, filters/sort, offline resilience, dark mode).

Work is sliced vertically: each task after the foundation delivers one complete, demoable user path
(state + UI + verification), not a horizontal layer.

---

## Current State: Verified Findings

### Runtime-breaking defects

| # | Defect | Evidence | Impact |
|---|--------|----------|--------|
| B1 | Home page shows a permanently blank list | `ProductProvider.fetchProducts()` is never called on init; the only trigger is a scroll notification, and an empty `ListView` cannot scroll | App looks broken on first launch |
| B2 | Login button crashes | `login_page.dart:36` calls `Navigator.pushReplacementNamed(context, '/')`, but `MaterialApp` in `main.dart` declares only `home:` — no `routes` table | Unhandled route exception |
| B3 | Cart, Search and Login are unreachable | `HomePage` has no navigation affordance to any other screen | Three of five screens are dead code |
| B4 | Cart page issues unbounded network requests | `cart_page.dart:16` puts `cartProvider.fetchProducts()` in `FutureBuilder(future:)`, and that method calls `notifyListeners()` — the rebuild creates a new future, forever | Battery/data drain, UI never settles |
| B5 | Cart items show "Product not found" | `CartProvider` keeps a second product cache and only fetches 10 items, so any product with `id > 10` cannot be resolved | Broken cart for most of the catalog |
| B6 | Infinite scroll appends duplicates forever | Verified: `GET /products?limit=3&offset=2` ignores `offset` and returns ids 1,2,3. The catalog is only **20 products** total | Duplicate keys, unbounded memory growth |
| B7 | Search returns the entire catalog for every query | Verified: `GET /products?q=shirt` returns all 20 products — `q` is not supported by the API. Also fires one request per keystroke, with no debounce | Search feature does not work |
| B8 | `Product.fromJson` crashes on unexpected payloads | `json['rating']['rate']` and `json['price'].toDouble()` assume non-null types | Whole list fails on one malformed item |
| B9 | Network errors are silently swallowed | `product_provider.dart` has an empty `catch (e)` block; `ApiService` sets no timeout | User sees an empty screen with no explanation and no retry |
| B10 | `flutter test` is red | `test/widget_test.dart` is the untouched default counter test asserting `find.text('0')` | No safety net; CI cannot be trusted |
| B11 | `SearchPage` leaks and can `setState` after dispose | `_searchController` is never disposed; `setState` runs after `await` with no `mounted` guard | Leak plus "setState called after dispose" exception |
| B12 | Product detail overflows on small screens | Unscrollable `Column` with a full-size `Image.network` and long description | Overflow stripes |

### UI/UX gaps

- Material 2 `primarySwatch: Colors.blue`, no `ColorScheme.fromSeed`, no Material 3, no dark mode.
- Every list is a bare `ListTile`; no product cards, no grid, no imagery hierarchy, no empty states.
- No loading skeletons, no pull-to-refresh, no retry affordance, no error states.
- `Image.network` with no `loadingBuilder`/`errorBuilder`; unbounded image sizes in list rows.
- Raw double prices render as `$219.9` or with floating-point noise instead of formatted currency.
- No app shell: no bottom navigation, no cart badge, no back-stack strategy.
- No accessibility work: no semantics labels, unverified contrast and tap-target sizes.

### Feature gaps vs. the README's own claims

The README advertises product sorting, review display, and registration with name/email/phone/password
validation. None of these exist in `lib/`. Cart quantity cannot be decremented, nothing persists across
restarts, and there is no checkout.

### Housekeeping

- `pubspec.yaml` carries ~55 lines of commented-out duplicate content above the real manifest.
- `http: ^0.13.4` (current: 1.x), `flutter_lints: ^4.0.0` (current: 6.0.0).
- No `assets/` directory declared; README is still half Flutter boilerplate.

---

## Architecture Decisions

1. **Client-side catalog, not server pagination.** The API ignores `offset` and `q`, and the catalog is
   20 items. Fetch all products once, then paginate, search, filter and sort in memory. This removes
   B6 and B7 at the root instead of papering over them.
2. **Single source of truth for products.** `CatalogProvider` owns the product list; `CartProvider` and
   `WishlistProvider` store only ids and resolve through it. This removes B5 and the duplicate cache.
3. **Stay on Provider.** The app already uses it and it is adequate at this size. Migrating to Riverpod
   or bloc would be churn this plan does not buy.
4. **Repository plus typed results.** `ProductRepository` wraps `ApiService` and returns explicit
   success / empty / failure states so the UI can render loading, error-with-retry, and empty
   distinctly (fixes B9).
5. **Local persistence via `shared_preferences`.** Cart, wishlist, session, theme mode, search history
   and orders survive restarts. No backend exists, so auth and orders are honest local simulations —
   stated in the UI and README rather than implied to be real.
6. **Material 3 with a seeded color scheme and a token file.** One `AppTheme` plus spacing/radius
   tokens; screens never hard-code colors or paddings.
7. **Widget tests over golden tests.** Goldens are brittle across platforms; widget tests asserting
   states (loading/error/empty/content) give better value per line here.

## Dependency Graph

```
pubspec (deps) ────────────┐
                           │
theme/design tokens ───────┼──> app shell (nav + routes)
                           │           │
Product model (safe) ──> ApiService ──> ProductRepository ──> CatalogProvider
                                                │                  │
                                                │                  ├──> Home (browse/grid/paging)
                                                │                  ├──> Detail
                                                │                  ├──> Search + history
                                                │                  └──> Filter + sort
                                                │
LocalStore (shared_preferences) ──> CartProvider ──> Cart UI ──> Checkout ──> Orders
                                └──> WishlistProvider ──> Wishlist UI
                                └──> AuthProvider ──> Login / Register ──> checkout guard
                                └──> SettingsProvider ──> theme toggle
```

Implementation order follows this graph bottom-up.

---

## Task List

### Phase 0: Foundation
- [ ] Task 1: Clean `pubspec.yaml` and upgrade dependencies
- [ ] Task 2: Material 3 design system and theme tokens
- [ ] Task 3: Replace the default counter test with a real test harness

### Checkpoint A: Foundation

### Phase 1: Data Layer Correctness
- [ ] Task 4: Null-safe `Product` model with category and rating count
- [ ] Task 5: `ApiService` + `ProductRepository` with timeouts and typed errors
- [ ] Task 6: `LocalStore` persistence service

### Checkpoint B: Data Layer

### Phase 2: Vertical Feature Slices
- [ ] Task 7: Home browse — first load, client-side paging, states, product cards
- [ ] Task 8: App shell — bottom navigation, named routes, cart badge
- [ ] Task 9: Product detail — scrollable, modernized, add-to-cart
- [ ] Task 10: Cart — fix the loop, quantity controls, persistence, currency formatting
- [ ] Task 11: Search — client-side, debounced, leak-free, with recent searches
- [ ] Task 12: Category filter and sort
- [ ] Task 13: Auth — login, register with validation, persisted session
- [ ] Task 14: Wishlist

### Checkpoint C: Core Shopping Flow

### Phase 3: Real-World Features and Polish
- [ ] Task 15: Checkout flow with address form and order confirmation
- [ ] Task 16: Order history and reorder
- [ ] Task 17: Profile and settings with persisted dark mode
- [ ] Task 18: Offline resilience — catalog cache and connectivity handling
- [ ] Task 19: Accessibility and polish pass
- [ ] Task 20: Update README to match reality

### Checkpoint D: Complete

---

## Task Details

### Task 1: Clean `pubspec.yaml` and upgrade dependencies

**Description:** Delete the ~55 lines of commented-out duplicate manifest at the top of `pubspec.yaml`,
upgrade `http` to 1.x and `flutter_lints` to 6.x, and add the packages the rest of the plan needs
(`shared_preferences`, `intl`, `cached_network_image`). Adjust `ApiService` for any http 1.x API change
and declare an `assets/` folder.

**Acceptance criteria:**
- [ ] `pubspec.yaml` contains exactly one manifest with no commented duplicate block.
- [ ] `http ^1.5.0`, `provider ^6.1.5`, `shared_preferences ^2.5.0`, `intl ^0.20.0`,
      `cached_network_image ^3.4.0`, `flutter_lints ^6.0.0` resolve.
- [ ] `flutter pub get` succeeds and the app still compiles.

**Verification:**
- [ ] `flutter pub get`
- [ ] `flutter analyze` — no issues
- [ ] `flutter test`
- [ ] Manual: `flutter run -d chrome` still launches

**Dependencies:** None
**Files:** `pubspec.yaml`, `analysis_options.yaml`, `lib/services/api_service.dart`
**Scope:** S

---

### Task 2: Material 3 design system and theme tokens

**Description:** Replace `primarySwatch: Colors.blue` with a Material 3 theme built from
`ColorScheme.fromSeed`, in light and dark variants, plus a token file for spacing, radii and elevation
and a shared text theme. Wire both themes into `MaterialApp` with `themeMode: ThemeMode.system` (the
persisted toggle arrives in Task 17).

**Acceptance criteria:**
- [ ] `lib/theme/app_theme.dart` exposes `AppTheme.light` and `AppTheme.dark` with `useMaterial3: true`.
- [ ] `lib/theme/app_tokens.dart` defines the spacing/radius scale used by every later screen.
- [ ] After this task's refactor of `main.dart`, no screen hard-codes a raw `Color` or a magic padding number.

**Verification:**
- [ ] `flutter analyze`
- [ ] Manual: launch in light and dark (`flutter run -d chrome`, toggle the OS theme) — both render legibly

**Dependencies:** Task 1
**Files:** `lib/theme/app_theme.dart`, `lib/theme/app_tokens.dart`, `lib/main.dart`
**Scope:** S

---

### Task 3: Replace the default counter test with a real test harness

**Description:** Delete the boilerplate counter test (B10) and build a small harness: an in-memory
`FakeProductRepository`, a `pumpApp()` helper that wraps a widget in the providers and theme, and one
smoke test asserting the app boots to the home screen.

**Acceptance criteria:**
- [ ] `flutter test` is green.
- [ ] `test/helpers/pump_app.dart` and `test/helpers/fake_repository.dart` exist and are reused by later tests.
- [ ] The smoke test fails if `MaterialApp` does not build.

**Verification:**
- [ ] `flutter test`
- [ ] `flutter analyze`

**Dependencies:** Task 1
**Files:** `test/widget_test.dart`, `test/helpers/pump_app.dart`, `test/helpers/fake_repository.dart`
**Scope:** S

---

### Checkpoint A: Foundation

- [ ] `flutter analyze` reports no issues
- [ ] `flutter test` is green
- [ ] App launches in light and dark mode
- [ ] Human review before proceeding

---

### Task 4: Null-safe `Product` model with category and rating count

**Description:** Harden `Product.fromJson` against nulls and unexpected types (B8), and add the
`category` and `rating.count` fields that Tasks 9 and 12 need. Add `toJson` for the offline cache
(Task 18) and value equality for list diffing.

**Acceptance criteria:**
- [ ] `Product.fromJson` returns a valid object for a payload missing `rating`, `description` or `image`.
- [ ] `price` parses from `int`, `double` or a numeric `String` without throwing.
- [ ] `category` and `ratingCount` are exposed; `toJson()` round-trips through `fromJson`.

**Verification:**
- [ ] `flutter test test/models/product_test.dart` — happy path, missing rating, null price, string price
- [ ] `flutter analyze`

**Dependencies:** Task 3
**Files:** `lib/models/product.dart`, `test/models/product_test.dart`
**Scope:** S

---

### Task 5: `ApiService` + `ProductRepository` with timeouts and typed errors

**Description:** Remove the `offset` and `q` query parameters the API ignores (B6, B7). Add a
10-second timeout, an `ApiException` with a human-readable message, a `fetchAllProducts()` call and a
`fetchCategories()` call. Introduce `ProductRepository` returning a sealed result so the UI can
distinguish loading, empty, content and failure (B9). Make the `http.Client` injectable for tests.

**Acceptance criteria:**
- [ ] No request sends `offset` or `q`.
- [ ] A non-200 response, a timeout and a malformed body each produce `ApiException` with a distinct message — never an empty catch.
- [ ] `fetchCategories()` returns the four live categories.
- [ ] `ProductRepository` takes an injected client in tests; the test suite makes no live network call.

**Verification:**
- [ ] `flutter test test/services/` — mocked 200, 500, timeout, malformed JSON
- [ ] `flutter analyze`
- [ ] Manual: with the device offline, the repository surfaces a failure rather than hanging

**Dependencies:** Task 4
**Files:** `lib/services/api_service.dart`, `lib/services/api_exception.dart`, `lib/repositories/product_repository.dart`, `test/services/api_service_test.dart`
**Scope:** M

---

### Task 6: `LocalStore` persistence service

**Description:** One thin `shared_preferences` wrapper owning every persisted key: cart, wishlist,
session, theme mode, search history, orders and the cached catalog. Keys and JSON codecs live here so
no provider touches `SharedPreferences` directly.

**Acceptance criteria:**
- [ ] `LocalStore` exposes typed read/write for each key with sane defaults on first launch.
- [ ] Corrupted or partially written JSON returns the default instead of throwing.
- [ ] Tests pass using `SharedPreferences.setMockInitialValues`.

**Verification:**
- [ ] `flutter test test/services/local_store_test.dart`
- [ ] `flutter analyze`

**Dependencies:** Task 4
**Files:** `lib/services/local_store.dart`, `test/services/local_store_test.dart`
**Scope:** S

---

### Checkpoint B: Data Layer

- [ ] Unit tests cover model parsing, API errors and persistence
- [ ] `flutter test` green, `flutter analyze` clean
- [ ] No test performs a live network call
- [ ] Human review before proceeding

---

### Task 7: Home browse — first load, client-side paging, states, product cards

**Description:** The core fix. `CatalogProvider` loads the full catalog once on init (B1), exposes a
loading / error / empty / ready state, and pages it client-side in batches of 8. Replace the `ListTile`
list with a responsive two-column product card grid: cached image, title, formatted price, star rating,
wishlist heart placeholder and an add-to-cart button. Add skeleton placeholders while loading, an error
state with a Retry button, and pull-to-refresh.

**Acceptance criteria:**
- [ ] Products appear on first launch with no user interaction.
- [ ] Scrolling to the bottom appends the next page and stops cleanly at 20 items with an end-of-results marker — no duplicates.
- [ ] Network failure renders an error message plus a working Retry button, not a blank screen.
- [ ] Pull-to-refresh re-fetches and replaces the list.
- [ ] Images show a placeholder while loading and a fallback icon on failure.

**Verification:**
- [ ] `flutter test test/views/home_page_test.dart` — asserts loading, error+retry, and content states via `FakeProductRepository`
- [ ] Manual: cold start shows products; scroll to the end; enable airplane mode and pull to refresh

**Dependencies:** Tasks 2, 5
**Files:** `lib/state/catalog_provider.dart`, `lib/views/home_page.dart`, `lib/widgets/product_card.dart`, `lib/widgets/app_states.dart`, `test/views/home_page_test.dart`
**Scope:** M

---

### Task 8: App shell — bottom navigation, named routes, cart badge

**Description:** Add an `AppShell` with a bottom navigation bar (Home, Search, Wishlist, Cart, Profile)
so every screen is reachable (B3), and register a named-route table including `/` so the login redirect
stops crashing (B2). The cart tab shows a live item-count badge.

**Acceptance criteria:**
- [ ] All five destinations are reachable from the shell and each keeps its own scroll position.
- [ ] `Navigator.pushReplacementNamed(context, '/')` resolves — no unknown-route exception.
- [ ] The cart badge updates immediately when an item is added.
- [ ] Android/browser back from a detail page returns to the correct tab.

**Verification:**
- [ ] `flutter test test/views/app_shell_test.dart` — tap each destination, assert the expected screen
- [ ] Manual: add to cart from home, confirm the badge increments, log in and confirm the redirect

**Dependencies:** Task 7
**Files:** `lib/app.dart`, `lib/routes.dart`, `lib/views/app_shell.dart`, `lib/main.dart`
**Scope:** M

---

### Task 9: Product detail — scrollable, modernized, add-to-cart

**Description:** Rebuild the detail page: `CustomScrollView` with a collapsing image header (fixing the
overflow, B12), title, formatted price, star rating with review count, category chip, expandable
description, quantity stepper, and a sticky bottom bar with Add to Cart plus a confirmation snackbar
that links to the cart. Hero-animate the image from the card.

**Acceptance criteria:**
- [ ] No overflow at 320 dp width or at 2.0x text scale.
- [ ] Add to Cart adds the selected quantity and shows a snackbar with a "View cart" action.
- [ ] Rating renders as stars plus the numeric review count from the API.

**Verification:**
- [ ] `flutter test test/views/product_detail_test.dart`
- [ ] Manual: open a long-description product in a narrow window, scroll to the end, add 3 to cart

**Dependencies:** Tasks 7, 8
**Files:** `lib/views/product_detail_page.dart`, `lib/widgets/rating_stars.dart`, `lib/widgets/quantity_stepper.dart`, `test/views/product_detail_test.dart`
**Scope:** M

---

### Task 10: Cart — fix the loop, quantity controls, persistence, currency formatting

**Description:** Rewrite `CartProvider` to store `{productId: quantity}` only, resolving products
through `CatalogProvider` (B5), and delete the `FutureBuilder(future: fetchProducts())` anti-pattern
(B4). Add increment/decrement/remove with undo, a subtotal/shipping/total summary formatted through
`intl` `NumberFormat.currency` (fixing raw double output), an illustrated empty state, and persistence
via `LocalStore`.

**Acceptance criteria:**
- [ ] Opening the cart issues zero network requests and settles in one frame.
- [ ] Quantity increment/decrement works; decrementing to zero removes the row and offers Undo.
- [ ] All prices render as `$1,234.50` — two decimals, thousands separator.
- [ ] The cart survives an app restart.
- [ ] The empty cart shows a message and a "Browse products" button, not a blank list.

**Verification:**
- [ ] `flutter test test/state/cart_provider_test.dart` — add, increment, decrement-to-zero, total arithmetic, persistence round-trip
- [ ] Manual: add 3 products, restart the app, confirm the cart is intact

**Dependencies:** Tasks 6, 7, 8
**Files:** `lib/state/cart_provider.dart`, `lib/views/cart_page.dart`, `lib/widgets/cart_item_tile.dart`, `lib/utils/formatters.dart`, `test/state/cart_provider_test.dart`
**Scope:** M

---

### Task 11: Search — client-side, debounced, leak-free, with recent searches

**Description:** Replace the broken server search (B7) with in-memory filtering over the loaded catalog
across title, description and category. Debounce input by 300 ms, dispose the controller and guard
`setState` with `mounted` (B11). Add recent-search chips persisted in `LocalStore`, a clear button, and
a distinct "no results for X" state.

**Acceptance criteria:**
- [ ] Typing "shirt" returns only matching products, not all 20.
- [ ] Search is case-insensitive and matches partial words.
- [ ] Fast typing produces at most one filter pass per 300 ms and no "setState after dispose" exception.
- [ ] Recent searches persist across restart and are tappable.

**Verification:**
- [ ] `flutter test test/views/search_page_test.dart` — query filtering, empty query, no-results state, rapid input
- [ ] Manual: type and delete quickly, navigate away mid-search, confirm no console exceptions

**Dependencies:** Tasks 6, 7, 8
**Files:** `lib/views/search_page.dart`, `lib/state/search_provider.dart`, `lib/widgets/search_field.dart`, `test/views/search_page_test.dart`
**Scope:** M

---

### Task 12: Category filter and sort

**Description:** Deliver the sorting the README already promises. A horizontal category chip row
(All plus the four API categories) and a sort bottom sheet: price low-to-high, price high-to-low,
rating, and name A-Z. Filter and sort compose with search and survive paging.

**Acceptance criteria:**
- [ ] Selecting a category narrows the grid and updates the result count.
- [ ] Each sort order produces a verifiably correct sequence.
- [ ] Filter, sort and search combine correctly; clearing filters restores all 20 products.

**Verification:**
- [ ] `flutter test test/state/catalog_filter_test.dart` — each sort comparator and combined filter cases
- [ ] Manual: filter to "jewelery", sort by price descending, confirm the order

**Dependencies:** Tasks 7, 11
**Files:** `lib/state/catalog_provider.dart`, `lib/widgets/category_chips.dart`, `lib/widgets/sort_sheet.dart`, `test/state/catalog_filter_test.dart`
**Scope:** M

---

### Task 13: Auth — login, register with validation, persisted session

**Description:** Turn the stub `AuthProvider` into a credible local auth simulation: a `Form`-based
login with email and password validation, a registration page validating name, email, phone and
password strength (the README's stated requirement), show/hide password, inline field errors, a loading
state on submit, and a session persisted through `LocalStore` so the user stays signed in.

**Acceptance criteria:**
- [ ] Invalid email, short password, malformed phone and empty name each show a specific inline error and block submission.
- [ ] A successful login persists the session; restarting the app keeps the user signed in.
- [ ] Logout clears the session and returns to the signed-out profile state.
- [ ] The screen labels this as a local demo account — no false claim of a real backend.

**Verification:**
- [ ] `flutter test test/views/auth_test.dart` — each validation rule, successful login, logout, session restore
- [ ] Manual: register, close the app, reopen, confirm still signed in

**Dependencies:** Tasks 6, 8
**Files:** `lib/state/auth_provider.dart`, `lib/views/login_page.dart`, `lib/views/register_page.dart`, `lib/utils/validators.dart`, `test/views/auth_test.dart`
**Scope:** M

---

### Task 14: Wishlist

**Description:** A persisted favorites list: a heart toggle on the product card and detail page, a
wishlist tab with an empty state, move-to-cart, and remove.

**Acceptance criteria:**
- [ ] Tapping the heart toggles state instantly on both the card and the detail page.
- [ ] The wishlist survives an app restart.
- [ ] Move-to-cart adds the item and removes it from the wishlist.

**Verification:**
- [ ] `flutter test test/state/wishlist_provider_test.dart`
- [ ] Manual: favorite two products, restart, confirm both are present

**Dependencies:** Tasks 6, 7, 8
**Files:** `lib/state/wishlist_provider.dart`, `lib/views/wishlist_page.dart`, `lib/widgets/product_card.dart`, `test/state/wishlist_provider_test.dart`
**Scope:** M

---

### Checkpoint C: Core Shopping Flow

- [ ] End-to-end: launch, browse, filter, search, open detail, add to cart, adjust quantity, restart, cart intact
- [ ] Every defect B1-B12 is fixed and covered by at least one test
- [ ] `flutter analyze` clean, `flutter test` green
- [ ] Human review before proceeding

---

### Task 15: Checkout flow with address form and order confirmation

**Description:** A three-step checkout: shipping address form (name, phone, address, city, postal code)
with validation and a saved-address default, an order review with the item list and total, and a
confirmation screen with an order number. Checkout requires a signed-in session; otherwise it routes to
login and returns afterwards. The order is recorded locally — no payment is taken and no card details
are collected or entered anywhere in the app.

**Acceptance criteria:**
- [ ] Checkout from a signed-out state routes to login and resumes after signing in.
- [ ] Invalid or empty address fields block the Place Order button with inline errors.
- [ ] Placing an order clears the cart, writes the order to `LocalStore`, and shows a confirmation with an order id.
- [ ] The screen states plainly that this is a demo order with no real payment.

**Verification:**
- [ ] `flutter test test/views/checkout_test.dart` — auth guard, validation, cart cleared on success
- [ ] Manual: full purchase path from an empty cart to confirmation

**Dependencies:** Tasks 10, 13
**Files:** `lib/views/checkout_page.dart`, `lib/views/order_confirmation_page.dart`, `lib/state/order_provider.dart`, `lib/models/order.dart`, `test/views/checkout_test.dart`
**Scope:** M

---

### Task 16: Order history and reorder

**Description:** An order list on the profile tab, newest first, with status, date, item count and
total; a detail view with the line items; and a Reorder button that refills the cart.

**Acceptance criteria:**
- [ ] Orders persist across restart and are sorted newest first.
- [ ] Order detail shows every line item at its purchased price.
- [ ] Reorder repopulates the cart and navigates to it.
- [ ] Empty history shows a "no orders yet" state.

**Verification:**
- [ ] `flutter test test/views/order_history_test.dart`
- [ ] Manual: place two orders, restart, verify both and reorder one

**Dependencies:** Task 15
**Files:** `lib/views/order_history_page.dart`, `lib/views/order_detail_page.dart`, `lib/state/order_provider.dart`, `test/views/order_history_test.dart`
**Scope:** S

---

### Task 17: Profile and settings with persisted dark mode

**Description:** A profile tab showing the signed-in user (or a sign-in prompt), links to orders and
wishlist, a theme mode selector (System / Light / Dark) persisted through `LocalStore`, an app version
line, and logout with a confirmation dialog.

**Acceptance criteria:**
- [ ] Switching theme applies immediately and survives restart.
- [ ] The signed-out profile shows sign-in and register calls to action instead of empty fields.
- [ ] Logout asks for confirmation before clearing the session.

**Verification:**
- [ ] `flutter test test/views/settings_test.dart`
- [ ] Manual: set Dark, restart, confirm it stuck

**Dependencies:** Tasks 13, 16
**Files:** `lib/views/profile_page.dart`, `lib/state/settings_provider.dart`, `lib/app.dart`, `test/views/settings_test.dart`
**Scope:** S

---

### Task 18: Offline resilience — catalog cache and connectivity handling

**Description:** Cache the fetched catalog in `LocalStore` and serve it on launch while a refresh runs
in the background. On a failed refresh, keep showing cached data with a non-blocking "showing offline
data" banner instead of an error screen.

**Acceptance criteria:**
- [ ] Second launch renders products from cache before any network response arrives.
- [ ] With no connectivity, cached products still display, with a banner.
- [ ] With no connectivity and no cache, the full error-plus-retry state shows.
- [ ] A successful refresh silently replaces the cache and clears the banner.

**Verification:**
- [ ] `flutter test test/state/catalog_offline_test.dart` — cache hit, stale-while-revalidate, cold failure
- [ ] Manual: launch online, kill the app, go offline, relaunch

**Dependencies:** Tasks 6, 7
**Files:** `lib/repositories/product_repository.dart`, `lib/state/catalog_provider.dart`, `lib/widgets/offline_banner.dart`, `test/state/catalog_offline_test.dart`
**Scope:** M

---

### Task 19: Accessibility and polish pass

**Description:** A sweep across every screen: semantics labels on icon-only buttons, minimum 48x48 dp
tap targets, contrast checked in both themes, layouts verified at 2.0x text scale, consistent page
transitions, and haptics on cart actions.

**Acceptance criteria:**
- [ ] Every icon-only control has a semantics label.
- [ ] No overflow at 320 dp width or 2.0x text scale on any screen.
- [ ] All interactive targets are at least 48x48 dp.
- [ ] Text and interactive colors meet WCAG AA contrast in light and dark.

**Verification:**
- [ ] `flutter test` including a semantics assertion test per major screen
- [ ] Manual: navigate the app end-to-end at 2.0x text scale in both themes

**Dependencies:** Tasks 7-18
**Files:** `lib/widgets/*.dart`, `lib/views/*.dart`, `test/a11y_test.dart`
**Scope:** M

---

### Task 20: Update README to match reality

**Description:** Replace the Flutter boilerplate and the currently inaccurate feature list with what the
app actually does, how to run it, its architecture, and an explicit note that auth, orders and checkout
are local simulations against a read-only public API.

**Acceptance criteria:**
- [ ] Every listed feature exists in the code.
- [ ] Setup instructions work from a clean clone.
- [ ] The demo-only nature of auth, orders and payment is stated plainly.

**Verification:**
- [ ] Manual: follow the README from a fresh clone and reach a running app

**Dependencies:** Task 19
**Files:** `README.md`
**Scope:** XS

---

### Checkpoint D: Complete

- [ ] All 20 tasks meet their acceptance criteria
- [ ] `flutter analyze` clean; `flutter test` green
- [ ] Full flow verified manually on one real device or emulator
- [ ] README accurate
- [ ] Ready for review

---

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| FakeStore API changes shape or goes down | High | Repository returns typed failures; Task 18 caches the catalog; tests use a fake repository, never the live network |
| 20 products is too small to feel like a real store | Medium | Client-side paging in batches of 8 still demonstrates the pattern; note the constraint in the README rather than faking data |
| Rewriting `CartProvider` breaks the existing cart shape | Medium | The cart stores ids only; Task 10 lands with unit tests before the UI change |
| Scope creep across 20 tasks | Medium | Checkpoints A-D require human sign-off; Phase 3 can ship separately from Phase 2 |
| `http` 0.13 to 1.x upgrade breaks compilation | Low | Task 1 is isolated and verified by `flutter analyze` before anything else builds on it |
| No backend means auth and orders are simulated | Low | Stated explicitly in the UI and README; no credentials or payment data are ever collected |

## Definition of Done (applies to every task)

- `flutter analyze` reports no issues
- `flutter test` is green
- New behavior has at least one test
- No `print`, no commented-out code, no `TODO` without an owner
- No hard-coded colors or magic paddings outside `lib/theme/`
- Manually verified in both light and dark mode

## Open Questions

1. **Target platforms — ANSWERED.** All six: Android, iOS, web, Windows, macOS, Linux. Every layout must
   be responsive across phone, tablet and desktop widths, and every package must support all six
   (`shared_preferences`, `cached_network_image`, `intl` and `http` all do). Task 19 verification widens
   to include a desktop window size.
2. **Brand color — OPEN, blocks Task 2.** The user asked for "the brand color" but has not named one, and
   the project contains no brand asset, design file or existing palette to read it from. A hex value (or
   a logo to sample) is needed before the Material 3 seed can be chosen.
3. **Auth realism — ANSWERED.** Stays a local simulation. No backend, no real credential storage, and the
   UI states this plainly.
4. **Payments.** Out of scope. No card or payment details are collected anywhere.
5. **Phase 3 scope.** If time is short, which of Tasks 15-18 matter most? Checkout and order history are
   the most demo-visible.

---

## Parallelization

- **Sequential and blocking:** Tasks 1-8 — everything else builds on the theme, data layer and shell.
- **Safe to parallelize after Task 8:** Task 11 (search), Task 13 (auth), Task 14 (wishlist) touch
  disjoint files.
- **Needs coordination:** Tasks 10 and 15 share the cart contract — land Task 10 first.
