import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Horizontal scrolling pill-shaped category filter bar.
///
/// Highlights the selected category with a solid purple background.
/// Manages its own selected state; exposes [onCategoryChanged] callback.
class CategoryFilterBar extends StatefulWidget {
  final List<String> categories;
  final ValueChanged<String>? onCategoryChanged;

  const CategoryFilterBar({
    super.key,
    required this.categories,
    this.onCategoryChanged,
  });

  @override
  State<CategoryFilterBar> createState() => _CategoryFilterBarState();
}

class _CategoryFilterBarState extends State<CategoryFilterBar> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.categories.length,
        separatorBuilder: (ctx, i) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = index == _selectedIndex;
          final label = widget.categories[index];
          return _CategoryPill(
            label: label,
            isSelected: isSelected,
            onTap: () {
              setState(() => _selectedIndex = index);
              widget.onCategoryChanged?.call(label);
            },
          );
        },
      ),
    );
  }
}

/// Individual pill button for a single category.
class _CategoryPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : AppColors.primarySurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: AppColors.primaryLight.withAlpha(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Text(
              label,
              style: isSelected
                  ? AppTextStyles.categoryActive
                  : AppTextStyles.categoryInactive,
            ),
          ),
        ),
      ),
    );
  }
}
