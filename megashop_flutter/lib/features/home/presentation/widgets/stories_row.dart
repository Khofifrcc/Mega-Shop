import 'package:flutter/material.dart';
import '../../domain/entities/story.dart';
import 'story_avatar.dart';

/// Horizontal scrollable row of story avatars.
///
/// Renders one [StoryAvatar] per [Story] entity.
class StoriesRow extends StatelessWidget {
  final List<Story> stories;

  const StoriesRow({super.key, required this.stories});

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
          return StoryAvatar(
            story: stories[index],
            onTap: () {
              // TODO: navigate to story viewer
            },
          );
        },
      ),
    );
  }
}
