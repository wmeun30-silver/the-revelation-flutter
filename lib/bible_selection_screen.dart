import 'package:flutter/material.dart';
import 'bible_data.dart';
import 'bible_screen.dart';

class BibleSelectionScreen extends StatelessWidget {
  final bool isMainTab; // 메인 탭에서 호출되었는지 확인

  const BibleSelectionScreen({super.key, this.isMainTab = false});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("성경 선택", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF001A33),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [Tab(text: "구약성경"), Tab(text: "신약성경")],
            labelColor: Colors.yellow,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: TabBarView(
          children: [
            _buildBookGrid(context, 0, 39, Colors.blue[50]!),
            _buildBookGrid(context, 39, 66, Colors.green[50]!),
          ],
        ),
      ),
    );
  }

  Widget _buildBookGrid(BuildContext context, int start, int end, Color bgColor) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, childAspectRatio: 2.2, crossAxisSpacing: 10, mainAxisSpacing: 10,
      ),
      itemCount: end - start,
      itemBuilder: (context, index) {
        int bookIdx = start + index;
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => _showChapterDialog(context, bookIdx),
          child: Text(BibleData.bookNames[bookIdx],
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold)),
        );
      },
    );
  }

  void _showChapterDialog(BuildContext context, int bookIdx) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("${BibleData.bookNames[bookIdx]} 장 선택"),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
            itemCount: BibleData.maxChapters[bookIdx],
            itemBuilder: (context, index) => TextButton(
              onPressed: () {
                final result = {'book': bookIdx + 1, 'chapter': index + 1};
                // 선택 즉시 팝업을 먼저 닫습니다.
                Navigator.pop(context, result);
              },
              child: Text("${index + 1}", style: const TextStyle(fontSize: 16)),
            ),
          ),
        ),
      ),
    ).then((result) {
      if (result != null) {
        if (isMainTab) {
          // 메인 탭에서 선택한 경우 팝업이 닫힌 후 본문 화면으로 이동합니다.
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => BibleScreen(book: result['book']!, chapter: result['chapter']!)
          ));
        } else {
          // 성경 본문 내 목록 버튼으로 들어온 경우 결과를 부모 화면에 전달합니다.
          Navigator.pop(context, result);
        }
      }
    });
  }
}
