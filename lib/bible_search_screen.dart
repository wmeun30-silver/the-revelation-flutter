import 'package:flutter/material.dart';
import 'bible_service.dart';
import 'bible_data.dart';

class BibleSearchScreen extends StatefulWidget {
  final String translation;
  const BibleSearchScreen({super.key, required this.translation});
  @override
  State<BibleSearchScreen> createState() => _BibleSearchScreenState();
}

class _BibleSearchScreenState extends State<BibleSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _selectedScope = "전체";
  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;

  final Map<String, List<int>> _scopes = {
    "전체": List.generate(66, (i) => i + 1),
    "구약전체": List.generate(39, (i) => i + 1),
    "신약전체": List.generate(27, (i) => i + 40),
    "모세오경": [1, 2, 3, 4, 5],
    "역사서(구약)": [6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17],
    "시가서": [18, 19, 20, 21, 22],
    "선지서": List.generate(17, (i) => i + 23),
    "사복음서": [40, 41, 42, 43],
    "바울서신서": [45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57],
  };

  void _handleSearch() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _isSearching = true);
    final data = await BibleService.search(translation: widget.translation, query: _controller.text.trim(), bookIds: _scopes[_selectedScope]!);
    setState(() { _results = data; _isSearching = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF001A33),
        automaticallyImplyLeading: false,
        title: Row(children: [
          ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: const Size(40, 30)), child: const Text("Back", style: TextStyle(fontSize: 10))),
          const SizedBox(width: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: DropdownButton<String>(value: _selectedScope, underline: Container(), items: _scopes.keys.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13, color: Colors.black)))).toList(), onChanged: (v) => setState(() => _selectedScope = v!))),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 40, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: TextField(controller: _controller, decoration: InputDecoration(hintText: "검색어", contentPadding: const EdgeInsets.only(left: 15, bottom: 10), border: InputBorder.none, suffixIcon: IconButton(icon: const Icon(Icons.search, size: 20), onPressed: _handleSearch)), onSubmitted: (_) => _handleSearch()))),
        ]),
      ),
      body: _isSearching ? const Center(child: CircularProgressIndicator()) : ListView.builder(itemCount: _results.length, itemBuilder: (context, index) {
        final r = _results[index];
        return ListTile(title: Text("${BibleData.bookNames[r['book']-1]} ${r['chapter']}:${r['verse']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)), subtitle: Text(r['Scripture'], style: const TextStyle(fontSize: 18, color: Colors.black, fontFamily: 'serif')), onTap: () => Navigator.pop(context, {'book': r['book'], 'chapter': r['chapter']}));
      }),
    );
  }
}