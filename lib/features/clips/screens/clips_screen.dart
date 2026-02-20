import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/core/models/clip_model.dart';
import 'package:private_4t_app/core/widgets/enhanced_clips_video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class ClipsScreen extends ConsumerStatefulWidget {
  const ClipsScreen({super.key});

  @override
  ConsumerState<ClipsScreen> createState() => _ClipsScreenState();
}

class _ClipsScreenState extends ConsumerState<ClipsScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin , AnalyticsScreenMixin {
  
  @override
  String get screenName => 'Clipsscreen';
  
  List<ClipModel> _clips = const [];
  late final PageController _pageController;
  int _currentActiveIndex = 0;
  bool _isScreenActive = true;

  // Performance optimizations
  static const int _preloadPageCount = 1; // Only preload 1 page ahead/behind
  final Set<int> _initializedPlayers = {}; // Track initialized players

  @override
  bool get wantKeepAlive => true; // Keep state alive for better performance

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final clipProvider = ref.watch(ApiProviders.clipProvider);
    _clips = clipProvider.clips;
    _isScreenActive = clipProvider.isScreenActive;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: null,
          automaticallyImplyLeading: false,
          toolbarHeight: 0, // Hide the app bar completely for full screen
        ),
        body: LayoutBuilder(builder: (context, constraints) {
          final availableHeight = constraints.maxHeight; // Full screen height

          if (_clips.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _clips.length,
            allowImplicitScrolling: false,
            // Improve performance
            physics: const PageScrollPhysics(),
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              return _buildOptimizedVideoCard(index, availableHeight);
            },
          );
        }),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 1.0,
      keepPage: true,
    );

    // Add observer to monitor app lifecycle
    WidgetsBinding.instance.addObserver(this);

    // Initialize clips data with debounce
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(ApiProviders.clipProvider).fetchClips(context, refresh: true);
      }
    });
  }

  @override
  void dispose() {
    // Remove observer
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _initializedPlayers.clear();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    debugPrint("PUSHED IS $state");

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // App is in background, pause videos
        setState(() {
          _isScreenActive = false;
        });
        break;
      case AppLifecycleState.resumed:
        // App is in foreground, resume videos
        setState(() {
          _isScreenActive = true;
        });
        break;
      case AppLifecycleState.hidden:
        // App is hidden, pause videos
        setState(() {
          _isScreenActive = false;
        });
        break;
    }
  }

  @override
  void deactivate() {
    // When navigating away from this screen, deactivate videos
    setState(() {
      _isScreenActive = false;
    });
    super.deactivate();
  }

  // Optimized page change handler with debouncing
  void _onPageChanged(int index) {
    if (!mounted) return;

    setState(() {
      _currentActiveIndex = index;
    });

    // Log clip scroll
    if (index < _clips.length) {
      final clip = _clips[index];
      logStep('clip_scrolled', data: {
        'clip_id': clip.id.toString(),
        'clip_index': index,
        'clip_title': clip.title,
      });
    }

    // Debounced view increment
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _currentActiveIndex == index) {
        final clip = _clips[index];
        ref.read(ApiProviders.clipProvider).incrementView(context, clip.id);
      }
    });

    // Dispose players that are too far away
    _disposeDistantPlayers(index);
  }

  // Optimized video card builder
  Widget _buildOptimizedVideoCard(int index, double availableHeight) {
    if (index >= _clips.length) return const SizedBox.shrink();

    final clip = _clips[index];
    final distance = (index - _currentActiveIndex).abs();

    // Only create active players for nearby cards
    final isActive = index == _currentActiveIndex && _isScreenActive;
    final shouldLoad = distance <= _preloadPageCount;

    if (!shouldLoad) {
      // Return placeholder for distant cards
      return SizedBox(
        height: availableHeight,
        child: Material(
          color: Colors.black,
          child: Center(
            child: Icon(
              Icons.play_circle_outline,
              size: 64.sp,
              color: Colors.white54,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: availableHeight,
      child: _buildVideoCard(clip, index, isActive: isActive),
    );
  }

  // Clean up distant players to save memory
  void _disposeDistantPlayers(int currentIndex) {
    final playersToRemove = <int>[];

    for (final playerIndex in _initializedPlayers) {
      final distance = (playerIndex - currentIndex).abs();
      if (distance > _preloadPageCount + 1) {
        playersToRemove.add(playerIndex);
      }
    }

    for (final index in playersToRemove) {
      _initializedPlayers.remove(index);
    }
  }

  Widget _buildVideoCard(ClipModel clip, int index, {required bool isActive}) {
    return Stack(
      children: [
        // Enhanced Video Player
        EnhancedClipsVideoPlayer(
          videoUrl: clip.videoUrl,
          // "${ApiKeys.baseUrl}/stream/advanced/${YoutubePlayer.convertUrlToId(clip.videoUrl) ?? 'e8hdBBiR1SQ'}",
          isActive: isActive && _isScreenActive,
          onDispose: () {
            // Handle video disposal when swiping away
            debugPrint('Video disposed for clip: ${clip.title}');
          },
        ),

        // Video Info (Bottom Left) - Only show when not interacting with video controls
        Positioned(
          bottom: 10.h,
          // Moved up to avoid timeline controls and account for full screen
          left: 16.w,
          right: 16.w,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  clip.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.8),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        _buildActionsOverlay(clip, index),
      ],
    );
  }

  // removed old action button builder

  Widget _buildActionsOverlay(ClipModel clip, int index) {
    final safe = MediaQuery.of(context).padding;
    final bottomOffset =
        140.h + safe.bottom; // More space for timeline controls in full screen
    return Positioned(
      right: 12.w,
      bottom: bottomOffset,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _roundedAction(
            icon: clip.isLiked ? Icons.favorite : Icons.favorite_border,
            color: clip.isLiked ? Colors.redAccent : Colors.white,
            label: clip.likesCount.toString(),
            onTap: () => _onLike(index),
          ),
          SizedBox(height: 16.h),
          _roundedAction(
            icon: Icons.comment,
            color: Colors.white,
            label: clip.commentsCount.toString(),
            onTap: () => _onComments(index),
          ),
          SizedBox(height: 16.h),
          _roundedAction(
            icon: Icons.share,
            color: Colors.white,
            label: 'شارك',
            onTap: () => _onShare(index),
          ),
        ],
      ),
    );
  }

  Widget _roundedAction({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              shadows: [
                Shadow(
                    color: Colors.black.withValues(alpha: 0.8), blurRadius: 3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // removed unused sample data helper

  void _onLike(int index) {
    final clip = _clips[index];
    logButtonClick('clip_like', data: {
      'clip_id': clip.id.toString(),
      'was_liked': clip.isLiked,
      'likes_count': clip.likesCount,
    });
    
    final provider = ref.read(ApiProviders.clipProvider);
    provider.toggleLike(context, clip);
  }

  void _onComments(int index) {
    final clip = _clips[index];
    logButtonClick('clip_comments', data: {
      'clip_id': clip.id.toString(),
      'comments_count': clip.commentsCount,
    });
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final controller = TextEditingController();
        final provider = ref.watch(ApiProviders.clipProvider);
        final clip = _clips[index];
        final comments = provider.commentsOf(clip.id);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder(
                      future: provider.fetchComments(context, clip.id,
                          refresh: comments.isEmpty),
                      builder: (context, snapshot) {
                        final current = provider.commentsOf(clip.id);
                        return ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: current.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 16),
                          itemBuilder: (_, i) {
                            final c = current[i];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const CircleAvatar(
                                        radius: 16,
                                        child: Icon(Icons.person, size: 16)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(c.user.name,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          Text(c.content),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (c.replies.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                        start: 44),
                                    child: Column(
                                      children: c.replies
                                          .map((r) => Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 8),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const CircleAvatar(
                                                        radius: 12,
                                                        child: Icon(
                                                            Icons.person,
                                                            size: 12)),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(r.user.name,
                                                              style: const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize:
                                                                      12)),
                                                          const SizedBox(
                                                              height: 2),
                                                          Text(r.content,
                                                              style:
                                                                  const TextStyle(
                                                                      fontSize:
                                                                          12)),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                  )
                                ]
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                  if (provider.hasMoreComments(clip.id))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () {
                            logButtonClick('clip_load_more_comments', data: {
                              'clip_id': clip.id.toString(),
                            });
                            ref
                                .read(ApiProviders.clipProvider)
                                .fetchComments(context, clip.id);
                          },
                          child: const Text('تحميل المزيد'),
                        ),
                      ),
                    ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            decoration: const InputDecoration(
                              hintText: 'أضف تعليقًا...',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final commentText = controller.text.trim();
                            if (commentText.isNotEmpty && mounted) {
                              logButtonClick('clip_send_comment', data: {
                                'clip_id': clip.id.toString(),
                                'comment_length': commentText.length,
                              });
                              await ref
                                  .read(ApiProviders.clipProvider)
                                  .addComment(context, clip.id, commentText);
                              if (mounted) Navigator.pop(context);
                            }
                          },
                          child: const Text('إرسال'),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _onShare(int index) async {
    final clip = _clips[index];
    logButtonClick('clip_share', data: {
      'clip_id': clip.id.toString(),
    });
    
    final box = context.findRenderObject() as RenderBox?;
    final packageInfo = await PackageInfo.fromPlatform();
    final appName = packageInfo.appName;
    final appVersion = packageInfo.version;
    final appBuildNumber = packageInfo.buildNumber;

    // Share the app information with website and store links
    final shareText = '''$appName v$appVersion (Build: $appBuildNumber)

تطبيق تعليمي متطور يوفر:
• دروس فيديو تعليمية
• حجز دروس خصوصية
• مكتبة تعليمية شاملة
• محتوى تعليمي عالي الجودة

تحميل التطبيق:
• Android: https://play.google.com/store/apps/details?id=com.private_4t.app
• iOS: https://apps.apple.com/app/private-4t/id123456789

جرب التطبيق الآن!''';

    await SharePlus.instance.share(
      ShareParams(
        text: shareText,
        subject: 'جرب تطبيق $appName',
        sharePositionOrigin: box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : Rect.largest,
      ),
    );
  }
}

class VideoData {
  final String title;
  final String description;
  final String subject;
  final int likes;
  final int comments;

  VideoData({
    required this.title,
    required this.description,
    required this.subject,
    required this.likes,
    required this.comments,
  });
}
