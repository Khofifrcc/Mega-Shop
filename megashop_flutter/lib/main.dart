import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'shared/state/cart_state.dart';

// Auth
import 'features/auth/presentation/pages/login_register_page.dart';
import 'features/auth/presentation/pages/otp_page.dart';

// Home
import 'features/home/presentation/pages/home_page.dart';

// Reels
import 'features/reels/presentation/pages/reels_page.dart';

// Product
import 'features/product/presentation/pages/product_detail_page.dart';

// Cart
import 'features/cart/presentation/pages/cart_page.dart';

// Checkout
import 'features/checkout/presentation/pages/checkout_page.dart';
import 'features/checkout/presentation/pages/order_status_page.dart';

// Search
import 'features/search/presentation/pages/search_page.dart';

// Post
import 'features/post/presentation/pages/post_creation_page.dart';

// Chat
import 'features/chat/presentation/pages/chat_list_page.dart';
import 'features/chat/presentation/pages/conversation_page.dart';

// Profile
import 'features/profile/presentation/pages/profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MegaShopApp());
}

/// Root widget — wraps the entire app with [CartStateProvider] so every
/// descendant page can access and mutate cart state without prop drilling.
class MegaShopApp extends StatelessWidget {
  const MegaShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CartStateProvider(
      cart: CartState(),
      child: MaterialApp(
        title: 'MegaShop',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute:
            FirebaseAuth.instance.currentUser != null ? '/home' : '/login',
        routes: {
          '/login': (_) => const LoginRegisterPage(),
          '/otp': (_) => const OtpPage(),
          '/home': (_) => const HomePage(),
          '/reels': (_) => const ReelsPage(),
          '/product': (_) => const ProductDetailPage(),
          '/cart': (_) => const CartPage(),
          '/checkout': (_) => const CheckoutPage(),
          '/order-status': (_) => const OrderStatusPage(),
          '/search': (_) => const SearchPage(),
          '/post': (_) => const PostCreationPage(),
          '/chat': (_) => const ChatListPage(),
          '/conversation': (_) => const ConversationPage(),
          '/profile': (_) => const ProfilePage(),
        },
      ),
    );
  }
}
