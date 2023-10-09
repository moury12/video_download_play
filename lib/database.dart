import 'dart:io';

import 'dart:async';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

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

  Future<dynamic> alterTable(String TableName, String ColumneName) async {
    final db = await database;
    var count = await db.execute("ALTER TABLE $TableName ADD "
        "COLUMN $ColumneName TEXT;");

    return count;
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

  Future<void> deleteAllFiles() async {
    final db =
        await database; // Replace 'database' with your database reference
    await db.delete('files'); // 'files' should be replaced with your table name
  }
}
