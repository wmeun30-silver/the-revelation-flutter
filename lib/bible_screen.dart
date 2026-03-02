import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'bible_service.dart';
import 'bible_data.dart';
import 'bible_selection_screen.dart';
import 'bible_search_screen.dart';
import 'package:flutter_html/flutter_html.dart';

class BibleScreen extends StatefulWidget {
  final int book;
  final int chapter;
  final bool initPlay;
  final VoidCallback? onPlayStarted;

  const BibleScreen({
    super.key,
    required this.book,
    required this.chapter,
    this.initPlay = true,
    this.onPlayStarted
  });

  @override
  State<BibleScreen> createState() => BibleScreenState();
}

class BibleScreenState extends State<BibleScreen> {
  static String currentTranslation = "개역개정";
  String compareTranslation = "none";
  late int currentBook, currentChapter;
  List<Map<String, dynamic>> mainVerses = [];
  Map<int, String> compareMap = {};
  
  List<GlobalKey> _itemKeys = [];
  int _lastScrolledIndex = -1;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();
  final ScrollController _scrollController = ScrollController();
  
  bool _isPlaying = false;
  bool _isTtsMode = false;
  double _currentSpeed = 1.0;
  int _repeatMode = 2; 
  Duration _duration = Duration.zero, _position = Duration.zero;
  int _currentTtsIndex = 0;

  final List<String> translations = ["개역개정", "개역한글", "새번역", "쉬운성경", "흠정역", "niv2011", "kjv1611", "nas2020", "히브리어", "LXX(헬라어)", "프랑스어", "독일어", "일본어", "중국어", "러시아어", "베트남어", "네팔어", "터키어", "berean-interlinear"];

  @override
  void initState() {
    super.initState();
    currentBook = widget.book;
    currentChapter = widget.chapter;
    
    // 초기 대조성경 설정
    _applyDefaultCompare();

    _initForegroundTask();
    _loadVerses();
    
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
    
    _audioPlayer.onDurationChanged.listen((d) { if(mounted) setState(() => _duration = d); });
    _audioPlayer.onPositionChanged.listen((p) { if(mounted) setState(() => _position = p); });
    _audioPlayer.onPlayerComplete.listen((event) {
      if (_repeatMode == 1) { _startPlay(); }
      else if (_repeatMode == 2) { _changeChapter(1, forcePlay: true); }
      else { stopAudio(); }
    });

    _flutterTts.setCompletionHandler(() {
      if (_isTtsMode && _isPlaying) {
        _currentTtsIndex++;
        if (_currentTtsIndex < mainVerses.length) {
          _speakVerse(_currentTtsIndex);
        } else {
          if (_repeatMode == 1) { _currentTtsIndex = 0; _speakVerse(0); }
          else if (_repeatMode == 2) { _changeChapter(1, forcePlay: true); }
          else { stopAudio(); }
        }
      }
    });

    if (widget.initPlay) {
      bool canPlay = currentTranslation != "kjv1611" && currentTranslation != "berean-interlinear";
      if (canPlay) {
        Future.delayed(const Duration(milliseconds: 500), () => _startPlay());
      }
    }
  }

  void _applyDefaultCompare() {
    // 특정 번역본 외에는 개역개정을 대조성경으로 디폴트 설정
    final List<String> noDefaultCompare = ["개역개정", "개역한글", "새번역", "쉬운성경", "흠정역"];
    if (!noDefaultCompare.contains(currentTranslation)) {
      compareTranslation = "개역개정";
    } else {
      compareTranslation = "none";
    }
  }

  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'bible_reading_channel',
        channelName: 'Bible Reading Service',
        channelDescription: 'Maintains bible reading in background',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
      ),
      iosNotificationOptions: const IOSNotificationOptions(showNotification: true, playSound: false),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000,
        isOnceEvent: false,
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  @override
  void dispose() {
    _stopForegroundService();
    WakelockPlus.disable();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    _flutterTts.stop();
    _scrollController.dispose();
    super.dispose();
  }

  void stopAudio() { 
    _stopForegroundService();
    WakelockPlus.disable();
    _audioPlayer.stop(); 
    _flutterTts.stop();
    if(mounted) setState(() { _isPlaying = false; _isTtsMode = false; }); 
  }

  Future<void> _stopForegroundService() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  Future<void> _loadVerses() async {
    final result = await BibleService.getVersesWithDb(
      translation: currentTranslation, 
      book: currentBook, 
      chapter: currentChapter
    );
    
    final List<Map<String, dynamic>> verses = result["verses"] as List<Map<String, dynamic>>;

    Map<int, String> cMap = {};
    if (compareTranslation != "none") {
      final compData = await BibleService.getVerses(translation: compareTranslation, book: currentBook, chapter: currentChapter);
      for (var v in compData) { cMap[v['verse']] = v['Scripture']; }
    }

    if(mounted) {
      setState(() { 
        mainVerses = verses; 
        compareMap = cMap; 
        _itemKeys = List.generate(mainVerses.length, (_) => GlobalKey());
        _lastScrolledIndex = -1;
      });
    }
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  void _changeChapter(int offset, {bool forcePlay = false}) async {
    stopAudio();
    if(mounted) {
      setState(() {
        if (offset > 0) {
          if (currentBook == 66 && currentChapter == BibleData.maxChapters[65]) return;
          if (currentChapter < BibleData.maxChapters[currentBook - 1]) currentChapter++;
          else { currentBook++; currentChapter = 1; }
        } else {
          if (currentBook == 1 && currentChapter == 1) return;
          if (currentChapter > 1) currentChapter--;
          else { currentBook--; currentChapter = BibleData.maxChapters[currentBook - 1]; }
        }
      });
    }
    await _loadVerses();
    
    bool canPlay = currentTranslation != "kjv1611" && currentTranslation != "berean-interlinear";
    if (canPlay) _startPlay();
  }

  void _changeNo(int offset) => _changeChapter(offset);

  Future<String> _getAudioBasePath() async {
    if (Platform.isAndroid) return "/storage/emulated/0/com.bms.bible";
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  void _startPlay() async {
    if (currentTranslation == "kjv1611" || currentTranslation == "berean-interlinear") {
      stopAudio(); return;
    }

    if (await Permission.audio.request().isGranted || await Permission.storage.request().isGranted) {
      if (Platform.isAndroid) await Permission.notification.request();
      WakelockPlus.enable();
      await FlutterForegroundTask.startService(
        notificationTitle: 'Bms Bible 낭독 중',
        notificationText: '${BibleData.bookNames[currentBook - 1]} $currentChapter장',
      );

      if (widget.onPlayStarted != null) widget.onPlayStarted!();
      
      String basePath = await _getAudioBasePath();
      String path = "$basePath/source/normal/0/$currentBook/${currentChapter.toString().padLeft(3, '0')}.mp3";
      
      if (currentTranslation == "개역개정" && await File(path).exists()) {
        try {
          await _audioPlayer.play(DeviceFileSource(path));
          await _audioPlayer.setPlaybackRate(_currentSpeed);
          if(mounted) setState(() { _isPlaying = true; _isTtsMode = false; });
        } catch (e) { stopAudio(); }
      } else { _startTts(); }
    }
  }

  void _startTts() async {
    String t = currentTranslation.toLowerCase();
    String lang = "ko-KR";
    if (t.contains("niv") || t.contains("kjv") || t.contains("nas")) lang = "en-US";
    else if (t.contains("히브리어")) lang = "he-IL";
    else if (t.contains("lxx") || t.contains("헬라어")) lang = "el-GR";
    else if (t.contains("프랑스어")) lang = "fr-FR";
    else if (t.contains("독일어")) lang = "de-DE";
    else if (t.contains("일본어")) lang = "ja-JP";
    else if (t.contains("중국어")) lang = "zh-CN";

    await _flutterTts.setLanguage(lang);
    await _flutterTts.setSpeechRate(_currentSpeed * 0.5);
    
    if(mounted) {
      setState(() {
        _isPlaying = true; _isTtsMode = true; _currentTtsIndex = 0;
        _duration = Duration(seconds: mainVerses.length); _position = Duration.zero;
      });
    }
    _speakVerse(0);
  }

  void _scrollToVerse(int index) {
    if (index >= mainVerses.length || index < 0) return;
    if (_lastScrolledIndex != index) {
      _lastScrolledIndex = index;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (index < _itemKeys.length) {
          final keyContext = _itemKeys[index].currentContext;
          if (keyContext != null) {
            Scrollable.ensureVisible(keyContext, duration: const Duration(milliseconds: 400), curve: Curves.easeOut, alignment: 0.0);
          }
        }
      });
    }
  }

  void _speakVerse(int index) async {
    if (!_isPlaying || index >= mainVerses.length) return;
    if(mounted) setState(() => _position = Duration(seconds: index));
    _scrollToVerse(index);
    String text = mainVerses[index]['Scripture'] ?? "";
    text = text.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ').trim();
    await _flutterTts.speak(text);
  }

  Future<void> _navigateToSelection() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const BibleSelectionScreen()));
    if (result != null) {
      if(mounted) setState(() { currentBook = result['book']; currentChapter = result['chapter']; });
      await _loadVerses();
      bool canPlay = currentTranslation != "kjv1611" && currentTranslation != "berean-interlinear";
      if (canPlay) _startPlay();
    }
  }

  void _showStrongPopup(String code) async {
    String fullCode = code;
    if (!code.startsWith('H') && !code.startsWith('G')) {
      fullCode = (currentBook <= 39) ? "H$code" : "G$code";
    }
    final data = await BibleService.getStrongDefinition(fullCode);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Strong's: $fullCode"),
        content: SizedBox(width: double.maxFinite, child: SingleChildScrollView(child: Html(data: data ?? "정보를 찾을 수 없습니다."))),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("확인"))],
      ),
    );
  }

  // [핵심 수정] 모든 성경 태그(KJV1611 FI/Fi/CM, NAS sup/i/br, Strong번호 등)를 처리하는 고성능 커스텀 파서
  InlineSpan _parseVerseContent(String text, double fontSize, bool isSpeaking) {
    if (isSpeaking) {
      return TextSpan(
        text: text.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ').trim(),
        style: TextStyle(fontSize: fontSize, height: 1.4, fontFamily: 'serif', color: Colors.black),
      );
    }

    final List<InlineSpan> children = [];
    // 정규식: 스트롱 번호, <sup>, <i>, <br>, <FI>, <Fi>, <CM>, 기타 모든 태그 감지
    final regExp = RegExp(r'<W([HG]?)(\d+)>|<sup>(.*?)</sup>|<i>(.*?)</i>|<br>|<FI>|<Fi>|<CM>|<.*?>', caseSensitive: false);
    int lastMatchEnd = 0;
    bool isItalic = false;

    for (final match in regExp.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        children.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: TextStyle(fontStyle: isItalic ? FontStyle.italic : FontStyle.normal),
        ));
      }

      String fullTag = match.group(0)!;
      String upperTag = fullTag.toUpperCase();

      if (upperTag.startsWith('<W')) {
        // 스트롱 번호 처리
        String prefix = match.group(1) ?? "";
        String number = match.group(2) ?? "";
        if (prefix.isEmpty) prefix = (currentBook <= 39 ? "H" : "G");
        String fullCode = "$prefix$number";
        children.add(TextSpan(
          text: "($fullCode)",
          style: TextStyle(fontSize: fontSize * 0.7, color: Colors.blue, decoration: TextDecoration.underline, fontStyle: FontStyle.normal),
          recognizer: TapGestureRecognizer()..onTap = () => _showStrongPopup(fullCode),
        ));
      } else if (upperTag.startsWith('<SUP')) {
        // 첨자(sup) 처리
        children.add(WidgetSpan(
          baseline: TextBaseline.alphabetic,
          alignment: PlaceholderAlignment.baseline,
          child: Transform.translate(
            offset: const Offset(0, -10),
            child: Text(match.group(3) ?? "", style: TextStyle(fontSize: fontSize * 0.6, fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
        ));
      } else if (upperTag.startsWith('<I')) {
        // 이탤릭(i) 처리
        children.add(TextSpan(text: match.group(4) ?? "", style: const TextStyle(fontStyle: FontStyle.italic)));
      } else if (upperTag == '<BR>') {
        children.add(const TextSpan(text: "\n"));
      } else if (upperTag == '<FI>') {
        isItalic = true;
      } else if (upperTag == '<FI>' || upperTag == '</FI>' || upperTag == '</I>' || upperTag == '<FI>') {
        isItalic = false;
      } else if (upperTag == '<CM>') {
        children.add(const TextSpan(text: "\n\n"));
      }
      
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      children.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: TextStyle(fontStyle: isItalic ? FontStyle.italic : FontStyle.normal),
      ));
    }

    return TextSpan(children: children, style: TextStyle(fontSize: fontSize, height: 1.4, fontFamily: 'serif', color: Colors.black));
  }

  @override
  Widget build(BuildContext context) {
    bool isInterlinear = currentTranslation == "berean-interlinear";
    bool hidePlayer = currentTranslation == "kjv1611" || currentTranslation == "berean-interlinear";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF001A33),
        toolbarHeight: 85,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(icon: const Icon(Icons.list), onPressed: _navigateToSelection),
        title: GestureDetector(
          onTap: _navigateToSelection,
          child: Column(
            children: [
              Text("${BibleData.bookNames[currentBook - 1]} $currentChapter장", style: const TextStyle(color: Colors.yellow, fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                DropdownButton<String>(
                  value: currentTranslation, dropdownColor: const Color(0xFF001A33), underline: Container(),
                  isDense: true, style: const TextStyle(color: Colors.white, fontSize: 12),
                  items: translations.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) async { 
                    if(mounted) { setState(() { currentTranslation = v!; _applyDefaultCompare(); }); }
                    await _loadVerses();
                    bool canPlayNow = currentTranslation != "kjv1611" && currentTranslation != "berean-interlinear";
                    stopAudio();
                    if(canPlayNow) {
                      Future.delayed(const Duration(milliseconds: 500), () { if(mounted) _startPlay(); });
                    }
                  },
                ),
                const Text(" | ", style: TextStyle(color: Colors.white24, fontSize: 12)),
                DropdownButton<String>(
                  value: compareTranslation, dropdownColor: const Color(0xFF001A33), underline: Container(),
                  isDense: true, style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
                  items: ["none", ...translations].map((t) => DropdownMenuItem(value: t, child: Text(t == "none" ? "대조없음" : t))).toList(),
                  onChanged: isInterlinear ? null : (v) { if(mounted) setState(() { compareTranslation = v!; _loadVerses(); }); },
                ),
              ]),
            ],
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () async {
            final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => BibleSearchScreen(translation: currentTranslation)));
            if (result != null) {
              if(mounted) { setState(() { currentBook = result['book']; currentChapter = result['chapter']; }); }
              await _loadVerses(); stopAudio();
            }
          }),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: WithForegroundTask(
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(16, 16, 16, hidePlayer ? 20 : 220),
                itemCount: mainVerses.length,
                itemBuilder: (context, index) {
                  final v = mainVerses[index];
                  bool isSpeaking = _isTtsMode && _isPlaying && _currentTtsIndex == index;
                  if (isInterlinear) return _buildInterlinearVerse(v['Scripture'] ?? "", v['verse']);
                  return Padding(
                    key: _itemKeys[index],
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: isSpeaking ? Colors.blue.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text.rich(TextSpan(children: [
                          TextSpan(text: "${v['verse']} ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 22, fontFamily: 'serif')),
                          _parseVerseContent(v['Scripture'] ?? "", 24, isSpeaking),
                        ])),
                        if (compareMap[v['verse']] != null) Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(compareMap[v['verse']]!, style: TextStyle(fontSize: 20, color: Colors.green[700], height: 1.4, fontFamily: 'serif')),
                        ),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomSheet: hidePlayer ? null : _buildPlayer(),
    );
  }

  Widget _buildPlayer() {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 5),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)], borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Slider(
            activeColor: Colors.blue,
            value: _position.inSeconds.toDouble().clamp(0.0, _duration.inSeconds > 0 ? _duration.inSeconds.toDouble() : 1.0),
            max: _duration.inSeconds > 0 ? _duration.inSeconds.toDouble() : 1.0,
            onChanged: (v) {
              if (_isTtsMode) {
                int idx = v.toInt();
                if(mounted) setState(() { _currentTtsIndex = idx; _position = Duration(seconds: idx); });
                _scrollToVerse(idx);
              } else { _audioPlayer.seek(Duration(seconds: v.toInt())); }
            },
            onChangeEnd: (v) { if (_isTtsMode && _isPlaying) _speakVerse(v.toInt()); },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0].map((s) =>
                  GestureDetector(
                    onTap: () { 
                      if(mounted) setState(() => _currentSpeed = s);
                      if (_isTtsMode) { _flutterTts.setSpeechRate(s * 0.5); }
                      else { _audioPlayer.setPlaybackRate(s); }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(color: _currentSpeed == s ? Colors.blue.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(15)),
                      child: Text("${s}x", style: TextStyle(fontSize: 14, fontWeight: _currentSpeed == s ? FontWeight.bold : FontWeight.normal, color: _currentSpeed == s ? Colors.blue : Colors.grey[700])),
                    ),
                  )).toList(),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 5, 15, 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(onTap: () => Navigator.maybePop(context), child: Image.asset('assets/img/button/home_btn.png', width: 45)),
              GestureDetector(onTap: () => _changeNo(-1), child: Image.asset('assets/img/button/l_arrow_btn.png', width: 50)),
              GestureDetector(onTap: () => _isPlaying ? stopAudio() : _startPlay(), child: Image.asset(_isPlaying ? 'assets/img/button/pause_btn.png' : 'assets/img/button/play_btn.png', width: 65)),
              GestureDetector(onTap: () => _changeNo(1), child: Image.asset('assets/img/button/r_arrow_btn.png', width: 50)),
              GestureDetector(onTap: () => setState(() => _repeatMode = (_repeatMode + 1) % 3), child: Image.asset('assets/img/button/repeat_btn.png', width: 40, color: _repeatMode == 0 ? Colors.grey : (_repeatMode == 1 ? Colors.orange : Colors.blue))),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildInterlinearVerse(String scripture, int verseNo) {
    List<Widget> words = [];
    bool isRtl = scripture.contains("<rtl/>") || currentBook <= 39;
    List<String> qParts = scripture.split(RegExp(r'<q>|<Q>'));
    for (var qPart in qParts) {
      if (qPart.trim().isEmpty) continue;
      String? original, strong, grammar, trans, english;
      original = RegExp(r'<[HG]>(.*?)<').firstMatch(qPart)?.group(1);
      strong = RegExp(r'<W[HG](.*?)>').firstMatch(qPart)?.group(1);
      grammar = RegExp(r'<WT(.*?)>').firstMatch(qPart)?.group(1);
      trans = RegExp(r'<X>(.*?)<').firstMatch(qPart)?.group(1);
      english = RegExp(r'<E>(.*?)<').firstMatch(qPart)?.group(1);
      if (original != null) {
        words.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(original, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            if (strong != null) InkWell(onTap: () => _showStrongPopup(strong!), child: Text("${currentBook <= 39 ? 'H' : 'G'}$strong", style: const TextStyle(fontSize: 14, color: Colors.blue, decoration: TextDecoration.underline))),
            if (grammar != null) Text(grammar, style: const TextStyle(fontSize: 12, color: Colors.green), textAlign: TextAlign.center),
            if (trans != null) Text(trans, style: const TextStyle(fontSize: 14, color: Colors.red), textAlign: TextAlign.center),
            if (english != null) Text(english, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.blueAccent), textAlign: TextAlign.center),
          ]),
        ));
      }
    }
    return Column(crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), child: Text("${BibleData.bookNames[currentBook-1].substring(0,1)}$currentBook:$verseNo", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
      Directionality(textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr, child: Wrap(alignment: isRtl ? WrapAlignment.start : WrapAlignment.start, children: words)),
      if (compareMap[verseNo] != null) Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(compareMap[verseNo]!, style: TextStyle(fontSize: 18, color: Colors.green[700], height: 1.4, fontFamily: 'serif')),
      ),
      const Divider(),
    ]);
  }
}

extension Let<T> on T? {
  void let(void Function(T) block) { if (this != null) block(this as T); }
}
