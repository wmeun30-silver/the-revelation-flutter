import 'package:flutter/material.dart';

class BibleMapScreen extends StatelessWidget {
  const BibleMapScreen({super.key});

  final List<String> mapTitles = const [
    "고대 근동",
    "아브라함의 이주",
    "아브라함의 가나안 이주",
    "이스라엘 지파의 토지 분배",
    "솔로몬의 경제 사업",
    "엘리야와 엘리사",
    "디글랏빌레셋3세 치하의 앗시리아 ..",
    "알렉산더 대왕의 제국",
    "헤롯 왕국의 분열",
    "예루살렘의 고난 주간",
    "오순절과 유대인 디아스포라",
    "바울의 첫 번째 선교 여행",
    "바울의 두 번째 선교 여행",
    "바울의 세 번째 선교 여행",
    "요한계시록(계 2-3장)",
  ];

  final List<String> mapFileNames = const [
    "1. THE ANCIENT NEAR EAST.png",
    "2. THE MIGRATION OF ABRAHAM.png",
    "3. ABRAHAM IN CANAAN.png",
    "4. THE TRIBAL ALLOTMENTS OF ISRAEL.png",
    "5. SOLOMON'S ECONOMIC ENTERPRISES.png",
    "6. ELIJAH AND ELISHA.png",
    "7. THE ASSYRIAN EMPIRE UNDER TIGLATH-PILESER III.png",
    "8. ALEXANDER THE GREAT'S EMPIRE.png",
    "9. THE DIVISION OF HEROD'S KINGDOM.png",
    "10.THE PASSION WEEK IN JERUSALEM.png",
    "11. PENTECOST AND THE JEWISH DIASPORA.png",
    "12.THE FIRST MISSIONARY JOURNEY OF PAUL.png",
    "13.THE SECOND MISSIONARY JOURNEY OF PAUL.png",
    "14.THE THIRD MISSIONARY JOURNEY OF PAUL.png",
    "15.CHURCHES OF THE REVELATION(REV.2-3).png",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("성경 지도", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF001A33),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.65,
        ),
        itemCount: mapFileNames.length,
        itemBuilder: (context, index) {
          String imagePath = 'assets/img/bible_map/${mapFileNames[index]}';
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullScreenImage(
                    imagePath: imagePath,
                    title: mapTitles[index],
                  ),
                ),
              );
            },
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[300],
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "${index + 1}. ${mapTitles[index]}",
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final String imagePath;
  final String title;

  const FullScreenImage({super.key, required this.imagePath, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 5.0,
          child: Image.asset(
            imagePath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Text(
              "이미지를 불러올 수 없습니다.",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
