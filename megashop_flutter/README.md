# Mega Shop Flutter Frontend

Frontend UI untuk aplikasi social commerce **Mega Shop** menggunakan Flutter.

## Installation & Run

```bash
cd megashop_flutter
flutter pub get
flutter devices
flutter run -d chrome
```

Untuk Android Emulator atau HP:

```bash
flutter run
```

Jika error:

```bash
flutter clean
flutter pub get
flutter run -d chrome
```

## Flutter Structure

```text
lib/
├── main.dart
├── app.dart
├── utils/
│   ├── app_colors.dart
│   └── api_constants.dart
├── models/
│   ├── product_model.dart
│   ├── user_model.dart
│   └── cart_model.dart
├── providers/
│   ├── auth_provider.dart
│   ├── product_provider.dart
│   └── cart_provider.dart
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── home/
│   │   ├── home_screen.dart
│   │   └── reels_screen.dart
│   ├── post/
│   │   └── create_post_screen.dart
│   ├── cart/
│   │   └── cart_screen.dart
│   └── profile/
│       └── profile_screen.dart
└── widgets/
    ├── product_card.dart
    └── bottom_nav_bar.dart
```

## Frontend Team Division

### Orang 1 — Home, Reels, Post

**Tanggung jawab:** Home feed, reels page, create post page, product card UI, dan bottom navigation.

**File yang dikerjakan:**
- `lib/app.dart`
- `lib/screens/home/home_screen.dart`
- `lib/screens/home/reels_screen.dart`
- `lib/screens/post/create_post_screen.dart`
- `lib/widgets/product_card.dart`
- `lib/widgets/bottom_nav_bar.dart`
- `lib/models/product_model.dart`
- `lib/providers/product_provider.dart`
- `lib/utils/app_colors.dart`

**Fitur yang dibuat:**
- Home feed UI
- Product list UI
- Reels UI
- Add to cart button UI
- Create product/post UI
- Bottom navigation

### Orang 2 — Auth, Cart, Profile

**Tanggung jawab:** Login/register page, cart page, profile page, state management, dan API constants.

**File yang dikerjakan:**
- `lib/screens/auth/login_screen.dart`
- `lib/screens/auth/register_screen.dart`
- `lib/screens/cart/cart_screen.dart`
- `lib/screens/profile/profile_screen.dart`
- `lib/models/user_model.dart`
- `lib/models/cart_model.dart`
- `lib/providers/auth_provider.dart`
- `lib/providers/cart_provider.dart`
- `lib/utils/api_constants.dart`

**Fitur yang dibuat:**
- Login UI
- Register UI
- Cart UI
- Profile UI
- State management sederhana
- Menyimpan base URL backend