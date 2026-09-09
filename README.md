# Ecommerce

A Flutter storefront built on the public [FakeStore API](https://fakestoreapi.com), running on
Android, iOS, web, Windows, macOS and Linux from one codebase.

> **This is a demo app.** The product catalog is real and read-only. Everything else — accounts,
> orders, delivery — is simulated on your device. **No payment is ever taken and no card details are
> collected anywhere in the app.** Every screen that touches those areas says so on the screen
> itself, not just here.

---

## What it does

**Browse**
- Catalog grid that loads on launch, paged 8 at a time
- Category filter and five sort orders (featured, price up/down, top rated, name A–Z)
- Product detail with a collapsing image header, star rating, review count, quantity stepper
- Responsive: 2 columns on a phone, 3 on a tablet, 4 on a desktop window; bottom navigation below
  840dp, a side rail above it

**Search**
- Filters the loaded catalog across title, category and description
- Debounced 300ms, case-insensitive, partial match, title matches ranked first
- Recent searches, remembered on submit or when you open a result

**Cart**
- Quantity stepper per line, remove with undo, clear behind a confirmation
- Subtotal, delivery and total, with a free-delivery threshold
- Survives closing the app

**Saved**
- Heart on any product card or detail page, newest saved first
- Move to cart, remove with undo

**Account** *(local simulation)*
- Sign in and register, with real validation on name, email, phone and password
- Session survives a restart; signing out ends the session but keeps the account
- **No password is stored anywhere, not even hashed** — there is no server to check one against

**Checkout and orders** *(local simulation)*
- Shipping address form with per-field validation, prefilled from your last order
- Order history with every line at the price you paid, and reorder at today's prices
- **No payment step exists.** Nothing is charged and nothing ships

**Settings**
- Theme: System, Light or Dark, remembered across restarts
- Erase all local data, behind a confirmation

**Offline**
- The catalog is cached; a second launch opens on products before the network answers
- If a refresh fails, the products stay on screen with a banner saying how old they are
- With no cache and no network, a clear error with a retry

---

## Running it

Requires the Flutter SDK (this project is developed against 3.47, Dart 3.13).

```bash
git clone https://github.com/abdelrazzaq19/Ecommerce_ui_flutter-.git
cd Ecommerce_ui_flutter-
flutter pub get
flutter run
```

`flutter run` picks whatever device is connected. To choose one:

```bash
flutter run -d chrome
flutter run -d windows
flutter devices
```

## Tests

```bash
flutter test
flutter analyze
```

289 tests across 22 files: unit tests for parsing, pricing and persistence; widget tests for every
screen; an accessibility sweep that renders all 13 screens at 320dp and at 2.0x text scale.

**No test touches the network.** The API is faked at the `http.Client` and repository level, and
`shared_preferences` is mocked, so the suite is fast and does not fail because someone else's server
is down.

---

## How it is built

State is [`provider`](https://pub.dev/packages/provider). The layers are:

```
views/      screens
widgets/    reusable pieces (product card, empty and error states, banners)
state/      ChangeNotifiers: catalog, cart, wishlist, search, auth, orders, settings
repositories/  turns thrown failures into typed results the UI can switch on
services/   ApiService (HTTP), LocalStore (shared_preferences), ApiException
models/     Product, Order, UserSession
theme/      Material 3 themes seeded from one brand color, plus design tokens
utils/      validators, currency and date formatting
```

Two rules the code holds to:

- **One copy of the catalog.** `CatalogProvider` owns the products. The cart, wishlist and orders
  store ids and resolve through it, so nothing can drift out of sync.
- **Failures are values, not exceptions.** `ProductRepository` returns `Success`, `EmptyResult` or
  `Failure`, so "the store is empty" and "the request failed" can never be confused for each other
  in the UI.

### Working around the API

The FakeStore API shapes some decisions, and the code says so where it matters:

| What the API does | What the app does |
|---|---|
| Ignores `?offset=` — always returns from the first product | Fetches the catalog once and pages it in memory |
| Ignores `?q=` — returns all 20 products for any query | Filters in memory instead of calling a search endpoint |
| Has 20 products total | Pages 8 at a time and says "You have seen every product" at the end |
| Read-only, no accounts or orders | Accounts, orders and delivery are simulated on device |

## Accessibility

- Every icon-only control carries a label
- No layout overflows at 320dp or at 2.0x text scale — both asserted for all 13 screens
- Interactive targets are at least 48x48dp
- Text and interactive color pairs clear WCAG AA in both light and dark, asserted for the pairs the
  app actually paints

## Known limitations

- The catalog is 20 products, because that is what the API has
- Categories, prices and ratings come from the API and cannot be edited
- Orders have no delivery status, deliberately: there is no fulfilment behind this app, and a
  "Shipped" badge would be a fiction
- Accounts are per device. There is no password check, no recovery, and no sync
