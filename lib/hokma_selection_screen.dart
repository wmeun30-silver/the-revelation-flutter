import 'package:flutter/material.dart';
import 'bible_data.dart';
import 'bible_service.dart';
import 'hokma_content_screen.dart';

class HokmaSelectionScreen extends StatefulWidget {
  const HokmaSelectionScreen({super.key});
  @override
  State<HokmaSelectionScreen> createState() => _HokmaSelectionScreenState();
}

class _HokmaSelectionScreenState extends State<HokmaSelectionScreen> {
  int selectedBook = 1;
  int selectedChapter = 1;
  int selectedVerse = 0;
  List<int> availableVerses = [];

  @override
  void initState() {
    super.initState();
    _updateAvailableVerses();
  }

  // 선택된 권/장에 주석이 있는 절 목록을 DB에서 가져옴
  Future<void> _updateAvailableVerses() async {
    final verses = await BibleService.getAvailableVerses(selectedBook, selectedChapter);
    setState(() {
      availableVerses = verses;
      selectedVerse = 0; // 초기화
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("호크마 주석", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF001A33),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFFE8F5E9),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: const Row(
              children: [
                Expanded(child: Center(child: Text("권", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)))),
                Expanded(child: Center(child: Text("장", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)))),
                Expanded(child: Center(child: Text("절", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)))),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                _buildColumn(BibleData.bookNames, selectedBook - 1, (i) async {
                  setState(() { selectedBook = i + 1; selectedChapter = 1; });
                  await _updateAvailableVerses();
                }),
                const VerticalDivider(width: 1),
                _buildColumn(List.generate(BibleData.maxChapters[selectedBook - 1], (i) => "${i + 1}장"), selectedChapter - 1, (i) async {
                  setState(() { selectedChapter = i + 1; });
                  await _updateAvailableVerses();
                }),
                const VerticalDivider(width: 1),
                _buildColumn(
                    availableVerses.isEmpty ? ["없음"] : availableVerses.map((v) => "$v절").toList(),
                    availableVerses.indexOf(selectedVerse),
                    (i) {
                      if (availableVerses.isNotEmpty) {
                        int verse = availableVerses[i];
                        // 절을 선택하면 즉시 주석 화면으로 이동
                        Navigator.push(context, MaterialPageRoute(builder: (context) =>
                            HokmaContentScreen(book: selectedBook, chapter: selectedChapter, verse: verse)));
                      }
                    }
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumn(List<String> items, int selectedIdx, Function(int) onSelected) {
    return Expanded(
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          bool isSelected = index == selectedIdx;
          return GestureDetector(
            onTap: () => onSelected(index),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFC8E6C9) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(items[index], textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.green[900] : Colors.black87)),
            ),
          );
        },
      ),
    );
  }
}
