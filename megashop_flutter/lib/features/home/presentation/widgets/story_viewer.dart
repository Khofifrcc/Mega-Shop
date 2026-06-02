import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/story.dart';

/// Full-screen story viewer — swipe left/right to navigate between stories,
/// tap left/right half to go prev/next, tap close or swipe down to dismiss.
/// Auto-advances after [_storyDuration] seconds with an animated progress bar.
class StoryViewer extends StatefulWidget {
  final List<Story> stories;
  final int initialIndex;
  final ValueChanged<String>? onStoryViewed;

  const StoryViewer({
    super.key,
    required this.stories,
    required this.initialIndex,
    this.onStoryViewed,
  });

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer>
    with SingleTickerProviderStateMixin {
  static const _storyDuration = Duration(seconds: 5);

  late int _currentIndex;
  late final List<Story> _viewerStories;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _viewerStories = List.from(widget.stories);
    _currentIndex = widget.initialIndex;

    // Skip the "Your Story" add button if tapped
    if (_viewerStories[_currentIndex].isOwnStory) {
      final next =
          _viewerStories.indexWhere((s) => !s.isOwnStory, _currentIndex + 1);
      if (next != -1) _currentIndex = next;
    }

    _progressController = AnimationController(
      vsync: this,
      duration: _storyDuration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _goNext();
      });

    _startStory();
    _notifyViewed();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _notifyViewed() {
    if (_currentIndex >= 0 && _currentIndex < _viewerStories.length) {
      final story = _viewerStories[_currentIndex];
      widget.onStoryViewed?.call(story.id);
    }
  }

  void _startStory() => _progressController.forward(from: 0);

  void _goNext() {
    int next = _currentIndex + 1;
    while (next < _viewerStories.length && _viewerStories[next].isOwnStory) {
      next++;
    }
    if (next >= _viewerStories.length) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _currentIndex = next);
    _startStory();
    _notifyViewed();
  }

  void _goPrev() {
    int prev = _currentIndex - 1;
    while (prev >= 0 && _viewerStories[prev].isOwnStory) {
      prev--;
    }
    if (prev < 0) {
      _startStory();
      return;
    }
    setState(() => _currentIndex = prev);
    _startStory();
    _notifyViewed();
  }

  Future<void> _deleteStory(Story story) async {
    // Pause progress indicator during deletion confirmation
    _progressController.stop();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Delete Story', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this story?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.badgeSale),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('stories')
            .doc(story.id)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Story deleted successfully'),
              backgroundColor: AppColors.primary,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        debugPrint('Failed to delete story: $e');
        if (mounted) {
          _progressController.forward(); // resume
        }
      }
    } else {
      if (mounted) {
        _progressController.forward(); // resume
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = _viewerStories[_currentIndex];
    final viewableStories =
        _viewerStories.where((s) => !s.isOwnStory).toList();
    final viewableIndex =
        viewableStories.indexWhere((s) => s.id == story.id);

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 200) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        // ── extendBody true: image fills behind bottom nav bar ───────────
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Story image — truly full screen ──────────────────────────
            SizedBox.expand(
              child: story.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: story.imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (_, __) => const _StoryPlaceholder(),
                      errorWidget: (_, __, ___) => const _StoryPlaceholder(),
                    )
                  : const _StoryPlaceholder(),
            ),

            // ── Dark gradient top ─────────────────────────────────────────
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: const Alignment(0, -0.3),
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ── Tap zones: left = prev, right = next ──────────────────────
            // (placed BEFORE the overlay so taps pass through to UI above)
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _goPrev,
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _goNext,
                    ),
                  ),
                ],
              ),
            ),

            // ── Progress bars + header (SafeArea so they clear status bar) ─
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress bars row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    child: AnimatedBuilder(
                      animation: _progressController,
                      builder: (_, __) {
                        return Row(
                          children: List.generate(viewableStories.length, (i) {
                            double value;
                            if (i < viewableIndex) {
                              value = 1.0;
                            } else if (i == viewableIndex) {
                              value = _progressController.value;
                            } else {
                              value = 0.0;
                            }
                            return Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: value,
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.35),
                                    color: Colors.white,
                                    minHeight: 3,
                                  ),
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  ),

                  // Avatar + username + close button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 4, 0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primarySurface,
                          backgroundImage: story.imageUrl != null
                              ? CachedNetworkImageProvider(story.imageUrl!)
                              : null,
                          child: story.imageUrl == null
                              ? Text(
                                  story.username.isNotEmpty
                                      ? story.username[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            story.username,
                            style: AppTextStyles.productName.copyWith(
                                color: Colors.white, fontSize: 14),
                          ),
                        ),
                        if (story.ownerId == FirebaseAuth.instance.currentUser?.uid)
                          IconButton(
                            onPressed: () => _deleteStory(story),
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: Colors.redAccent, size: 24),
                          ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white, size: 26),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder shown while story image loads or on error.
class _StoryPlaceholder extends StatelessWidget {
  const _StoryPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A2E),
      child: const Center(
        child: Icon(Icons.image_rounded, color: Colors.white24, size: 64),
      ),
    );
  }
}
