import 'dart:io';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class BibleService {
  static final Map<String, Database> _openedDbs = {};

  static Future<Database> getDatabase(String dbName) async {
    if (_openedDbs.containsKey(dbName)) return _openedDbs[dbName]!;
    var databasesPath = await getDatabasesPath();
    var path = join(databasesPath, dbName);

    if (!await databaseExists(path)) {
      ByteData data = await rootBundle.load("assets/mybible/$dbName");
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes, flush: true);
    }
    Database db = await openDatabase(path, readOnly: true);
    _openedDbs[dbName] = db;
    return db;
  }

  static Future<List<Map<String, dynamic>>> getVerses({
    required String translation, required int book, required int chapter,
  }) async {
    String dbName = (translation == "개역개정") ? "nrkv_bible.db" :
    (_isForeign(translation) ? "foreign_bible.db" : "general_bible.db");
    try {
      final db = await getDatabase(dbName);
      return await db.rawQuery('SELECT Scripture, verse FROM "$translation" WHERE book=$book AND chapter=$chapter ORDER BY verse ASC');
    } catch (e) {
      final fallbackDb = await getDatabase("general_bible.db");
      return await fallbackDb.rawQuery('SELECT Scripture, verse FROM "$translation" WHERE book=$book AND chapter=$chapter ORDER BY verse ASC');
    }
  }

  static Future<List<Map<String, dynamic>>> search({
    required String translation, required String query, required List<int> bookIds
  }) async {
    String dbName = (translation == "개역개정") ? "nrkv_bible.db" : "general_bible.db";
    final db = await getDatabase(dbName);
    String bookList = bookIds.join(',');
    return await db.rawQuery(
        'SELECT book, chapter, verse, Scripture FROM "$translation" WHERE book IN ($bookList) AND Scripture LIKE ? ORDER BY book ASC, chapter ASC, verse ASC',
        ['%$query%']
    );
  }

  static Future<List<int>> getAvailableVerses(int book, int chapter) async {
    try {
      final db = await getDatabase("HokmahKor.cmt.mybible");
      try {
        final List<Map<String, dynamic>> result = await db.rawQuery(
          'SELECT DISTINCT fromverse FROM commentary WHERE book = ? AND chapter = ? ORDER BY fromverse ASC',
          [book, chapter]
        );
        return result.map((row) => row['fromverse'] as int).toList();
      } catch (e) {
        final List<Map<String, dynamic>> result = await db.rawQuery(
          'SELECT DISTINCT "from verse" as fromverse FROM commentary WHERE book = ? AND chapter = ? ORDER BY fromverse ASC',
          [book, chapter]
        );
        return result.map((row) => row['fromverse'] as int).toList();
      }
    } catch (e) {
      return [];
    }
  }

  static Future<String?> getHokmaCommentary(int book, int chapter, int verse) async {
    try {
      final db = await getDatabase("HokmahKor.cmt.mybible");
      try {
        final result = await db.rawQuery(
          'SELECT data FROM commentary WHERE book = ? AND chapter = ? AND ? BETWEEN fromverse AND toverse',
          [book, chapter, verse]
        );
        if (result.isNotEmpty) return result.first['data'] as String?;
      } catch (e) {
        final result = await db.rawQuery(
          'SELECT data FROM commentary WHERE book = ? AND chapter = ? AND ? BETWEEN "from verse" AND toverse',
          [book, chapter, verse]
        );
        if (result.isNotEmpty) return result.first['data'] as String?;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  static bool _isForeign(String t) {
    String tl = t.toLowerCase();
    return tl.contains("lxx") || tl.contains("berean") || tl.contains("kjv") ||
        tl.contains("네팔어") || tl.contains("독일어") || tl.contains("러시아어") ||
        tl.contains("베트남어") || tl.contains("일본어") || tl.contains("중국어") ||
        tl.contains("터키어") || tl.contains("프랑스어") || tl.contains("히브리어");
  }

  static Future<String?> getStrongDefinition(String code) async {
    final db = await getDatabase("strong.dct.mybible");
    String type = code.substring(0, 1), numOnly = code.substring(1), padded = numOnly.padLeft(5, '0');
    final result = await db.rawQuery("SELECT data FROM dictionary WHERE word = ? OR word = ? OR word = ?", [code, numOnly, type + padded]);
    return result.isNotEmpty ? result.first['data'] as String : null;
  }
}
