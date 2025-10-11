import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SummaryScreen extends StatefulWidget {
  final String? initialPollId;

  const SummaryScreen({
    super.key,
    this.initialPollId,
  });

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  DateTime? _selectedDate;
  Future<List<QueryDocumentSnapshot>>? _pollsFuture;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  // Ekranı başlatan performanslı fonksiyonu koruyoruz
  Future<void> _initializeScreen() async {
    DateTime initialDate;
    if (widget.initialPollId != null) {
      try {
        final pollDoc = await FirebaseFirestore.instance
            .collection('polls')
            .doc(widget.initialPollId)
            .get();
        if (pollDoc.exists && pollDoc.data()!.containsKey('date')) {
          initialDate = DateTime.parse(pollDoc['date']);
        } else {
          initialDate = DateTime.now().subtract(const Duration(days: 1));
        }
      } catch (e) {
        initialDate = DateTime.now().subtract(const Duration(days: 1));
      }
    } else {
      initialDate = DateTime.now().subtract(const Duration(days: 1));
    }

    if (mounted) {
      setState(() {
        _selectedDate = initialDate;
        _pollsFuture = _fetchPollsForDate(_selectedDate!);
      });
    }
  }

  Future<List<QueryDocumentSnapshot>> _fetchPollsForDate(DateTime date) async {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    final snapshot = await FirebaseFirestore.instance
        .collection('polls')
        .where('date', isEqualTo: dateString)
        .get();
    return snapshot.docs;
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate!.add(Duration(days: days));
      _pollsFuture = _fetchPollsForDate(_selectedDate!);
    });
  }

  @override
  Widget build(BuildContext context) {
    // TASARIM SIFIRLAMA: Orijinal arayüz widget ağacı geri getirildi
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: const Text(
          'Anket Özetleri',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Orijinal tarih navigasyon çubuğu
          if (_selectedDate != null) _buildDateNavigator(),
          const Divider(height: 1),
          Expanded(
            child: _pollsFuture == null
                ? const Center(child: CircularProgressIndicator(color: Colors.black))
                : FutureBuilder<List<QueryDocumentSnapshot>>(
                    future: _pollsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.black));
                      }
                      if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('Bu tarihe ait anket bulunamadı.', style: TextStyle(color: Colors.grey)));
                      }
                      final polls = snapshot.data!;
                      // PERFORMANS: ListView.builder ve orijinal tasarım
                      return ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: polls.length,
                        itemBuilder: (context, index) {
                          final pollData = polls[index].data() as Map<String, dynamic>;
                          return _buildPollResultCard(pollData);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Orijinal Tarih Navigasyon Tasarımı
  Widget _buildDateNavigator() {
    final now = DateTime.now();
    final isTodayOrFuture = DateUtils.isSameDay(_selectedDate, now) || _selectedDate!.isAfter(now);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => _changeDate(-1),
          ),
          Text(
            DateFormat('d MMMM yyyy', 'tr_TR').format(_selectedDate!),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 20),
            onPressed: isTodayOrFuture ? null : () => _changeDate(1), // Geleceğe gitmeyi engelle
          ),
        ],
      ),
    );
  }

  // Orijinal Anket Sonuç Kartı Tasarımı
  Widget _buildPollResultCard(Map<String, dynamic> pollData) {
    final String question = pollData['question'] ?? 'Soru bulunamadı';
    final int votes1 = pollData['option1_votes'] ?? 0;
    final int votes2 = pollData['option2_votes'] ?? 0;
    final totalVotes = votes1 + votes2;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildResultBar(pollData['option1'], votes1, totalVotes),
          const SizedBox(height: 8),
          _buildResultBar(pollData['option2'], votes2, totalVotes),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text('Toplam $totalVotes oy', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ),
        ],
      ),
    );
  }
  
  // Orijinal Sonuç Barı Tasarımı
  Widget _buildResultBar(String option, int votes, int totalVotes) {
    double percentage = totalVotes == 0 ? 0 : votes / totalVotes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(option, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('${(percentage * 100).toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}