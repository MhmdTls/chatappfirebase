import 'package:flutter/material.dart';
import 'package:chatappfirbase/full_screen_image.dart';
import 'package:chatappfirbase/full_screen_video.dart';
import 'package:video_player/video_player.dart';

class ChatBubble extends StatefulWidget {
  final String? message; // Optional message
  final String? imageUrl; // Optional image URL
  final String? videoUrl; // Optional video URL
  final Color color; // Bubble color
  final String time; // Message time

  const ChatBubble({
    Key? key,
    this.message,
    this.imageUrl,
    this.videoUrl,
    required this.color,
    required this.time,
  }) : super(key: key);

  @override
  _ChatBubbleState createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;
  bool _isImageLoaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.videoUrl != null) {
      _controller = VideoPlayerController.network(widget.videoUrl!)
        ..initialize().then((_) {
          setState(() {
            _isVideoInitialized = true;
          });
        });
    }
  }

  @override
  void dispose() {
    if (widget.videoUrl != null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        color: widget.color,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.message != null)
            Text(
              widget.message!,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          if (widget.imageUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenImage(imageUrl: widget.imageUrl!),
                    ),
                  );
                },
                child: Hero(
                  tag: widget.imageUrl!,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 150,
                        height: 150,
                        child: Image.network(
                          widget.imageUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                            if (loadingProgress == null) {
                              return child;
                            } else {
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                                      : null,
                                ),
                              );
                            }
                          },
                          errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                            return const Center(child: Icon(Icons.error));
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (widget.videoUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenVideo(videoUrl: widget.videoUrl!),
                    ),
                  );
                },
                child: Hero(
                  tag: widget.videoUrl!,
                  child: Container(
                    width: 150,
                    height: 150,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_isVideoInitialized)
                          AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: VideoPlayer(_controller),
                          ),
                        if (!_isVideoInitialized)
                          const CircularProgressIndicator(),
                        const Icon(Icons.play_circle_outline, size: 50, color: Colors.white70),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 5),
          Text(
            widget.time,
            style: const TextStyle(fontSize: 10, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
