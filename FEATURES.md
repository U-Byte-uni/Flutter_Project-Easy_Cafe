# Easy Cafe — Feature Inventory

> **App version:** 1.0.0  
> **Platform:** Flutter (Android, iOS, Web, Desktop targets present)  
> **Report generated from:** `main` branch

---

## Table of Contents
1. [Project Overview](#1-project-overview)
2. [Tech Stack & Dependencies](#2-tech-stack--dependencies)
3. [Data / Storage Layer](#3-data--storage-layer)
4. [Authentication & Authorization](#4-authentication--authorization)
5. [Core User-Facing Features](#5-core-user-facing-features)
   - 5.1 Menu Browsing (Home)
   - 5.2 Product Detail
   - 5.3 Shopping Cart
   - 5.4 Order Placement & History
   - 5.5 Favourites
   - 5.6 Weather-Based Suggestions
   - 5.7 AI Chatbot Assistant
   - 5.8 User Profile
   - 5.9 Settings
6. [Navigation](#6-navigation)
7. [State Management](#7-state-management)
8. [AI / External API Integrations](#8-ai--external-api-integrations)
9. [Theming & Styling](#9-theming--styling)
10. [Error Handling & Resilience](#10-error-handling--resilience)
11. [Environment Configuration](#11-environment-configuration)
12. [What Is NOT Present](#12-what-is-not-present)
13. [Key File Reference Map](#13-key-file-reference-map)

---

## 1. Project Overview

**Easy Cafe** is a mobile coffee-shop ordering app built with Flutter. Users can browse a menu, add items to a cart, place orders, save favourites, and get AI-driven coffee recommendations — all backed by a hosted Supabase (PostgreSQL) database.

---

## 2. Tech Stack & Dependencies

| Concern | Library / Service |
|---|---|
| UI framework | Flutter (Material 3, dark theme) |
| State management | `provider` ^6.1.2 |
| Backend / Auth / DB | `supabase_flutter` ^2.6.0 |
| AI chatbot & descriptions | OpenRouter REST API (`http` ^1.6.0) |
| Weather-based suggestions | OpenWeatherMap REST API |
| Google AI SDK (declared) | `google_generative_ai` ^0.4.0 *(imported but not currently wired up)* |
| Fonts | `google_fonts` ^6.2.1 (Poppins) |
| Date formatting | `intl` ^0.19.0 |
| Env var loading | `flutter_dotenv` ^5.1.0 |

> **`pubspec.yaml`** · **`pubspec.lock`**

---

## 3. Data / Storage Layer

### Supabase (PostgreSQL) — hosted cloud database

All persistent data lives in Supabase. Row-Level Security (RLS) is enabled on every table.

| Table | Purpose | RLS highlights |
|---|---|---|
| `categories` | Coffee categories (Cappuccino, Espresso, Latte, Flat White) | Public read |
| `products` | Menu items — name, description, price, image URL, category, roasted level, rating | Public read |
| `profiles` | One row per authenticated user; stores `full_name`, `avatar_url` | Owner read/write |
| `orders` | Orders placed by users — UUID id, total price, status (`Pending`/`Completed`/`Cancelled`) | Owner read/insert |
| `order_items` | Line items for each order — product_id, quantity, price | Owner read/insert via order FK |
| `favorites` | User ↔ product many-to-many; unique constraint prevents duplicates | Owner read/insert/delete |

> Schema source files: **`supabase_schema.sql`** (initial), **`supabase_update.sql`** (orders, favorites, profiles update)  
> Dart wrapper: **`lib/services/supabase_service.dart`**

### Local / In-memory
- Shopping cart state is held **only in memory** (`CartController`) and is lost on app restart — there is no local persistence layer (no SQLite / SharedPreferences / Hive).

---

## 4. Authentication & Authorization

- **Provider:** Supabase Auth (email + password)
- **Flows:**
  - **Sign Up** — email, password, and full name; Supabase auto-creates an `auth.users` row and a DB trigger inserts a matching `profiles` row.
  - **Sign In** — email + password via `signInWithPassword`.
  - **Sign Out** — clears the Supabase session and resets `AuthController._user` to `null`.
  - **Password Change** — in-app via `updateUser(UserAttributes(password: ...))`.
- **Session persistence:** Supabase SDK handles JWT refresh automatically.
- **Route guard:** `main.dart` wraps the app in a `Consumer<AuthController>`: authenticated → `MainNavigationWrapper`; unauthenticated → `LoginScreen`.
- **No social/OAuth providers** are wired up.

> **`lib/views/login_screen.dart`** · **`lib/controllers/auth_controller.dart`** · **`lib/services/supabase_service.dart`**

---

## 5. Core User-Facing Features

### 5.1 Menu Browsing (Home Screen)

- Displays all products in a 2-column `GridView`.
- **Category filter bar** — horizontal scrollable list; tapping a category filters the grid in real-time (via `CafeController.selectCategory`).
- **Live search** — text field above the grid calls `CafeController.searchProducts`, filtering by product name (case-insensitive).
- Shows a loading spinner while fetching; shows "No products found." when results are empty.
- Tapping a product card navigates to the Product Detail Screen.

> **`lib/views/home_screen.dart`** · **`lib/controllers/cafe_controller.dart`** · **`lib/widgets/product_card.dart`** · **`lib/widgets/category_item.dart`**

---

### 5.2 Product Detail Screen

- Full-bleed product image occupying the top half of the screen.
- **AI-generated description** — on load, calls `AIService.getProductDescription`; falls back to the stored DB description if the AI call fails.
- Displays product name, roast level, and star rating.
- **Size selector** — S / M / L pill buttons (visual-only; size is not factored into price or order data yet).
- **Favourite toggle** — heart icon syncs with Supabase `favorites` table in real-time.
- **Add to Cart** button — increments quantity if already in cart, shows a SnackBar confirmation.

> **`lib/views/product_detail_screen.dart`** · **`lib/services/ai_service.dart`** · **`lib/controllers/cart_controller.dart`**

---

### 5.3 Shopping Cart

- Lists all items currently in the cart with product image, name, price, and a quantity stepper (+/−).
- **Remove one** decrements quantity; at quantity 1, removes the item entirely.
- Shows total amount at the bottom.
- **Checkout** button:
  1. Shows a blocking progress dialog.
  2. Calls `SupabaseService.createOrder` → inserts into `orders` + `order_items`.
  3. On success: dismisses dialog, shows "Order placed successfully!" SnackBar, clears cart.
  4. On failure: shows error SnackBar.

> **`lib/views/cart_screen.dart`** · **`lib/controllers/cart_controller.dart`** · **`lib/services/supabase_service.dart`**

---

### 5.4 Order Placement & History

- **Order History Screen** fetches orders for the logged-in user joined with `order_items` and `products`.
- Each order card shows: order ID (first 8 chars of UUID), date (formatted `MMM dd, yyyy`), total price, and a colour-coded status badge (`Pending` = orange, `Completed` = green, `Cancelled` = red).
- Data is loaded with a `FutureBuilder`; shows "No orders yet." when empty.

> **`lib/views/order_history_screen.dart`** · **`lib/services/supabase_service.dart`**

---

### 5.5 Favourites

- Dedicated **Favourites Screen** in the bottom navigation and also reachable from the Profile Screen.
- Shows all products the user has hearted, in the same `ProductCard` grid style as Home.
- Tapping a favourite navigates to its Product Detail Screen.
- **Clear all** option via `CafeController.clearAllFavorites` (deletes all `favorites` rows for the user).
- Favourite state is synced to Supabase on every toggle.

> **`lib/views/favorites_screen.dart`** · **`lib/controllers/cafe_controller.dart`**

---

### 5.6 Weather-Based Suggestions

- **Suggestions Screen** fetches current weather for a configurable city (env var `DEFAULT_LOCATION`, default: London) from OpenWeatherMap.
- Displays temperature, weather condition icon (sunny / cloudy / rainy / other), and a localised coffee recommendation:
  - < 15 °C → hot drink (Hot Chocolate / Warm Latte)
  - Rainy → Espresso or Mocha
  - > 25 °C → Iced Coffee / Cold Brew
  - Otherwise → Classic Cappuccino
- Falls back gracefully ("Perfect time for a coffee anyway!") if the API call fails.
- A placeholder section ("Special for this weather") exists for a filtered product list — **not yet implemented**.

> **`lib/views/suggestions_screen.dart`** · **`lib/services/weather_service.dart`**

---

### 5.7 AI Chatbot Assistant

- A **floating action button** (chat bubble icon) on every tab opens a bottom sheet chat overlay.
- Powered by the **OpenRouter free-tier router** (`openrouter/free` model) which auto-selects an available free LLM.
- System prompt includes the current live menu so the bot can answer questions about items, prices, cheapest/most premium options, etc.
- Conversation is rendered in a chat-bubble list; "typing" state shows a linear progress bar.
- On network error or SocketException, returns a friendly fallback message.
- Configuration can be tested programmatically via `AIService.testConfiguration()`.

> **`lib/widgets/chat_bot_overlay.dart`** · **`lib/services/ai_service.dart`**

---

### 5.8 User Profile

- Shows avatar (network image or default person icon), display name (from `profiles.full_name` or auth metadata).
- Menu items navigate to: **My Orders**, **Favourites**, **Settings**, **Help Center** (stub — no action yet).
- **Logout** button at the bottom calls `AuthController.signOut`.

> **`lib/views/profile_screen.dart`**

---

### 5.9 Settings

- **Profile Picture URL** — paste an image URL to update the avatar stored in Supabase.
- **Full Name** — editable text field, saved to `profiles` table.
- **New Password** — change password via Supabase Auth (only updated if the field is non-empty).
- **Account Management** section includes a second Logout option.
- Save button shows a loading spinner and pops back on success.

> **`lib/views/settings_screen.dart`** · **`lib/controllers/auth_controller.dart`**

---

## 6. Navigation

Navigation uses Flutter's built-in `Navigator` (push/pop). The main shell is a `BottomNavigationBar` with five tabs:

| Index | Icon | Screen |
|---|---|---|
| 0 | Home | `HomeScreen` |
| 1 | Favorite | `FavoritesScreen` |
| 2 | Auto-Awesome | `SuggestionsScreen` |
| 3 | Shopping Bag | `CartScreen` |
| 4 | Person | `ProfileScreen` |

Secondary screens (Product Detail, Order History, Settings) are pushed on top of this shell.

> **`lib/views/main_navigation_wrapper.dart`**

---

## 7. State Management

Three `ChangeNotifier` providers registered in `main.dart` via `MultiProvider`:

| Provider | Responsibility |
|---|---|
| `AuthController` | Current user, profile data, loading flag; auth operations |
| `CafeController` | Product list, category list, favourite IDs, search query, selected category |
| `CartController` | In-memory cart items map (productId → `CartItem`), total amount |

> **`lib/controllers/`**

---

## 8. AI / External API Integrations

| Integration | API / Service | Key env var | What it powers |
|---|---|---|---|
| OpenRouter | `https://openrouter.ai/api/v1/chat/completions` | `OPENROUTER_API_KEY` | Chatbot + AI product descriptions |
| OpenWeatherMap | `https://api.openweathermap.org/data/2.5/weather` | `OPENWEATHER_API_KEY` | Suggestions screen |
| Supabase | Supabase hosted project | `SUPABASE_URL`, `SUPABASE_ANON_KEY` | Auth, DB, all data |
| google_generative_ai | (declared) | — | Imported but not actively used |

---

## 9. Theming & Styling

- **Dark theme only** — no light mode or theme switcher.
- Custom `AppTheme` (`lib/theme/app_theme.dart`):
  - Background: `#0C0F14` (near-black)
  - Primary accent: `#D17842` (warm orange/brown — "coffee" colour)
  - Card surface: `#141921` (dark navy)
  - Secondary text: `#52555A` (muted grey)
- Global font: **Poppins** via `google_fonts`, applied to the entire `TextTheme`.
- Material 3 (`useMaterial3: true`) with a custom `ColorScheme.dark`.
- Consistent `ElevatedButton`, `InputDecoration`, and `AppBar` styles defined once in the theme.
- No localisation, no right-to-left support, no accessibility overrides (no `Semantics` labels).

---

## 10. Error Handling & Resilience

- All async operations wrapped in `try/catch`; failures surfaced to users via `SnackBar`.
- AI service detects `SocketException` specifically to show a network-specific message.
- Weather service returns a hard-coded mock payload `{temp: 25, condition: 'Clear'}` if the API call fails.
- AI product description falls back to the stored DB description on any error.
- `debugPrint` used throughout for development diagnostics.
- **No crash reporting** (no Firebase Crashlytics, Sentry, etc.).
- **No offline support** — the app requires an active internet connection for all features.

---

## 11. Environment Configuration

All secrets and config are loaded from a `.env` file (bundled as a Flutter asset):

```
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
OPENROUTER_API_KEY=...
OPENWEATHER_API_KEY=...
DEFAULT_LOCATION=London
```

> **`.env`** (not committed — listed in `.gitignore`), loaded by `flutter_dotenv`

---

## 12. What Is NOT Present

The following features were **not found** in the codebase:

- ❌ Admin / management panel
- ❌ Payments / payment gateway (no Stripe, PayPal, etc.)
- ❌ Table reservations
- ❌ Loyalty / rewards programme
- ❌ Push notifications
- ❌ Maps integration
- ❌ Localisation / i18n (single language — English only)
- ❌ Light theme / theme toggle
- ❌ Offline mode / local database caching
- ❌ Analytics or crash reporting
- ❌ Social login (Google, Apple, etc.)
- ❌ Image upload (avatar is URL-only)
- ❌ Order cancellation by user
- ❌ Size selection affecting price

---

## 13. Key File Reference Map

```
lib/
├── main.dart                          # Entry point; Supabase init; route guard
├── controllers/
│   ├── auth_controller.dart           # Auth state & operations
│   ├── cafe_controller.dart           # Menu, categories, favourites, search
│   └── cart_controller.dart           # In-memory cart
├── models/
│   ├── product.dart                   # Product data model
│   ├── category.dart                  # Category data model
│   └── cart_item.dart                 # CartItem + Order model classes
├── services/
│   ├── supabase_service.dart          # All Supabase DB + Auth calls
│   ├── ai_service.dart                # OpenRouter AI (chatbot + descriptions)
│   └── weather_service.dart           # OpenWeatherMap + recommendation logic
├── views/
│   ├── login_screen.dart              # Sign in / Sign up
│   ├── main_navigation_wrapper.dart   # Bottom nav shell + FAB chatbot
│   ├── home_screen.dart               # Menu grid, search, category filter
│   ├── product_detail_screen.dart     # Item detail, AI desc, size, add to cart
│   ├── cart_screen.dart               # Cart list, checkout
│   ├── favorites_screen.dart          # Saved items grid
│   ├── suggestions_screen.dart        # Weather-based coffee suggestion
│   ├── order_history_screen.dart      # Past orders list
│   ├── profile_screen.dart            # User profile hub
│   └── settings_screen.dart           # Edit profile, change password
├── widgets/
│   ├── chat_bot_overlay.dart          # AI chat bottom sheet
│   ├── product_card.dart              # Reusable product grid card
│   └── category_item.dart             # Reusable category filter chip
└── theme/
    └── app_theme.dart                 # Dark theme, colours, fonts

supabase_schema.sql                    # Initial DB schema (categories, products, profiles)
supabase_update.sql                    # Extended schema (orders, order_items, favorites)
pubspec.yaml                           # Dependencies
```
