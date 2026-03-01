import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'bible_service.dart';
import 'bible_data.dart';

class HokmaContentScreen extends StatefulWidget {
  final int book, chapter, verse;
  const HokmaContentScreen({super.key, required this.book, required this.chapter, required this.verse});
  @override
  State<HokmaContentScreen> createState() => _HokmaContentScreenState();
}

class _HokmaContentScreenState extends State<HokmaContentScreen> {
  late int b, c, v;
  String content = "로딩 중...";

  @override
  void initState() {
    super.initState();
    b = widget.book; c = widget.chapter; v = widget.verse;
    _loadContent();
  }

  void _loadContent() async {
    setState(() => content = "데이터를 불러오는 중...");
    final data = await BibleService.getHokmaCommentary(b, c, v);
    setState(() { content = data ?? "해당 구절(${v}절)에 대한 주석 정보가 없습니다."; });
  }

  void _move(int offset) async {
    final list = await BibleService.getAvailableVerses(b, c);
    int idx = list.indexOf(v);
    if (idx != -1) {
      int nextIdx = idx + offset;
      if (nextIdx >= 0 && nextIdx < list.length) {
        setState(() { v = list[nextIdx]; _loadContent(); });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF001A33),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context), 
          child: Padding(padding: const EdgeInsets.all(12), child: Image.asset('assets/img/button/home_btn.png'))
        ),
        // 제목 좌우에 화살표 배치
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _move(-1), 
              child: Image.asset('assets/img/button/l_arrow_btn.png', width: 35)
            ),
            const SizedBox(width: 10),
            Text("${BibleData.bookNames[b-1]} ${c}장 ${v}절", 
                style: const TextStyle(color: Colors.yellow, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _move(1), 
              child: Image.asset('assets/img/button/r_arrow_btn.png', width: 35)
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10), 
        child: Html(
          data: content,
          style: {
            "body": Style(
              fontSize: FontSize(22),
              lineHeight: LineHeight(1.6),
              fontFamily: 'serif',
              color: Colors.black, // 본문 글자색 명시
            ),
          },
        )
      ),
    );
  }
}
