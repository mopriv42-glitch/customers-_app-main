import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YoutubeVideoPlayer extends StatefulWidget {
  final String youtubeUrl;
  final bool autoPlayMuted;

  const YoutubeVideoPlayer(
      {super.key, required this.youtubeUrl, this.autoPlayMuted = true});

  @override
  State<YoutubeVideoPlayer> createState() => _YoutubeVideoPlayerState();
}

class _YoutubeVideoPlayerState extends State<YoutubeVideoPlayer> {
  late YoutubePlayerController _controller;
  String? _videoId; // Store the video ID for potential error checking
  bool _isPlayerReady = false; // Flag to track player initialization

  @override
  void initState() {
    super.initState();

    // 1. Extract Video ID
    _videoId = YoutubePlayer.convertUrlToId(widget.youtubeUrl);

    // 2. Check if Video ID is valid
    if (_videoId == null || _videoId!.isEmpty) {
      // Handle invalid URL case
      // You could use a callback, set an error state, or log an error
      debugPrint("Invalid YouTube URL provided: ${widget.youtubeUrl}");
      // Consider setting an error state to display a message in build()
      return; // Exit early if ID is invalid
    }

    // 3. Initialize Controller (only if ID is valid)
    _controller = YoutubePlayerController(
      initialVideoId: _videoId!,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        loop: false,
        controlsVisibleAtStart: true,
        forceHD: false,
        enableCaption: false,
      ),
    )..addListener(_playerStatusChanged);
  }

  // Optional: Listen to player events
  void _playerStatusChanged() {
    if (_controller.value.isReady && !_isPlayerReady) {
      setState(() {
        _isPlayerReady = true;
      });
      // Player is ready, you can perform actions here if needed
      debugPrint("Youtube Player is Ready");
    }
    // You can also check for errors: _controller.value.hasError
    if (_controller.value.hasError) {
      debugPrint("Youtube Player Error: ${_controller.value.errorCode}");
      // Handle player error, maybe show a message
    }
  }

  @override
  void dispose() {
    // 4. Dispose the controller to free up resources
    _controller.removeListener(_playerStatusChanged); // Remove listener first
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 5. Handle invalid URL case in build
    if (_videoId == null || _videoId!.isEmpty) {
      return const Center(
        child: Text(
          'Invalid YouTube URL',
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    // 6. Wrap in AspectRatio for correct display
    return AspectRatio(
      aspectRatio: 16 / 9, // Standard YouTube aspect ratio
      child: YoutubePlayer(
        controller: _controller,
        progressIndicatorColor: Colors.redAccent,
        showVideoProgressIndicator: false,
        // onReady: () { // Alternative to listener for ready state
        //   debugPrint("Player is ready via onReady callback");
        //   setState(() {
        //      _isPlayerReady = true;
        //   });
        // },
        // onEnded: (metaData) { // Handle video end if needed
        //   debugPrint("Video ended: ${metaData.title}");
        // },
      ),
    );
  }
}
