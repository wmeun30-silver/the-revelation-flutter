import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';

class RevelationStudyScreen extends StatefulWidget {
  const RevelationStudyScreen({super.key});

  @override
  State<RevelationStudyScreen> createState() => _RevelationStudyScreenState();
}

class _RevelationStudyScreenState extends State<RevelationStudyScreen> {
  String currentCategory = "장별 강해";
  List<String> items = [];
  String? selectedHtmlPath;
  String htmlContent = "";

  final List<String> churchFiles = [
    "1_Ephesus.html",
    "2_Smyrna.html",
    "3_Pergamo.html",
    "4_Thyatira.html",
    "5_Sardis.html",
    "6_Philadephia.html", // 파일명 오타 반영 (Philadelphia -> Philadephia)
    "7_Laodicea.html"
  ];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    if (currentCategory == "장별 강해") {
      items = ["0. 계시록 개관"];
      for (int i = 1; i <= 22; i++) {
        items.add("$i. $i장 강해");
      }
    } else {
      items = [
        "1. 에베소교회",
        "2. 서머나교회",
        "3. 버가모교회",
        "4. 두아디라교회",
        "5. 사데교회",
        "6. 빌라델비아교회",
        "7. 라오디게아교회"
      ];
    }
    setState(() {});
  }

  Future<void> _loadHtml(String path) async {
    try {
      String content = await rootBundle.loadString(path);
      setState(() {
        htmlContent = content;
        selectedHtmlPath = path;
      });
    } catch (e) {
      // 대소문자나 파일명 오타 대응
      try {
        String content = await rootBundle.loadString(path.toLowerCase());
        setState(() { htmlContent = content; selectedHtmlPath = path; });
      } catch (_) {
        setState(() {
          htmlContent = "<div style='color:red; text-align:center; padding:20px;'>파일을 찾을 수 없습니다: $path</div>";
          selectedHtmlPath = path;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF001A33),
        title: const Text("계시록 강해", style: TextStyle(color: Colors.yellow, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: selectedHtmlPath != null 
            ? IconButton(icon: const Icon(Icons.list, color: Colors.white), onPressed: () => setState(() => selectedHtmlPath = null))
            : null,
      ),
      body: Column(
        children: [
          if (selectedHtmlPath == null) Container(
            color: const Color(0xFF001A33),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: Row(
              children: [
                _buildTabButton("장별 강해"),
                const SizedBox(width: 10),
                _buildTabButton("일곱교회 강해"),
              ],
            ),
          ),
          Expanded(
            child: selectedHtmlPath == null ? _buildList() : _buildHtmlView(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label) {
    bool isSelected = currentCategory == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            currentCategory = label;
            _loadItems();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.yellow : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      itemCount: items.length,
      padding: const EdgeInsets.symmetric(vertical: 10),
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(items[index], style: const TextStyle(fontSize: 18, fontFamily: 'serif')),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          onTap: () {
            String path = "";
            if (currentCategory == "장별 강해") {
              path = (index == 0) ? "assets/Chapter/Chapter_menu.html" : "assets/Chapter/rev_$index.html";
            } else {
              path = "assets/7Churches/${churchFiles[index]}";
            }
            _loadHtml(path);
          },
        );
      },
    );
  }

  Widget _buildHtmlView() {
    return Container(
      color: Colors.white,
      height: double.infinity,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Html(
          data: htmlContent,
          style: {
            "body": Style(fontSize: FontSize(20), lineHeight: LineHeight(1.6), fontFamily: 'serif', color: Colors.black),
          },
        ),
      ),
    );
  }
}
