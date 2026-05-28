import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/story.dart';

/// A single story avatar with username label beneath it.
///
/// When [story.isOwnStory] is true, renders a "+" icon instead of a photo.
class StoryAvatar extends StatelessWidget {
  final Story story;
  final VoidCallback? onTap;

  const StoryAvatar({super.key, required this.story, this.onTap});

  static const double _avatarSize = 64.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAvatar(),
          const SizedBox(height: 6),
          SizedBox(
            width: _avatarSize + 10,
            child: Text(
              story.username,
              style: AppTextStyles.storyUsername,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (story.isOwnStory) {
      return _OwnStoryButton(size: _avatarSize);
    }

    return Container(
      width: _avatarSize + 4,
      height: _avatarSize + 4,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.storyRing, width: 2.5),
      ),
      child: ClipOval(
        child: story.imageUrl != null
            ? CachedNetworkImage(
                imageUrl: story.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (ctx, url) => Container(
                  color: AppColors.primarySurface,
                ),
                errorWidget: (ctx, url, err) => _FallbackAvatar(
                  username: story.username,
                ),
              )
            : _FallbackAvatar(username: story.username),
      ),
    );
  }
}

/// The "Your Story" add button with a "+" icon.
class _OwnStoryButton extends StatelessWidget {
  final double size;

  const _OwnStoryButton({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 4,
      height: size + 4,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primarySurface,
        border: Border.all(color: AppColors.storyRingAdd, width: 2),
      ),
      child: const Icon(
        Icons.add_rounded,
        color: AppColors.primary,
        size: 28,
      ),
    );
  }
}

/// Fallback avatar using the first letter of the username.
class _FallbackAvatar extends StatelessWidget {
  final String username;

  const _FallbackAvatar({required this.username});

  @override
  Widget build(BuildContext context) {
    final letter = username.isNotEmpty ? username[0].toUpperCase() : '?';
    return Container(
      color: AppColors.primarySurface,
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 22,
        ),
      ),
    );
  }
}
