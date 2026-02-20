import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class EnhancedClipsVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onDispose;

  const EnhancedClipsVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.isActive,
    this.onTap,
    this.onDispose,
  });

  @override
  State<EnhancedClipsVideoPlayer> createState() =>
      _EnhancedClipsVideoPlayerState();
}

class _EnhancedClipsVideoPlayerState extends State<EnhancedClipsVideoPlayer>
    with TickerProviderStateMixin {
  VideoPlayerController? _videoController;
  YoutubePlayerController? _youtubeController;

  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _showControls = false;
  bool _isBuffering = false;
  bool _isYouTube = false;

  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  late AnimationController _controlsAnimationController;
  late AnimationController _timelineAnimationController;
  late Animation<double> _controlsOpacity;
  late Animation<Offset> _timelineSlideAnimation;

  @override
  void initState() {
    super.initState();

    _controlsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _timelineAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _controlsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controlsAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _timelineSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _timelineAnimationController,
        curve: Curves.easeOut,
      ),
    );

    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _initializePlayer();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant EnhancedClipsVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only reinitialize if URL actually changes
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposePlayer();
      _isInitialized = false;
      if (widget.isActive) {
        _initializePlayer();
      }
    }

    // Handle isActive changes efficiently - pause instead of dispose
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive && !_isInitialized) {
        _initializePlayer();
      } else if (!widget.isActive && _isInitialized) {
        _pausePlayer();
      }
    }
  }

  void _initializePlayer() {
    if (_isInitialized) return;

    _isYouTube = _isYouTubeUrl(widget.videoUrl);

    if (_isYouTube) {
      _initializeYouTubePlayer();
    } else {
      _initializeVideoPlayer();
    }
  }

  bool _isYouTubeUrl(String url) {
    return url.contains('youtu.be') || url.contains('youtube.com');
  }

  void _initializeYouTubePlayer() {
    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
    if (videoId == null) return;

    _youtubeController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        showLiveFullscreenButton: false,
        loop: true,
        hideControls: true,
        forceHD: false,
        useHybridComposition: false,
        disableDragSeek: false,
        enableCaption: false,
      ),
    );

    // _youtubeController!.value.webViewController..

    _youtubeController!.addListener(_youtubePlayerListener);

    setState(() {
      _isInitialized = true;
      _isPlaying = true;
    });
  }

  void _initializeVideoPlayer() async {
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
      httpHeaders: {
        'Accept': 'video/mp4,video/webm,video/*',
        'Connection': 'keep-alive',
        'User-Agent': 'Mozilla/5.0 (compatible; VideoPlayer/1.0)',
      },
    );

    _videoController!.addListener(_videoPlayerListener);

    try {
      await _videoController!.initialize();
      await _videoController!.play();
      await _videoController!.setLooping(true);

      setState(() {
        _isInitialized = true;
        _isPlaying = true;
        _totalDuration = _videoController!.value.duration;
      });
    } catch (e) {
      debugPrint('Error initializing video player: $e');
    }
  }

  void _youtubePlayerListener() {
    if (!mounted) return;

    final value = _youtubeController!.value;

    setState(() {
      _isPlaying = value.isPlaying;
      _isBuffering = !value.isReady;
      _currentPosition = value.position;
      _totalDuration = value.metaData.duration;
    });
  }

  void _videoPlayerListener() {
    if (!mounted) return;

    final value = _videoController!.value;

    setState(() {
      _isPlaying = value.isPlaying;
      _isBuffering = value.isBuffering;
      _currentPosition = value.position;
      _totalDuration = value.duration;
    });
  }

  void _pausePlayer() {
    if (_videoController != null && _videoController!.value.isPlaying) {
      _videoController!.pause();
    }
    if (_youtubeController != null && _youtubeController!.value.isPlaying) {
      _youtubeController!.pause();
    }

    setState(() {
      _isPlaying = false;
    });
  }

  void _disposePlayer() {
    widget.onDispose?.call();

    _videoController?.removeListener(_videoPlayerListener);
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;

    _youtubeController?.removeListener(_youtubePlayerListener);
    _youtubeController?.pause();
    _youtubeController?.dispose();
    _youtubeController = null;

    try{
      setState(() {
        _isInitialized = false;
        _isPlaying = false;
        _currentPosition = Duration.zero;
        _totalDuration = Duration.zero;
      });
    }catch(_){}
  }

  void _togglePlayPause() {
    debugPrint("Is playing: $_isPlaying");
    if (_isYouTube && _youtubeController != null) {
      if (_isPlaying) {
        _youtubeController!.pause();
      } else {
        _youtubeController!.play();
      }
    } else if (_videoController != null) {
      if (_isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
    }
  }

  void _seek(Duration position) {
    if (_isYouTube && _youtubeController != null) {
      _youtubeController!.seekTo(position);
    } else if (_videoController != null) {
      _videoController!.seekTo(position);
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    if (_showControls) {
      _controlsAnimationController.forward();
      _timelineAnimationController.forward();

      // Auto-hide controls after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _showControls) {
          _hideControls();
        }
      });
    } else {
      _hideControls();
    }
  }

  void _hideControls() {
    _controlsAnimationController.reverse();
    _timelineAnimationController.reverse();
    setState(() {
      _showControls = false;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onTap?.call();
        _toggleControls();
      },
      child: Material(
        color: Colors.black,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              // Video Player
              if (_isInitialized) ...[
                if (_isYouTube && _youtubeController != null)
                  if (widget.videoUrl.contains('shorts'))
                    SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: YoutubePlayer(
                        controller: _youtubeController!,
                        showVideoProgressIndicator: false,
                        bufferIndicator: const SizedBox.shrink(),
                        progressIndicatorColor: Colors.transparent,
                      ),
                    )
                  else
                    YoutubePlayer(
                      controller: _youtubeController!,
                      showVideoProgressIndicator: false,
                      progressIndicatorColor: Colors.transparent,
                      aspectRatio: 16 / 9,
                      bufferIndicator: const SizedBox.shrink(),
                    )

                // SizedBox.expand(
                //   child: FittedBox(
                //     fit: BoxFit.cover,
                //     child: SizedBox(
                //       width: MediaQuery.of(context).size.width,
                //       height: MediaQuery.of(context).size.width * (9 / 16),
                //       child: YoutubePlayer(
                //         controller: _youtubeController!,
                //         showVideoProgressIndicator: false,
                //         progressIndicatorColor: Colors.transparent,
                //       ),
                //     ),
                //   ),
                // )
                else if (_videoController != null)
                  SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoController!.value.size.width,
                        height: _videoController!.value.size.height,
                        child: VideoPlayer(_videoController!),
                      ),
                    ),
                  ),
              ] else
                const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),

              // Buffering Indicator
              // if (_isBuffering)
              //   const Center(
              //     child: CircularProgressIndicator(
              //       valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              //     ),
              //   ),

              // Play/Pause Control (Center)
              if (_showControls && _isInitialized)
                AnimatedBuilder(
                  animation: _controlsOpacity,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _controlsOpacity.value,
                      child: Center(
                        child: GestureDetector(
                          onTap: _togglePlayPause,
                          child: Container(
                            width: 80.w,
                            height: 80.w,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              size: 40.sp,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

              // Timeline Progress Bar (Bottom)
              Positioned(
                bottom: 20.h,
                left: 16.w,
                right: 16.w,
                child: SlideTransition(
                  position: _timelineSlideAnimation,
                  child: AnimatedBuilder(
                    animation: _controlsOpacity,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _showControls ? 1.0 : 0.3,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Progress Bar with Swipe Gestures
                            GestureDetector(
                              onPanStart: (details) {
                                // Show controls when user starts swiping timeline
                                if (!_showControls) {
                                  _toggleControls();
                                }
                              },
                              onPanUpdate: (details) {
                                if (_totalDuration.inMilliseconds > 0) {
                                  final RenderBox box =
                                      context.findRenderObject() as RenderBox;
                                  final localPosition = box.globalToLocal(
                                    details.globalPosition,
                                  );
                                  final progressBarWidth =
                                      MediaQuery.of(context).size.width - 32.w;
                                  final progress = (localPosition.dx - 16.w) /
                                      progressBarWidth;
                                  final clampedProgress = progress.clamp(
                                    0.0,
                                    1.0,
                                  );
                                  final newPosition = Duration(
                                    milliseconds:
                                        (_totalDuration.inMilliseconds *
                                                clampedProgress)
                                            .round(),
                                  );
                                  _seek(newPosition);
                                }
                              },
                              onPanEnd: (details) {
                                // Auto-hide controls after seeking
                                Future.delayed(const Duration(seconds: 2), () {
                                  if (mounted && _showControls) {
                                    _hideControls();
                                  }
                                });
                              },
                              child: Container(
                                height: 20.h, // Increased touch area
                                padding: EdgeInsets.symmetric(vertical: 8.h),
                                child: Container(
                                  height: 4.h,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2.r),
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(2.r),
                                    child: Stack(
                                      children: [
                                        // Background
                                        Container(
                                          width: double.infinity,
                                          height: double.infinity,
                                          color: Colors.transparent,
                                        ),
                                        // Progress
                                        FractionallySizedBox(
                                          widthFactor:
                                              _totalDuration.inMilliseconds > 0
                                                  ? _currentPosition
                                                          .inMilliseconds /
                                                      _totalDuration
                                                          .inMilliseconds
                                                  : 0.0,
                                          child: Container(
                                            height: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(2.r),
                                            ),
                                          ),
                                        ),
                                        // Thumb indicator (only when controls are visible)
                                        if (_showControls)
                                          Positioned(
                                            left: (_totalDuration
                                                        .inMilliseconds >
                                                    0
                                                ? (_currentPosition
                                                                .inMilliseconds /
                                                            _totalDuration
                                                                .inMilliseconds) *
                                                        (MediaQuery.of(
                                                              context,
                                                            ).size.width -
                                                            32.w) -
                                                    6.w
                                                : 0),
                                            top: -4.h,
                                            child: Container(
                                              width: 12.w,
                                              height: 12.w,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.3),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Time Labels
                            if (_showControls) ...[
                              SizedBox(height: 8.h),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(_currentPosition),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w500,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.8),
                                          blurRadius: 3,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(_totalDuration),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w400,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.8),
                                          blurRadius: 3,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controlsAnimationController.dispose();
    _timelineAnimationController.dispose();
    _disposePlayer();
    super.dispose();
  }
}
