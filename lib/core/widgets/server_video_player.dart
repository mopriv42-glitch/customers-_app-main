import 'package:chewie/chewie.dart'; // Optional
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ServerVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const ServerVideoPlayer({super.key, required this.videoUrl});

  @override
  State<ServerVideoPlayer> createState() => _ServerVideoPlayerState();
}

class _ServerVideoPlayerState extends State<ServerVideoPlayer> {
  late VideoPlayerController _controller;
  late ChewieController _chewieController;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {});
      });

    _chewieController = ChewieController(
      videoPlayerController: _controller,
      autoPlay: true,
      looping: false,
      showControls: true,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: Chewie(
              controller: _chewieController,
            ),
          )
        : const CircularProgressIndicator();
  }
}
