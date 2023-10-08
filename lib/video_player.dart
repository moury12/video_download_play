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

class VideoPlayerScreen extends StatelessWidget {
  final VideoPlayerController videoController;

  VideoPlayerScreen({required this.videoController});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Player'),
      ),
      body: Center(
        child: videoController.value.isInitialized
            ? Container(
                child: AspectRatio(
                  aspectRatio: videoController.value.aspectRatio,
                  child: VideoPlayer(videoController),
                ),
              )
            : CircularProgressIndicator(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (videoController.value.isPlaying) {
            videoController.pause();
          } else {
            videoController.play();
          }
        },
        child: Icon(
          videoController.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}
