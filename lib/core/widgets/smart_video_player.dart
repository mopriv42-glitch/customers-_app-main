import 'package:flutter/material.dart';
import 'package:private_4t_app/core/widgets/server_video_player.dart';
import 'package:private_4t_app/core/widgets/youtube_video_player.dart';

class SmartVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool isActive;

  const SmartVideoPlayer(
      {Key? key, required this.videoUrl, this.isActive = true})
      : super(key: key);

  @override
  State<SmartVideoPlayer> createState() => _SmartVideoPlayerState();
}

class _SmartVideoPlayerState extends State<SmartVideoPlayer> {
  late Widget _playerWidget;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _playerWidget = const SizedBox.shrink();
    _maybeBuildPlayer();
  }

  @override
  void didUpdateWidget(covariant SmartVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive ||
        oldWidget.videoUrl != widget.videoUrl) {
      if (!widget.isActive) {
        // Unmount heavy players when inactive to free resources
        setState(() {
          _initialized = false;
          _playerWidget = const SizedBox.shrink();
        });
      } else {
        _maybeBuildPlayer();
      }
    }
  }

  Widget _buildServerVideoPlayer(String videoUrl) {
    return ServerVideoPlayer(videoUrl: videoUrl);
  }

  Widget _buildYoutubeVideoPlayer(String videoUrl) {
    return YoutubeVideoPlayer(youtubeUrl: videoUrl);
  }

  @override
  Widget build(BuildContext context) {
    return _playerWidget;
  }

  void _maybeBuildPlayer() {
    if (!widget.isActive || _initialized) return;
    _initialized = true;
    if (widget.videoUrl.startsWith('http') &&
        !widget.videoUrl.contains('youtu') &&
        !widget.videoUrl.contains('youtube')) {
      _playerWidget = _buildServerVideoPlayer(widget.videoUrl);
    } else {
      _playerWidget = _buildYoutubeVideoPlayer(widget.videoUrl);
    }
    if (mounted) setState(() {});
  }
}
