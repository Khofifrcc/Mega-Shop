# Mega Shop Flutter Frontend

Frontend UI untuk aplikasi social commerce **Mega Shop** menggunakan Flutter.

## Prerequisites (Wajib Install Dulu!)

Sebelum menjalankan project ini, pastikan semua tools berikut sudah terinstall:

### 1. Flutter SDK
- Download di: https://docs.flutter.dev/get-started/install
- **Versi minimum:** Flutter 3.38.x (Dart 3.4+)
- Setelah install, jalankan `flutter doctor` untuk cek apakah sudah beres

### 2. Android Studio / VS Code
- **Android Studio:** https://developer.android.com/studio
  - Install plugin **Flutter** dan **Dart** di Android Studio
  - Buat Android Virtual Device (AVD) untuk emulator
- **VS Code (alternatif):** https://code.visualstudio.com
  - Install extension **Flutter** dari marketplace

### 3. Java JDK 17
- Download di: https://www.oracle.com/java/technologies/downloads/#java17
- Atau pakai JDK bawaan Android Studio (sudah termasuk)

### 4. Git
- Download di: https://git-scm.com/downloads
- Untuk pull project dari repository

### Cek Instalasi
Jalankan perintah ini, pastikan semua ✓ (centang hijau):
```bash
flutter doctor
```

## Installation & Run

> ⚠️ **PENTING — Kalau lib/ merah semua setelah pull:**
> Itu artinya packages belum terdownload. Jalankan dulu:
> ```bash
> cd megashop_flutter
> flutter pub get
> ```
> Tunggu sampai selesai, lalu restart IDE. Lib sudah tidak merah lagi.

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