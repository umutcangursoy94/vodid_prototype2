import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:vodid_prototype2/helpers/page_controller_with_listener.dart';
import 'package:vodid_prototype2/widgets/poll_card.dart';

class TodayPollsScreen extends StatefulWidget {
  const TodayPollsScreen({super.key});

  @override
  State<TodayPollsScreen> createState() => _TodayPollsScreenState();
}

class _TodayPollsScreenState extends State<TodayPollsScreen> {
  late final Future<List<QueryDocumentSnapshot>> _pollsFuture;
  late final PageControllerWithListener _pageController;
  VideoPlayerController? _videoController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pollsFuture = _fetchTodayPolls();
    _pageController = PageControllerWithListener(listener: _onPageChanged);
  }

  // Verimli video yönetimi fonksiyonu
  Future<void> _initializeVideoPlayer(String? videoUrl) async {
    await _videoController?.dispose();
    _videoController = null;
    if (videoUrl == null || videoUrl.isEmpty) {
      if(mounted) setState(() {});
      return;
    };

    final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    _videoController = controller;
    await controller.initialize();
    if (_videoController == controller) { // Eğer hala bu controller aktifse
      await controller.setLooping(true);
      await controller.play();
      if(mounted) setState(() {});
    }
  }

  // Sayfa değiştiğinde videoyu güncelleyen fonksiyon
  void _onPageChanged() {
    final newPage = _pageController.page?.round() ?? 0;
    if (newPage != _currentPage) {
      _currentPage = newPage;
      _pollsFuture.then((polls) {
        if (polls.isNotEmpty && _currentPage < polls.length) {
          final pollData = polls[_currentPage].data() as Map<String, dynamic>;
          _initializeVideoPlayer(pollData['videoUrl']);
        }
      });
    }
  }

  // Bugünün anketlerini getiren fonksiyon
  Future<List<QueryDocumentSnapshot>> _fetchTodayPolls() async {
    final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final snapshot = await FirebaseFirestore.instance
        .collection('polls')
        .where('date', isEqualTo: todayString)
        .limit(10)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final firstPollData = snapshot.docs.first.data() as Map<String, dynamic>;
      await _initializeVideoPlayer(firstPollData['videoUrl']);
    }

    return snapshot.docs;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Geçişlerde siyah arka plan
      body: FutureBuilder<List<QueryDocumentSnapshot>>(
        future: _pollsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Bugün için anket bulunamadı.', style: TextStyle(color: Colors.white)));
          }

          final polls = snapshot.data!;

          // PERFORMANSLI PageView.builder, yeni PollCard'ı kullanıyor
          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: polls.length,
            itemBuilder: (context, index) {
              return PollCard(
                pollDoc: polls[index],
                videoController: _currentPage == index ? _videoController : null,
              );
            },
          );
        },
      ),
    );
  }
}