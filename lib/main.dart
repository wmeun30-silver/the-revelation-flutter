import 'package:flutter/material.dart';
import 'bible_selection_screen.dart';
import 'hymn_list_screen.dart';
import 'hokma_selection_screen.dart';
import 'youtube_screen.dart';
import 'bible_map_screen.dart';
import 'revelation_study_screen.dart';

void main() => runApp(const MaterialApp(
  debugShowCheckedModeBanner: false,
  home: MainHolder(),
));

class MainHolder extends StatefulWidget {
  const MainHolder({super.key});
  @override
  State<MainHolder> createState() => _MainHolderState();
}

class _MainHolderState extends State<MainHolder> {
  int _selectedIndex = 0;
  final GlobalKey<YoutubeScreenState> _youtubeKey = GlobalKey<YoutubeScreenState>();

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const BibleSelectionScreen(isMainTab: true),
      const HokmaSelectionScreen(),
      const HymnListScreen(),
      const RevelationStudyScreen(),
      const BibleMapScreen(),
      YoutubeScreen(key: _youtubeKey),
    ];
  }

  Widget _buildIcon(String assetName, bool isSelected, double screenWidth) {
    double iconSize = screenWidth < 400 ? 55 : 65;
    bool isYoutube = assetName == 'youtube.png';

    return Container(
      width: iconSize,
      height: iconSize,
      alignment: Alignment.center, // 수직/수평 중앙 정렬
      decoration: BoxDecoration(
        color: isSelected ? Colors.purple.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: Colors.purple.withOpacity(0.15), width: 1.5) : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          'assets/img/button/$assetName',
          // 유튜브 아이콘만 비율에 맞춰 높이를 줄이고 중앙 정렬
          width: isYoutube ? iconSize * 0.85 : iconSize,
          height: isYoutube ? iconSize * 0.6 : iconSize,
          fit: isYoutube ? BoxFit.contain : BoxFit.fill,
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == 5 && index != 5) {
      _youtubeKey.currentState?.pauseVideo();
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: IndexedStack(index: _selectedIndex, children: _screens),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          type: BottomNavigationBarType.fixed,
          onTap: _onItemTapped,
          selectedItemColor: Colors.purple,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 10,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: [
            BottomNavigationBarItem(
              icon: _buildIcon('bible.png', _selectedIndex == 0, screenWidth),
              label: '성경',
            ),
            BottomNavigationBarItem(
              icon: _buildIcon('hokma.png', _selectedIndex == 1, screenWidth),
              label: '주석',
            ),
            BottomNavigationBarItem(
              icon: _buildIcon('hymn.png', _selectedIndex == 2, screenWidth),
              label: '찬송가',
            ),
            BottomNavigationBarItem(
              icon: _buildIcon('rev.png', _selectedIndex == 3, screenWidth),
              label: '계시록강해',
            ),
            BottomNavigationBarItem(
              icon: _buildIcon('map.png', _selectedIndex == 4, screenWidth),
              label: '지도',
            ),
            BottomNavigationBarItem(
              icon: _buildIcon('youtube.png', _selectedIndex == 5, screenWidth),
              label: '유튜브',
            ),
          ],
        ),
      ),
    );
  }
}
