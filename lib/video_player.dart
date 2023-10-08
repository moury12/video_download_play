import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_dowload_play/video_download_page.dart';
import 'package:video_player/video_player.dart';

class VideoListScreen extends StatefulWidget {
  @override
  _VideoListScreenState createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  late List<Map<String, dynamic>> videoList =
      []; // Initialize with an empty list
  List<VideoPlayerController> videoControllers = [];

  @override
  void initState() {
    super.initState();
    loadVideoList();
  }

  Future<void> loadVideoList() async {
    final files = await OfflineFileManager().getFiles();
    setState(() {
      videoList = files;
    });
  }

  @override
  void dispose() {
    for (final controller in videoControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Downloaded Videos'),
      ),
      body: ListView.builder(
        itemCount: videoList.length,
        itemBuilder: (context, index) {
          final fileName = videoList[index]['filename'];
          final filePath = videoList[index]['filepath'];
          final videoController = VideoPlayerController.file(File(filePath));
          videoControllers.add(videoController);

          return ListTile(
            title: Text(fileName),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoPlayerScreen(
                    videoController: videoController,
                    filePath: filePath,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  VideoPlayerController videoController;
  final String filePath;

  VideoPlayerScreen({required this.videoController, required this.filePath});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  @override
  void initState() {
    super.initState();
    widget.videoController = VideoPlayerController.file(File(widget.filePath))
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {});
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Player'),
      ),
      body: Center(
        child: widget.videoController.value.isInitialized
            ? Container(
                child: AspectRatio(
                  aspectRatio: widget.videoController.value.aspectRatio,
                  child: VideoPlayer(widget.videoController),
                ),
              )
            : CircularProgressIndicator(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (widget.videoController.value.isPlaying) {
            widget.videoController.pause();
          } else {
            widget.videoController.play();
          }
        },
        child: Icon(
          widget.videoController.value.isPlaying
              ? Icons.pause
              : Icons.play_arrow,
        ),
      ),
    );
  }
}
