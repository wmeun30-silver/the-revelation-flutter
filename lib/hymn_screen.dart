import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'hymn_service.dart';

class HymnScreen extends StatefulWidget {
  final String type;
  final int no;
  final VoidCallback? onPlayStarted;
  const HymnScreen({super.key, required this.type, required this.no, this.onPlayStarted});

  @override
  State<HymnScreen> createState() => HymnScreenState();
}

class HymnScreenState extends State<HymnScreen> {
  late String _currentType;
  late int _currentNo;
  String _title = "로딩 중...", _content = "";
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false, _isScoreVisible = false;
  double _currentSpeed = 1.0;
  int _repeatMode = 2;
  Duration _duration = Duration.zero, _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _currentType = widget.type;
    _currentNo = widget.no;
    _refresh();
    _audioPlayer.onDurationChanged.listen((d) => setState(() => _duration = d));
    _audioPlayer.onPositionChanged.listen((p) => setState(() => _position = p));
    _audioPlayer.onPlayerComplete.listen((event) {
      if (_repeatMode == 1) { _startPlay(); }
      else if (_repeatMode == 2) { _changeNo(1); }
      else { setState(() => _isPlaying = false); }
    });
    if (_currentType == "찬송가") _startPlay();
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  void stopAudio() { _audioPlayer.stop(); setState(() => _isPlaying = false); }

  void _refresh() async {
    if (_currentType == "주기도문") {
      setState(() {
        _title = "주기도문";
        _content = "하늘에 계신 우리 아버지여,\n이름이 거룩히 여김을 받으시오며,\n나라이 임하옵시며,\n뜻이 하늘에서 이룬 것 같이\n땅에서도 이루어지이다.\n\n"
            "오늘날 우리에게 일용할 양식을 주옵시고,\n우리가 우리에게 죄 지은 자를 사하여 준 것 같이\n우리 죄를 사하여 주옵시고,\n우리를 시험에 들게 하지 마옵시고,\n다만 악에서 구하옵소서.\n\n"
            "(대개 나라와 권세와 영광이\n아버지께 영원히 있사옵나이다. 아멘.)\n\n"
            "---------------------------------\n\n"
            "Our Father which art in heaven,\nHallowed be thy name.\nThy kingdom come.\nThy will be done in earth, as it is in heaven.\n\n"
            "Give us this day our daily bread.\nAnd forgive us our debts,\nas we forgive our debtors.\nAnd lead us not into temptation,\nbut deliver us from evil:\n\n"
            "For thine is the kingdom,\nand the power, and the glory, for ever. Amen.";
      });
      return;
    }
    if (_currentType == "사도신경") {
      setState(() {
        _title = "사도신경";
        _content = "전능하사 천지를 만드신\n하나님 아버지를 내가 믿사오며,\n그 외아들 우리 주 예수 그리스도를 믿사오니,\n이는 성령으로 잉태하사\n동정녀 마리아에게 나시고,\n본디오 빌라도에게 고난을 받으사,\n십자가에 못 박혀 죽으시고,\n장사한지 사흘 만에\n죽은 자 가운데서 다시 살아나시며,\n\n"
            "하늘에 오르사,\n전능하신 하나님 우편에 앉아 계시다가,\n저리로서 산 자와 죽은 자를 심판하러 오시리라.\n\n"
            "성령을 믿사오며,\n거룩한 공회와 성도가 서로 교통하는 것과,\n죄를 사하여 주시는 것과,\n몸이 다시 사는 것과,\n영원히 사는 것을 믿사옵나이다. 아멘.\n\n"
            "---------------------------------\n\n"
            "I believe in God the Father Almighty,\nMaker of heaven and earth,\nand in Jesus Christ his only Son our Lord,\nwho was conceived by the Holy Ghost,\nborn of the Virgin Mary,\nsuffered under Pontius Pilate,\nwas crucified, dead, and buried;\nhe descended into hell;\nthe third day he rose again from the dead;\n\n"
            "he ascended into heaven,\nand sitteth on the right hand\nof God the Father Almighty;\nfrom thence he shall come\nto judge the quick and the dead.\n\n"
            "I believe in the Holy Ghost;\nthe holy catholic Church;\nthe communion of saints;\nthe forgiveness of sins;\nthe resurrection of the body;\nand the life everlasting. Amen.";
      });
      return;
    }

    try {
      String fileName = (_currentType == "찬송가") ? "new_song.txt" : "교독문.txt";
      final data = await HymnService.loadData(fileName, _currentNo);
      
      setState(() {
        String titleRaw = data["title"] ?? "";
        if (titleRaw == "에러" || titleRaw.isEmpty) {
          _title = "$_currentNo장 (데이터 없음)";
          _content = "본문 데이터를 찾을 수 없거나 불러오는 데 실패했습니다.";
        } else {
          _title = titleRaw.replaceFirst(".", "장 ");
          _content = data["content"] ?? "";
        }
      });
    } catch (e) {
      setState(() {
        _title = "오류";
        _content = "데이터 로딩 중 오류가 발생했습니다.";
      });
    }
  }

  void _changeNo(int offset) async {
    if (_currentType == "주기도문" || _currentType == "사도신경") return;
    await _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
      int maxNo = (_currentType == "찬송가") ? 645 : 137;
      _currentNo += offset;
      if (_currentNo < 1) _currentNo = 1;
      if (_currentNo > maxNo) _currentNo = maxNo;
      _refresh();
      if (_currentType == "찬송가") _startPlay();
    });
  }

  Future<String> _getAudioBasePath() async {
    if (Platform.isAndroid) {
      return "/storage/emulated/0/com.bms.bible";
    } else if (Platform.isIOS) {
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    }
    return "";
  }

  void _startPlay() async {
    if (_currentType != "찬송가") return;
    if (await Permission.audio.request().isGranted || await Permission.storage.request().isGranted) {
      if (widget.onPlayStarted != null) widget.onPlayStarted!();
      
      String basePath = await _getAudioBasePath();
      String path = "$basePath/source/hymn/${_currentNo.toString().padLeft(3, '0')}.mp3";
      
      if (await File(path).exists()) {
        await _audioPlayer.play(DeviceFileSource(path));
        await _audioPlayer.setPlaybackRate(_currentSpeed);
        setState(() => _isPlaying = true);
      }
    }
  }

  Widget _buildContent() {
    if (_content.isEmpty || _title.contains("데이터 없음")) {
      return Center(child: Text(_content, style: const TextStyle(fontSize: 18, color: Colors.grey)));
    }

    if (_currentType != "교독문") {
      return Text(_content, style: const TextStyle(fontSize: 24, height: 1.4, fontFamily: 'serif'));
    }

    List<TextSpan> spans = [];
    List<String> lines = _content.split('\n');

    for (var line in lines) {
      if (line.trim().isEmpty) continue;

      if (line.startsWith('-')) {
        spans.add(const TextSpan(text: "(사회)\n", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 24, fontFamily: 'serif')));
        spans.add(TextSpan(text: line.substring(1).trim() + "\n\n", style: const TextStyle(color: Colors.black87, fontSize: 28, fontFamily: 'serif')));
      } else if (line.startsWith('=')) {
        spans.add(const TextSpan(text: "(청중)\n", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 24, fontFamily: 'serif')));
        spans.add(TextSpan(text: line.substring(1).trim() + "\n\n", style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 28, fontFamily: 'serif')));
      } else {
        spans.add(TextSpan(text: line + "\n\n", style: const TextStyle(fontSize: 28, fontFamily: 'serif')));
      }
    }

    return Text.rich(
      TextSpan(children: spans),
      style: const TextStyle(height: 1.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    String fNo = _currentNo.toString().padLeft(3, '0');
    double bottomPadding = MediaQuery.of(context).padding.bottom;
    bool isFixedText = _currentType == "주기도문" || _currentType == "사도신경";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF001A33),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: Text(_title, style: const TextStyle(color: Colors.yellow, fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          if (_currentType == "찬송가") GestureDetector(
            onTap: () => setState(() => _isScoreVisible = !_isScoreVisible),
            child: Padding(
              padding: const EdgeInsets.only(right: 15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    _isScoreVisible ? 'assets/img/button/btn5.png' : 'assets/img/button/akbo.png',
                    width: 30, 
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.music_note, color: Colors.white),
                  ),
                  Text(
                    _isScoreVisible ? "가사" : "악보",
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 180),
                child: _isScoreVisible && _currentType == "찬송가"
                    ? Center(
                        child: InteractiveViewer(
                          child: Image.asset(
                            'assets/img/new_song/$fNo.JPG', 
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, s) => const Center(child: Text("악보 이미지가 없습니다.")),
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20), 
                  child: _buildContent(),
                ),
              ),
            ),
          ]),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: EdgeInsets.fromLTRB(0, 0, 0, bottomPadding + 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 5)],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (_currentType == "찬송가") Slider(
                  activeColor: Colors.redAccent, 
                  value: _position.inSeconds.toDouble().clamp(0.0, _duration.inSeconds > 0 ? _duration.inSeconds.toDouble() : 1.0),
                  max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1.0, 
                  onChanged: (v) => _audioPlayer.seek(Duration(seconds: v.toInt())),
                ),
                
                if (_currentType == "찬송가") Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center, 
                    children: [1.0, 1.25, 1.5, 1.75, 2.0].map((s) => GestureDetector(
                      onTap: () { setState(() => _currentSpeed = s); _audioPlayer.setPlaybackRate(s); },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: _currentSpeed == s ? Colors.red.withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          "${s}x", 
                          style: TextStyle(
                            fontSize: 15, 
                            fontWeight: _currentSpeed == s ? FontWeight.bold : FontWeight.normal, 
                            color: _currentSpeed == s ? Colors.red : Colors.grey[700]
                          ),
                        ),
                      ),
                    )).toList(),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 5, 15, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(onTap: () => Navigator.maybePop(context), child: Image.asset('assets/img/button/home_btn.png', width: 45)),
                      if (!isFixedText) GestureDetector(onTap: () => _changeNo(-1), child: Image.asset('assets/img/button/l_arrow_btn.png', width: 50)),
                      if (isFixedText) const SizedBox(width: 50),
                      if (_currentType == "찬송가") GestureDetector(
                        onTap: () => _isPlaying ? _audioPlayer.pause().then((_) => setState(() => _isPlaying = false)) : _startPlay(),
                        child: Image.asset(_isPlaying ? 'assets/img/button/pause_btn.png' : 'assets/img/button/play_btn.png', width: 65),
                      ),
                      if (_currentType != "찬송가") const SizedBox(width: 65),
                      if (!isFixedText) GestureDetector(onTap: () => _changeNo(1), child: Image.asset('assets/img/button/r_arrow_btn.png', width: 50)),
                      if (isFixedText) const SizedBox(width: 50),
                      if (!isFixedText) GestureDetector(
                        onTap: () => setState(() => _repeatMode = (_repeatMode + 1) % 3),
                        child: Image.asset(
                          'assets/img/button/repeat_btn.png', 
                          width: 40, 
                          color: _repeatMode == 0 ? Colors.grey : (_repeatMode == 1 ? Colors.orange : Colors.blue)
                        ),
                      ),
                      if (isFixedText) const SizedBox(width: 40),
                    ],
                  ),
                ),
              ]),
            ),
          )
        ],
      ),
    );
  }
}
