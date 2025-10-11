import 'package:flutter/material.dart';
import 'package:vodid_prototype2/screens/dev/dev_admin_seed_screen.dart';
import 'package:vodid_prototype2/screens/polls/today_polls_screen.dart';
import 'package:vodid_prototype2/screens/profile/profile_wrapper_screen.dart';
import 'package:vodid_prototype2/screens/search/search_screen.dart';
import 'package:vodid_prototype2/screens/summary/summary_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Anlaştığımız dosya yapısına uygun ekran listesi
  static const List<Widget> _screens = <Widget>[
    TodayPollsScreen(),
    SearchScreen(),
    SummaryScreen(),
    ProfileWrapperScreen(),
    // TODO: Testler bittikten sonra bu satırı ve aşağıdaki admin sekmesini sil.
    DevAdminSeedScreen(), 
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // TASARIM SIFIRLAMA: Orijinal arayüz widget ağacı geri getirildi
    return Scaffold(
      // PERFORMANS: IndexedStack ile sekmeler arası geçişte state korunur.
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      // Orijinal BottomNavigationBar Tasarımı
      bottomNavigationBar: BottomNavigationBar(
        onTap: _onItemTapped,
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed, // Animasyonu sabitler
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1a1a1a), // Orijinal seçili renk
        unselectedItemColor: Colors.grey.shade600, // Orijinal seçili olmayan renk
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedFontSize: 12.0, // Orijinal font boyutu
        unselectedFontSize: 12.0, // Orijinal font boyutu
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Anketler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            activeIcon: Icon(Icons.search_sharp), // Alternatif aktif ikon
            label: 'Arama',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Özetler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
          // Test için geçici admin sekmesi
          BottomNavigationBarItem(
            icon: Icon(Icons.construction_outlined),
            activeIcon: Icon(Icons.construction),
            label: 'Admin',
          ),
        ],
      ),
    );
  }
}