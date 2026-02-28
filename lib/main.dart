import 'package:flutter/material.dart';
import 'bible_selection_screen.dart';
import 'hymn_list_screen.dart';
import 'hokma_selection_screen.dart';
import 'youtube_screen.dart';
import 'bible_map_screen.dart';

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
      const BibleMapScreen(),
      YoutubeScreen(key: _youtubeKey),
    ];
  }

  // 반응형 아이콘 크기 (화면 너비에 따라 조절될 수 있도록 함)
  Widget _buildIcon(String assetName, bool isSelected, double screenWidth) {
    // 화면 너비가 좁을 경우 아이콘 크기를 약간 줄여 반응형으로 대응
    double iconSize = screenWidth < 360 ? 60 : 70;

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.purple.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: isSelected ? Border.all(color: Colors.purple.withOpacity(0.15), width: 1.5) : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/img/button/$assetName',
          width: iconSize,
          height: iconSize,
          fit: BoxFit.fill,
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == 4 && index != 4) {
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
      // 1. 노치 대응: SafeArea를 사용하여 상단 노치 영역에 침범하지 않게 함
      body: SafeArea(
        top: false, // AppBar가 이미 대응하므로 아래쪽/옆쪽 위주
        child: IndexedStack(index: _selectedIndex, children: _screens),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        // 아이폰 하단 홈 바 영역을 위한 패딩 자동 확보 (SafeArea 포함)
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          type: BottomNavigationBarType.fixed,
          onTap: _onItemTapped,
          selectedItemColor: Colors.purple,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 14,
          unselectedFontSize: 12,
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
              icon: _buildIcon('map.png', _selectedIndex == 3, screenWidth),
              label: '지도',
            ),
            BottomNavigationBarItem(
              icon: _buildIcon('youtube.png', _selectedIndex == 4, screenWidth),
              label: '유튜브',
            ),
          ],
        ),
      ),
    );
  }
}
