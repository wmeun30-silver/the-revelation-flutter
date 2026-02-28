import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class YoutubeScreen extends StatefulWidget {
  const YoutubeScreen({super.key});
  @override
  State<YoutubeScreen> createState() => YoutubeScreenState();
}

class YoutubeScreenState extends State<YoutubeScreen> {
  late YoutubePlayerController _controller;
  final TextEditingController _urlController = TextEditingController();
  String _previewTitle = "(주소를 입력하세요)";
  
  final List<Map<String, String>> _defaultList = [
    {"title": "100년 전 천국 간증 | 세네카 쏘디 1편", "url": "https://youtu.be/x-0_rlX6rUE"},
    {"title": "조용기 목사님 레전드 설교 - 낙망하고 불안해 하지 말라", "url": "https://youtu.be/u13qcd4AePQ"},
    {"title": "(뮤비) Heaven's Hallelujah @다비드실버", "url": "https://youtu.be/vj2KGCFnYXM"},
    {"title": "2시간 통성기도음악: 보혈찬양 연속듣기", "url": "https://www.youtube.com/watch?v=MltCEnth5nM"},
  ];

  List<Map<String, String>> _userList = [];

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: YoutubePlayer.convertUrlToId(_defaultList[0]["url"]!)!,
      flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
    );
    _loadUserList();
    _urlController.addListener(_onUrlChanged);
  }

  void pauseVideo() {
    _controller.pause();
  }

  void _onUrlChanged() {
    _updatePreviewTitle();
  }

  // 유튜브 oEmbed API를 사용하여 실제 동영상 제목을 가져옵니다.
  Future<void> _updatePreviewTitle() async {
    String url = _urlController.text.trim();
    if (url.isEmpty) {
      if (mounted) setState(() => _previewTitle = "(주소를 입력하세요)");
      return;
    }
    String? id = YoutubePlayer.convertUrlToId(url);
    if (id != null) {
      try {
        var response = await http.get(Uri.parse("https://www.youtube.com/oembed?url=$url&format=json"));
        if (response.statusCode == 200) {
          var data = json.decode(response.body);
          if (mounted) setState(() => _previewTitle = data['title'] ?? "제목 없음");
        } else {
          if (mounted) setState(() => _previewTitle = "영상 ID: $id");
        }
      } catch (e) {
        if (mounted) setState(() => _previewTitle = "영상 ID: $id");
      }
    } else {
      if (mounted) setState(() => _previewTitle = "올바른 주소가 아닙니다.");
    }
  }

  Future<void> _loadUserList() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('user_youtube_list');
    if (savedData != null) {
      setState(() {
        _userList = List<Map<String, String>>.from(
          json.decode(savedData).map((item) => Map<String, String>.from(item))
        );
      });
    }
  }

  Future<void> _saveUserList() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_youtube_list', json.encode(_userList));
  }

  void _addVideo() {
    String url = _urlController.text.trim();
    if (_previewTitle != "(주소를 입력하세요)" && _previewTitle != "올바른 주소가 아닙니다.") {
      setState(() {
        // '추가된 동영상' 문구 없이 실제 제목만 저장
        _userList.add({"title": _previewTitle, "url": url});
        _urlController.clear();
        _previewTitle = "(주소를 입력하세요)";
      });
      _saveUserList();
    }
  }

  void _deleteVideo(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("삭제 확인"),
        content: const Text("이 동영상을 리스트에서 삭제하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소")),
          TextButton(onPressed: () {
            setState(() { _userList.removeAt(index); });
            _saveUserList();
            Navigator.pop(context);
          }, child: const Text("삭제", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> fullList = [..._defaultList, ..._userList];

    return Scaffold(
      appBar: AppBar(
        title: const Text("유튜브 보기", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF001A33),
        centerTitle: true,
      ),
      body: Column(
        children: [
          YoutubePlayer(controller: _controller, showVideoProgressIndicator: true),
          const SizedBox(height: 20), // 위쪽을 조금 더 떼어놓음
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 미리보기 제목 표시 (빨간색 강조)
                Text(_previewTitle, 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          hintText: "유튜브 주소 붙여넣기", 
                          isDense: true, 
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addVideo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF001A33),
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                      ),
                      child: const Text("추가", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          const Divider(thickness: 1.5),
          Expanded(
            child: ListView.separated(
              itemCount: fullList.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = fullList[index];
                bool isDefault = index < _defaultList.length;
                return ListTile(
                  title: Text(item["title"]!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.play_circle_outline, color: Colors.red),
                  onTap: () {
                    String? id = YoutubePlayer.convertUrlToId(item["url"]!);
                    if (id != null) _controller.load(id);
                  },
                  onLongPress: isDefault ? null : () => _deleteVideo(index - _defaultList.length),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _urlController.dispose();
    super.dispose();
  }
}
