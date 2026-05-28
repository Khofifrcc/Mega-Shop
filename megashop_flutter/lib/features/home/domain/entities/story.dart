/// Domain entity representing a story shown in the horizontal stories row.
/// Pure Dart — no Flutter dependencies.
class Story {
  final String id;

  /// Display name shown below the avatar (e.g. '@diana_v')
  final String username;

  /// URL to the user's profile image; null for the "Your Story" add button
  final String? imageUrl;

  /// True when this is the current user's own story slot (shows a '+' button)
  final bool isOwnStory;

  const Story({
    required this.id,
    required this.username,
    this.imageUrl,
    this.isOwnStory = false,
  });
}
