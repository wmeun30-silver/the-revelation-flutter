import 'package:flutter/services.dart' show rootBundle;

class HymnService {
  static Future<List<String>> getAllTitles(String fileName) async {
    try {
      final String fullText = await rootBundle.loadString('assets/$fileName');
      final List<String> lines = fullText.split('\n');
      List<String> titles = [];
      for (var line in lines) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty && RegExp(r'^\d+\.').hasMatch(trimmed)) {
          titles.add(trimmed);
        }
      }
      return titles;
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, String>> loadData(String fileName, int targetNo) async {
    try {
      final String fullText = await rootBundle.loadString('assets/$fileName');
      final List<String> lines = fullText.split('\n');
      String title = "";
      String content = "";
      bool found = false;

      final targetPrefix = "$targetNo.";

      for (var line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        if (trimmed.startsWith(targetPrefix)) {
          title = trimmed;
          found = true;
          continue;
        }
        
        if (found && RegExp(r'^\d+\.').hasMatch(trimmed)) break;
        
        if (found) {
          if (trimmed.startsWith("(")) {
            if (content.isNotEmpty) content += "\n";
          }
          content += "$trimmed\n";
        }
      }
      return {"title": title, "content": content};
    } catch (e) {
      return {"title": "에러", "content": "데이터를 불러오는 중 오류가 발생했습니다."};
    }
  }
}
