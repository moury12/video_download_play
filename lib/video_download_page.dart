import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:video_dowload_play/video_player.dart';
import 'package:video_player/video_player.dart';

class OfflineFileManager {
  static final OfflineFileManager _singleton = OfflineFileManager._internal();

  factory OfflineFileManager() => _singleton;

  static Database? _database;

  OfflineFileManager._internal();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    final Directory documentsDirectory =
    await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, 'offline_files.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE files (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            filename TEXT,
            filepath TEXT,
            track INTEGER,
            userId TEXT,
            nowPlaying BOOLEAN
          )
        ''');
      },
    );
  }

  Future<int> insertFile(File file) async {
    final db = await database;
    final String fileName = basename(file.path);

    final Map<String, dynamic> fileMap = {
      'filename': fileName,
      'filepath': file.path,
      'track': 123,
      'userId': 'RT5RT5',
      'nowPlaying': false
    };

    return await db.insert('files', fileMap);
  }

  Future<List<Map<String, dynamic>>> getFiles() async {
    final db = await database;
    return await db.query('files');
  }

  Future<File?> getFileById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> result =
    await db.query('files', where: 'id = ?', whereArgs: [id]);

    if (result.isNotEmpty) {
      return File(result.first['filepath']);
    } else {
      return null;
    }
  }

  Future<void> deleteFile(int id) async {
    final db = await database;
    await db.delete('files', where: 'id = ?', whereArgs: [id]);
  }
}

class VideoDownloadScreen extends StatefulWidget {
  const VideoDownloadScreen({super.key});

  @override
  State<VideoDownloadScreen> createState() => _VideoDownloadScreenState();
}

class _VideoDownloadScreenState extends State<VideoDownloadScreen> {
  double _percentage = .000;
  String dowloadMessage = 'Waiting...';
  bool isDownloading = false;
  bool isWantCancel = false;
  CancelToken cancelToken = CancelToken();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FloatingActionButton(
              onPressed: () {
                setState(() {
                  isDownloading = !isDownloading;
                });
                downloadAndSaveFile(
                    'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
                    'video.mp4_${DateTime
                        .timestamp()
                        .millisecondsSinceEpoch}');
              },
              child: Icon(Icons.download),
            ),
            SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(dowloadMessage),
                Text((_percentage.floor()).toString()),
                isDownloading
                    ? isWantCancel
                    ? InkWell(
                    child: Icon(Icons.play_arrow),
                    onTap: () {
                      setState(() {
                        isDownloading = !isDownloading;
                      });
                      downloadAndSaveFile(
                          'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
                          'video_${DateTime
                              .timestamp()
                              .millisecondsSinceEpoch}.mp4');
                    })
                    : InkWell(
                  child: Icon(Icons.pause),
                  onTap: () {
                    cancelToken.cancel();
                    setState(() {
                      isWantCancel = true;
                    });
                  },
                )
                    : SizedBox.shrink()
              ],
            ),
            SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: LinearProgressIndicator(
                value: _percentage,
                backgroundColor:
                isWantCancel ? Colors.red.shade100 : Colors.green.shade100,
                color: isWantCancel ? Colors.red : Colors.green,
              ),
            ),
            SizedBox(
              height: 20,
            ),
            FloatingActionButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) {
                    return VideoListScreen();
                  },
                ));
              },
              child: Icon(Icons.play_arrow),
            )
          ],
        ),
      ),
    );
  }

  Future<void> downloadAndSaveFile(String fileUrl, String fileName) async {
    final dio = Dio();

    try {
      final response = await dio.get(
        cancelToken: cancelToken,
        onReceiveProgress: (count, total) {
          var percentage = count / total * 100;
          if (percentage < 100) {
            _percentage = percentage / 100;

            setState(() {
              dowloadMessage = "Downloading..${percentage.floor()}";
            });
          } else if (percentage == 100) {
            setState(() {
              dowloadMessage = "Completed..${percentage.floor()}";
              isDownloading = false;
            });
          }
        },

        fileUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = response.data;

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(bytes);
      final result = await OfflineFileManager().insertFile(file);

      if (result != -1) {
        print('File saved successfully');
      } else {
        print('File saved failed');

        // File insertion failed
      }
      print('File saved at: $filePath');
    } catch (e) {
      print('Error downloading and saving file: $e');
    }
  }

  Future<void> updateNotificationProgress(int progress, int total, String title,
      String body) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'download_progress',
      'Download Progress',

      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      // Enable progress indicator
      maxProgress: total,
      // Total progress value
      progress: progress, // Current progress value
    );

    final NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'item x',
    );
  }

}
