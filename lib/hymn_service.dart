import 'package:flutter/services.dart' show rootBundle;

class HymnService {
  // 파일에서 모든 제목 목록(1. ..., 2. ...)만 추출하여 가져오는 함수
  static Future<List<String>> getAllTitles(String fileName) async {
    try {      final String fullText = await rootBundle.loadString('assets/$fileName');
    final List<String> lines = fullText.split('\n');
    List<String> titles = [];
    for (var line in lines) {
      line = line.trim();
      if (line.isNotEmpty && RegExp(r'^\d+\.').hasMatch(line)) {
        titles.add(line);
      }
    }
    return titles;
    } catch (e) {
      return [];
    }
  }

  // 본문 내용을 읽어오는 함수
  static Future<Map<String, String>> loadData(String fileName, int targetNo) async {
    try {
      final String fullText = await rootBundle.loadString('assets/$fileName');
      final List<String> lines = fullText.split('\n');
      String title = "";
      String content = "";
      bool found = false;

      for (var line in lines) {
        line = line.trim();
        if (line.isEmpty) continue;
        if (line.startsWith("$targetNo.")) {
          title = line;
          found = true;
          continue;
        }
        if (found && RegExp(r'^\d+\.').hasMatch(line)) break;
        if (found) {
          if (line.startsWith("(")) {
            if (content.isNotEmpty) content += "\n";
          }
          content += "$line\n";
        }
      }
      return {"title": title, "content": content};
    } catch (e) {
      return {"title": "에러", "content": "파일을 읽지 못했습니다."};
    }
  }
}