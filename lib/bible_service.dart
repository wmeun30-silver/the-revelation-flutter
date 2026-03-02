import 'dart:io';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class BibleService {
  static final Map<String, Database> _openedDbs = {};
  static String lastSuccessDb = "연결 시도 중...";

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

  static Future<String?> _findActualTableName(Database db, String targetName) async {
    try {
      final List<Map<String, dynamic>> allTables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      for (var row in allTables) {
        String name = row['name'] as String;
        if (name.toLowerCase() == targetName.toLowerCase()) return name;
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>> getVersesWithDb({required String translation, required int book, required int chapter}) async {
    List<String> dbsToSearch = ["general_bible.db", "foreign_bible.db", "nrkv_bible.db"];
    if (translation.toLowerCase().contains("kjv")) {
      dbsToSearch = ["foreign_bible.db", "general_bible.db", "nrkv_bible.db"];
    }

    for (String dbName in dbsToSearch) {
      try {
        final db = await getDatabase(dbName);
        String? actualTable = await _findActualTableName(db, translation);
        if (actualTable == null) continue;

        final List<Map<String, dynamic>> result = await db.rawQuery(
          'SELECT Scripture, verse FROM "$actualTable" WHERE book = ? AND chapter = ? ORDER BY verse ASC',
          [book, chapter]
        );
        if (result.isNotEmpty) {
          lastSuccessDb = dbName;
          return {"verses": result, "db": dbName, "table": actualTable};
        }
      } catch (e) { continue; }
    }
    return {"verses": [], "db": "데이터 없음", "table": "없음"};
  }

  static Future<List<Map<String, dynamic>>> getVerses({required String translation, required int book, required int chapter}) async {
    final res = await getVersesWithDb(translation: translation, book: book, chapter: chapter);
    return res["verses"] as List<Map<String, dynamic>>;
  }

  static Future<List<Map<String, dynamic>>> search({required String translation, required String query, required List<int> bookIds}) async {
    try {
      final db = await getDatabase(translation == "개역개정" ? "nrkv_bible.db" : "general_bible.db");
      String? actualTable = await _findActualTableName(db, translation);
      if (actualTable == null) return [];
      String bookList = bookIds.join(',');
      return await db.rawQuery('SELECT book, chapter, verse, Scripture FROM "$actualTable" WHERE book IN ($bookList) AND Scripture LIKE ? ORDER BY book ASC, chapter ASC, verse ASC', ['%$query%']);
    } catch (e) { return []; }
  }

  static Future<List<int>> getAvailableVerses(int book, int chapter) async {
    try {
      final db = await getDatabase("HokmahKor.cmt.mybible");
      final List<Map<String, dynamic>> result = await db.rawQuery('SELECT DISTINCT fromverse FROM commentary WHERE book = ? AND chapter = ? ORDER BY fromverse ASC', [book, chapter]);
      return result.map((row) => row['fromverse'] as int).toList();
    } catch (e) { return []; }
  }

  static Future<String?> getHokmaCommentary(int book, int chapter, int verse) async {
    try {
      final db = await getDatabase("HokmahKor.cmt.mybible");
      final result = await db.rawQuery('SELECT data FROM commentary WHERE book = ? AND chapter = ? AND ? BETWEEN fromverse AND toverse', [book, chapter, verse]);
      if (result.isNotEmpty) return result.first['data'] as String?;
    } catch (e) { return null; }
    return null;
  }

  static Future<String?> getStrongDefinition(String code) async {
    try {
      final db = await getDatabase("strong.dct.mybible");
      String type = code.substring(0, 1), numOnly = code.substring(1), padded = numOnly.padLeft(5, '0');
      final result = await db.rawQuery("SELECT data FROM dictionary WHERE word = ? OR word = ? OR word = ?", [code, numOnly, type + padded]);
      return result.isNotEmpty ? result.first['data'] as String : null;
    } catch (e) { return null; }
  }
}
