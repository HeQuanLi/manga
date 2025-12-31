import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import '../../providers/anime_provider.dart';

class PlayerScreen extends StatefulWidget {
  final String episodeUrl;
  final String episodeName;
  final String animeTitle;
  final String animeImg;
  final String animeUrl;

  const PlayerScreen({
    super.key,
    required this.episodeUrl,
    required this.episodeName,
    required this.animeTitle,
    required this.animeImg,
    required this.animeUrl,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // 设置横屏方向
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // 隐藏状态栏和导航栏，提供沉浸式体验
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    final provider = context.read<AnimeProvider>();
    try {
      await provider.loadVideoData(widget.episodeUrl);
      final videoUrl = provider.currentVideo?.videoUrl;

      if (videoUrl != null && mounted) {
        _videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(videoUrl),
        );

        await _videoPlayerController!.initialize();

        if (mounted) {
          _chewieController = ChewieController(
            videoPlayerController: _videoPlayerController!,
            autoPlay: true,
            looping: false,
            allowFullScreen: true,
            allowMuting: true,
            showControls: true,
            aspectRatio: _videoPlayerController!.value.aspectRatio,
            deviceOrientationsOnEnterFullScreen: [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ],
            deviceOrientationsAfterFullScreen: [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ],
            errorBuilder: (context, errorMessage) {
              return Center(
                child: Text(
                  '视频加载失败: $errorMessage',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            },
          );

          setState(() {
            _isInitialized = true;
          });

          // 记录播放历史
          await provider.addToHistory(
            animeTitle: widget.animeTitle,
            animeImg: widget.animeImg,
            animeUrl: widget.animeUrl,
            episodeName: widget.episodeName,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载视频失败: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    // 恢复竖屏方向
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    // 恢复系统UI显示
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<AnimeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && !_isInitialized) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    '正在加载视频...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          }

          if (provider.error != null && !_isInitialized) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadVideo,
                    icon: const Icon(Icons.refresh),
                    label: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          if (!_isInitialized || _chewieController == null) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          return Stack(
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: _videoPlayerController!.value.aspectRatio,
                  child: Chewie(controller: _chewieController!),
                ),
              ),
              // 添加返回按钮
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                child: SafeArea(
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
