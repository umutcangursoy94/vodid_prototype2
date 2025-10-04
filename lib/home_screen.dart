import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:vodid_prototype2/my_votes_screen.dart';
import 'package:vodid_prototype2/search_screen.dart';
import 'package:vodid_prototype2/summary_screen.dart';
import 'package:vodid_prototype2/today_polls_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const TodayPollsScreen(),
    const SearchScreen(),
    // HATA DÜZELTMESİ: SummaryScreen'in artık anket listesini parametre
    // olarak alması gerekiyor. Bu yüzden bir StreamBuilder ile veriyi
    // Firestore'dan çekip SummaryScreen'e iletiyoruz.
    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('polls')
          .orderBy('order')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        // 'polls' parametresi burada veriliyor.
        return SummaryScreen(polls: docs);
      },
    ),
    const MyVotesScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: _CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

class _CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const _CustomBottomNavBar({
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.poll_outlined, 0),
              _buildNavItem(Icons.search, 1),
              _buildNavItem(Icons.bar_chart_outlined, 2),
              _buildNavItem(Icons.person_outline, 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = selectedIndex == index;
    return IconButton(
      onPressed: () => onItemTapped(index),
      icon: Icon(
        icon,
        color: isSelected ? Colors.black : Colors.grey[500],
        size: 30,
      ),
    );
  }
}
