import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class IntroductionPage extends StatefulWidget {
  const IntroductionPage({super.key});

  static const seenKey = 'hasSeenIntroduction';

  @override
  State<IntroductionPage> createState() => _IntroductionPageState();
}

class _IntroductionPageState extends State<IntroductionPage> {
  final _pageController = PageController();
  int _page = 0;

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(IntroductionPage.seenKey, true);

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = [
      const _IntroSlide(
        icon: Icons.storefront_rounded,
        title: 'Welcome to MegaShop',
        description:
            'Discover products, reels, sellers, and daily finds in one place.',
      ),
      const _IntroSlide(
        icon: Icons.shopping_bag_rounded,
        title: 'Shop Faster',
        description:
            'Add items to cart, choose an address, and checkout smoothly.',
      ),
      const _IntroSlide(
        icon: Icons.notifications_active_rounded,
        title: 'Stay Updated',
        description: 'Get order and chat notifications right when they matter.',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finish,
                  child: Text('Skip', style: AppTextStyles.buttonOutlined),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: slides.length,
                  onPageChanged: (index) => setState(() => _page = index),
                  itemBuilder: (context, index) => slides[index],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: _page == index ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _page == index
                          ? AppColors.primary
                          : AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (_page == slides.length - 1) {
                      _finish();
                      return;
                    }

                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOut,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _page == slides.length - 1 ? 'Get Started' : 'Next',
                    style: AppTextStyles.buttonFilled.copyWith(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroSlide extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _IntroSlide({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 160,
          height: 160,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 28,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: Icon(icon, color: AppColors.primary, size: 74),
        ),
        const SizedBox(height: 36),
        Text(
          title,
          style: AppTextStyles.sectionTitle.copyWith(fontSize: 28),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: AppTextStyles.brandName.copyWith(fontSize: 15, height: 1.6),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
