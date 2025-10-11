import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DevAdminSeedScreen extends StatefulWidget {
  const DevAdminSeedScreen({super.key});

  @override
  State<DevAdminSeedScreen> createState() => _DevAdminSeedScreenState();
}

class _DevAdminSeedScreenState extends State<DevAdminSeedScreen> {
  bool _isBusy = false;
  String _log = 'Hazır.';
  final _db = FirebaseFirestore.instance;

  // YENİ FONKSİYON: Tüm anketlerin tarihini bugüne günceller
  Future<void> _updateAllPollsToToday() async {
    setState(() {
      _isBusy = true;
      _log = 'Mevcut anketler taranıyor ve tarihler güncelleniyor...';
    });

    try {
      // PERFORMANS: WriteBatch kullanarak tek seferde güncelleme
      final batch = _db.batch();
      final pollsSnapshot = await _db.collection('polls').get();
      
      if (pollsSnapshot.docs.isEmpty) {
        setState(() {
          _log = '⚠️ Bulunacak anket yok. Önce anket eklemelisiniz.';
          _isBusy = false;
        });
        return;
      }

      final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());

      for (final pollDoc in pollsSnapshot.docs) {
        final pollRef = _db.collection('polls').doc(pollDoc.id);
        batch.update(pollRef, {'date': todayString});
      }

      await batch.commit();

      setState(() {
        _log = '✅ BAŞARILI: ${pollsSnapshot.docs.length} adet anketin tarihi bugüne güncellendi!';
      });
    } catch (e) {
      setState(() => _log = '❌ HATA: Güncelleme sırasında bir sorun oluştu: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }


  // Bu fonksiyon, yeni anket eklemek için hala kullanılabilir.
  Future<void> _seedNewPolls() async {
    // ... (Bu fonksiyonun içeriği aynı kalıyor)
    setState(() {
      _isBusy = true;
      _log = '10 yeni test anketi veritabanına ekleniyor...';
    });
    try {
      final batch = FirebaseFirestore.instance.batch();
      final pollsCollection = FirebaseFirestore.instance.collection('polls');
      final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final List<Map<String, dynamic>> agendaPolls = _getPollsList();

      for (int i = 0; i < agendaPolls.length; i++) {
        final newPollRef = pollsCollection.doc(); // Otomatik ID
        batch.set(newPollRef, {
          'question': agendaPolls[i]['question'],
          'option1': agendaPolls[i]['options'][0],
          'option2': agendaPolls[i]['options'][1],
          'option1_votes': 0,
          'option2_votes': 0,
          'date': todayString,
          'videoUrl': 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      setState(() => _log = '✅ BAŞARILI: 10 yeni anket eklendi.');
    } catch (e) {
      setState(() => _log = '❌ HATA: Anketler eklenirken bir sorun oluştu: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geliştirici Paneli'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isBusy) const LinearProgressIndicator(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _log,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            const Divider(height: 40),
            // YENİ BUTON: Tarihleri güncellemek için
            ElevatedButton.icon(
              onPressed: _isBusy ? null : _updateAllPollsToToday,
              icon: const Icon(Icons.calendar_today),
              label: const Text('Tüm Anket Tarihlerini Güncelle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _isBusy ? null : _seedNewPolls,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('10 Yeni Test Anketi Ekle'),
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12)),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getPollsList() {
    // Bu liste, "10 Yeni Test Anketi Ekle" butonu için kullanılır.
    return [
      {'question': 'Sence Fatih Altaylı\'nın tutukluluk kararı doğru muydu?', 'options': ['Evet, doğruydu', 'Hayır, yanlıştı']},
      {'question': 'Ayşe Ateş davasının gidişatından memnun musun?', 'options': ['Evet, memnunum', 'Hayır, değilim']},
      {'question': 'Türkiye\'de sence de bir ekonomik kriz var mı?', 'options': ['Evet, var', 'Hayır, yok']},
      {'question': 'Yeni vergi reformu sence adil mi?', 'options': ['Adil', 'Değil']},
      {'question': 'Sokak hayvanları için en doğru çözüm sence hangisi?', 'options': ['Uyutulmalı', 'Kısırlaştırılmalı']},
      {'question': 'Sinan Ateş suikastının aydınlatılacağına inanıyor musun?', 'options': ['İnanıyorum', 'İnanmıyorum']},
      {'question': 'Yapay zeka gelecekte insanlık için bir tehdit oluşturur mu?', 'options': ['Evet, oluşturur', 'Hayır, oluşturmaz']},
      {'question': 'Sence Türkiye 2030 yılına kadar Avrupa Birliği\'ne girebilir mi?', 'options': ['Evet, girebilir', 'Hayır, giremez']},
      {'question': 'Asgari ücrete yılda tek zam yapılması yeterli mi?', 'options': ['Evet, yeterli', 'Hayır, yetersiz']},
      {'question': 'Sence sosyal medya fenomenlerine yönelik denetimler artırılmalı mı?', 'options': ['Evet, artırılmalı', 'Hayır, gerek yok']},
    ];
  }
}