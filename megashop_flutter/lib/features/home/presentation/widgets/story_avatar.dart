import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/story.dart';

/// A single story avatar with username label beneath it.
///
/// [isViewed] — when true, the ring colour turns grey (already watched).
/// When [story.isOwnStory] is true, renders a camera/add icon.
class StoryAvatar extends StatelessWidget {
  final Story story;
  final VoidCallback? onTap;
  final bool isViewed;

  /// Optional local file path for "Your Story" (after user picks an image).
  final String? localImagePath;

  const StoryAvatar({
    super.key,
    required this.story,
    this.onTap,
    this.isViewed = false,
    this.localImagePath,
  });

  static const double _avatarSize = 64.0;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
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
      ),
    );
  }

  Widget _buildAvatar() {
    if (story.isOwnStory) {
      return _OwnStoryButton(size: _avatarSize, localImagePath: localImagePath);
    }

    // Ring colour: grey if viewed, purple if not
    final ringColor = isViewed
        ? const Color(0xFFBDBDBD)   // grey
        : AppColors.storyRing;      // purple (original)

    return Container(
      width: _avatarSize + 4,
      height: _avatarSize + 4,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: 2.5),
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

// ── "Your Story" add / preview button ────────────────────────────────────────

class _OwnStoryButton extends StatelessWidget {
  final double size;
  final String? localImagePath;

  const _OwnStoryButton({required this.size, this.localImagePath});

  @override
  Widget build(BuildContext context) {
    final hasImage = localImagePath != null;

    return Stack(
      children: [
        Container(
          width: size + 4,
          height: size + 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primarySurface,
            border: Border.all(
              color: hasImage ? AppColors.storyRing : AppColors.storyRingAdd,
              width: 2,
            ),
          ),
          child: ClipOval(
            child: hasImage
                ? Image.file(
                    File(localImagePath!),
                    fit: BoxFit.cover,
                  )
                : Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
          ),
        ),
        // "+" badge at bottom-right
        Positioned(
          bottom: 2,
          right: 2,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 13),
          ),
        ),
      ],
    );
  }
}

// ── Fallback avatar ───────────────────────────────────────────────────────────

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
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 22,
        ),
      ),
    );
  }
}
