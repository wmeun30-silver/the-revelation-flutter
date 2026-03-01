import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'hymn_service.dart';
import 'hymn_screen.dart';

class HymnListScreen extends StatefulWidget {
  const HymnListScreen({super.key});

  @override
  State<HymnListScreen> createState() => _HymnListScreenState();
}

class _HymnListScreenState extends State<HymnListScreen> {
  String currentType = "찬송가";
  String currentRange = "전체";
  List<String> allItems = [];
  List<String> filteredItems = [];

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  void _loadList() async {
    if (currentType == "주기도문" || currentType == "사도신경") {
      final selectedType = currentType; // 값을 캡처하여 비동기 처리 시 변경되지 않도록 함
      Future.microtask(() {
        Navigator.push(context, MaterialPageRoute(builder: (context) => HymnScreen(type: selectedType, no: 1)));
        setState(() { currentType = "찬송가"; _loadList(); });
      });
      return;
    }

    // 소요리문답 선택 시 전체 화면 PDF 뷰어로 이동 (하단바 숨김 효과)
    if (currentType == "소요리문답") {
      Future.microtask(() {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const CatechismPdfScreen()));
        setState(() { currentType = "찬송가"; _loadList(); });
      });
      return;
    }

    String fileName = (currentType == "찬송가") ? "new_song.txt" : "교독문.txt";
    final titles = await HymnService.getAllTitles(fileName);
    setState(() {
      allItems = titles;
      _filterItems();
    });
  }

  void _filterItems() {
    if (currentRange == "전체") {
      filteredItems = allItems;
    } else {
      final parts = currentRange.split('-');
      int start = int.parse(parts[0]);
      int end = int.parse(parts[1]);
      setState(() {
        filteredItems = allItems.where((item) {
          int num = int.parse(item.split('.')[0]);
          return num >= start && num <= end;
        }).toList();
      });
    }
  }

  List<String> _getRangeOptions() {
    if (currentType == "찬송가") {
      return ["전체", "1-100", "101-200", "201-300", "301-400", "401-500", "501-600", "601-645"];
    } else if (currentType == "교독문") {
      return ["전체", "1-50", "51-100", "101-137"];
    } else {
      return ["전체"];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF8BC34A),
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: DropdownButton<String>(
                value: currentType,
                underline: Container(),
                items: ["찬송가", "교독문", "주기도문", "사도신경", "소요리문답"].map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 14, color: Colors.black)))).toList(),
                onChanged: (v) { setState(() { currentType = v!; currentRange = "전체"; _loadList(); }); },
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: Image.asset('assets/img/button/home_btn.png', width: 40, height: 40, errorBuilder: (c,e,s) => const Icon(Icons.home)),
            ),
            if (currentType == "찬송가" || currentType == "교독문") Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: DropdownButton<String>(
                value: currentRange,
                underline: Container(),
                items: _getRangeOptions().map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 14, color: Colors.black)))).toList(),
                onChanged: (v) { setState(() { currentRange = v!; _filterItems(); }); },
              ),
            ) else const SizedBox(width: 60),
          ],
        ),
      ),
      body: ListView.separated(
        itemCount: filteredItems.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = filteredItems[index];
          return ListTile(
            title: Text(item, style: const TextStyle(fontSize: 18)),
            onTap: () {
              int num = int.parse(item.split('.')[0]);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HymnScreen(type: currentType, no: num)),
              );
            },
          );
        },
      ),
    );
  }
}

// 전체 화면 PDF 뷰어 클래스 (하단바 없음)
class CatechismPdfScreen extends StatelessWidget {
  const CatechismPdfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF001A33),
        title: const Text("신조와 소요리문답", style: TextStyle(color: Colors.yellow, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SfPdfViewer.asset("assets/12creed_Catechism.pdf"),
    );
  }
}
