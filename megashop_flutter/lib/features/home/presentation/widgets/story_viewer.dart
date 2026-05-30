import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/story.dart';

/// Full-screen story viewer — swipe left/right to navigate between stories,
/// tap left/right half to go prev/next, tap close or swipe down to dismiss.
/// Auto-advances after [_storyDuration] seconds with an animated progress bar.
class StoryViewer extends StatefulWidget {
  final List<Story> stories;
  final int initialIndex;

  const StoryViewer({
    super.key,
    required this.stories,
    required this.initialIndex,
  });

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer>
    with SingleTickerProviderStateMixin {
  static const _storyDuration = Duration(seconds: 5);

  late int _currentIndex;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    // Skip the "Your Story" add button if tapped
    if (widget.stories[_currentIndex].isOwnStory) {
      final next =
          widget.stories.indexWhere((s) => !s.isOwnStory, _currentIndex + 1);
      if (next != -1) _currentIndex = next;
    }

    _progressController = AnimationController(
      vsync: this,
      duration: _storyDuration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _goNext();
      });

    _startStory();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _startStory() => _progressController.forward(from: 0);

  void _goNext() {
    int next = _currentIndex + 1;
    while (next < widget.stories.length && widget.stories[next].isOwnStory) {
      next++;
    }
    if (next >= widget.stories.length) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _currentIndex = next);
    _startStory();
  }

  void _goPrev() {
    int prev = _currentIndex - 1;
    while (prev >= 0 && widget.stories[prev].isOwnStory) {
      prev--;
    }
    if (prev < 0) {
      _startStory();
      return;
    }
    setState(() => _currentIndex = prev);
    _startStory();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];
    final viewableStories =
        widget.stories.where((s) => !s.isOwnStory).toList();
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
