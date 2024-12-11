import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerCard extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerCard({
    super.key,
    required this.videoUrl,
  });

  @override
  State<VideoPlayerCard> createState() => _VideoPlayerCardState();
}

class _VideoPlayerCardState extends State<VideoPlayerCard> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );
    _initializeVideoPlayerFuture = _controller.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        children: [
          FutureBuilder(
            future: _initializeVideoPlayerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                );
              }
              return const AspectRatio(
                aspectRatio: 16 / 9,
                child: Center(child: CircularProgressIndicator()),
              );
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10),
                onPressed: () {
                  final newPosition = Duration(
                    seconds: _controller.value.position.inSeconds - 10,
                  );
                  _controller.seekTo(newPosition);
                },
              ),
              IconButton(
                icon: Icon(
                  _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                ),
                onPressed: () {
                  setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.forward_10),
                onPressed: () {
                  final newPosition = Duration(
                    seconds: _controller.value.position.inSeconds + 10,
                  );
                  _controller.seekTo(newPosition);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
