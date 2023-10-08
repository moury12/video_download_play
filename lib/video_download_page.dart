import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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
            filepath TEXT
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
                downloadAndSaveFile(
                    'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
                    'video.mp4_');
              },
              child: Icon(Icons.download),
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
}
