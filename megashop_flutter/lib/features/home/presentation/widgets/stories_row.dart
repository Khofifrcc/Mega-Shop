import 'package:flutter/material.dart';
import '../../domain/entities/story.dart';
import 'story_avatar.dart';

/// Horizontal scrollable row of story avatars.
///
/// [viewedStoryIds] tracks which stories have been seen — their ring turns grey.
class StoriesRow extends StatelessWidget {
  final List<Story> stories;
  final Set<String> viewedStoryIds;
  final void Function(int index)? onStoryTap;
  final VoidCallback? onOwnStoryTap;
  final String? ownStoryImagePath;

  const StoriesRow({
    super.key,
    required this.stories,
    this.viewedStoryIds = const {},
    this.onStoryTap,
    this.onOwnStoryTap,
    this.ownStoryImagePath,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 102,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: stories.length,
        separatorBuilder: (ctx, i) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final story = stories[index];
          return StoryAvatar(
            story: story,
            isViewed: viewedStoryIds.contains(story.id),
            localImagePath: story.isOwnStory ? ownStoryImagePath : null,
            onTap: story.isOwnStory
                ? onOwnStoryTap
                : () => onStoryTap?.call(index),
          );
        },
      ),
    );
  }
}
