import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DevAdminSeedScreen extends StatefulWidget {
  const DevAdminSeedScreen({super.key});

  @override
  State<DevAdminSeedScreen> createState() => _DevAdminSeedScreenState();
}

class _DevAdminSeedScreenState extends State<DevAdminSeedScreen> {
  bool _busy = false;
  String _log = 'Hazır. Butona basarak anket verilerini güncelleyebilirsiniz.';
  final _db = FirebaseFirestore.instance;

  Future<void> _createAgendaPolls() async {
    setState(() {
      _busy = true;
      _log = '10 anketin arama indeksi güncelleniyor...';
    });

    try {
      final pollsCollection = _db.collection('polls');
      final List<Map<String, dynamic>> agendaPolls = _getPollsList();
      final writeBatch = _db.batch();

      for (int i = 0; i < agendaPolls.length; i++) {
        final pollData = agendaPolls[i];
        final docId = _slugify(pollData['question']);
        final pollRef = pollsCollection.doc(docId);

        final question = pollData['question'] as String;
        final words = question
            .toLowerCase()
            .split(' ')
            .where((s) => s.isNotEmpty)
            .toSet();

        final searchIndex = <String>{};
        for (final word in words) {
          for (int j = 3; j <= word.length; j++) {
            searchIndex.add(word.substring(0, j));
          }
          searchIndex.add(word);
        }

        writeBatch.set(
            pollRef,
            {
              'question': pollData['question'],
              'question_lowercase':
                  (pollData['question'] as String).toLowerCase(),
              'question_keywords': words.toList(),
              'question_search_index': searchIndex.toList(),
              'options': pollData['options'],
              'news_summary': pollData['news_summary'],
              'order': i + 1,
              'isActive': true,
            },
            SetOptions(merge: true));
      }

      await writeBatch.commit();

      setState(() {
        _log =
            '✅ BAŞARILI: 10 adet gündem anketi başarıyla güncellendi! Video URL\'leri korundu.';
      });
    } catch (e) {
      setState(
          () => _log = '❌ HATA: Güncelleme sırasında bir sorun oluştu: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// GÜNCELLENDİ: Tüm oyları, yorumları, beğenileri, aktiviteleri ve sayaçları sıfırlar.
  Future<void> _resetAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tüm Verileri Sıfırla'),
        content: const Text(
            'Bu işlem geri alınamaz. Tüm kullanıcıların oyları, yorumları, beğenileri, aktiviteleri ve tüm sayaçlar sıfırlanacak. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Evet, Hepsini Sıfırla'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _busy = true;
      _log = 'Tüm veriler sıfırlanıyor, lütfen bekleyin...';
    });

    try {
      // Toplu yazma işlemini başlat
      WriteBatch batch = _db.batch();
      int writeCount = 0;

      // Toplu işlemleri yönetmek için yardımcı fonksiyon
      Future<void> commitBatchIfNeeded() async {
        if (writeCount >= 400) {
          await batch.commit();
          batch = _db.batch();
          writeCount = 0;
        }
      }

      // 1. Tüm anketlerin alt koleksiyonlarını sil ve sayaçları sıfırla
      final pollsSnap = await _db.collection('polls').get();
      for (final pollDoc in pollsSnap.docs) {
        // Yorumlar ve yanıtları sil
        final commentsSnap =
            await pollDoc.reference.collection('comments').get();
        for (final commentDoc in commentsSnap.docs) {
          final repliesSnap =
              await commentDoc.reference.collection('replies').get();
          for (final replyDoc in repliesSnap.docs) {
            batch.delete(replyDoc.reference);
            writeCount++;
            await commitBatchIfNeeded();
          }
          batch.delete(commentDoc.reference);
          writeCount++;
          await commitBatchIfNeeded();
        }

        // Oyları sil
        final votesSnap = await pollDoc.reference.collection('votes').get();
        for (final voteDoc in votesSnap.docs) {
          batch.delete(voteDoc.reference);
          writeCount++;
          await commitBatchIfNeeded();
        }

        // Ana sayaçları sıfırla
        final options = List<String>.from(pollDoc.data()['options'] ?? []);
        final zeroCounts = {for (var opt in options) opt: 0};
        batch.update(pollDoc.reference, {
          'commentsCount': 0,
          'counts': zeroCounts,
          'totalVotes': 0,
          'savedByCount': 0,
          'shareCounts': {},
        });
        writeCount++;
        await commitBatchIfNeeded();
      }

      // 2. Tüm kullanıcıların alt koleksiyonlarını sil ve sayaçları sıfırla
      final usersSnap = await _db.collection('users').get();
      for (final userDoc in usersSnap.docs) {
        // 'votes' alt koleksiyonunu sil
        final userVotesSnap = await userDoc.reference.collection('votes').get();
        for (final voteDoc in userVotesSnap.docs) {
          batch.delete(voteDoc.reference);
          writeCount++;
          await commitBatchIfNeeded();
        }

        // 'activities' alt koleksiyonunu sil
        final userActivitiesSnap =
            await userDoc.reference.collection('activities').get();
        for (final activityDoc in userActivitiesSnap.docs) {
          batch.delete(activityDoc.reference);
          writeCount++;
          await commitBatchIfNeeded();
        }

        // 'savedPolls' alt koleksiyonunu sil
        final userSavedPollsSnap =
            await userDoc.reference.collection('savedPolls').get();
        for (final savedDoc in userSavedPollsSnap.docs) {
          batch.delete(savedDoc.reference);
          writeCount++;
          await commitBatchIfNeeded();
        }

        // Kullanıcı sayaçlarını sıfırla
        batch.update(userDoc.reference, {
          'commentsCount': 0,
          'votesCount': 0,
          'followersCount': 0,
          'followingCount': 0,
        });
        writeCount++;
        await commitBatchIfNeeded();
      }

      // Kalan işlemleri commit et
      if (writeCount > 0) {
        await batch.commit();
      }

      setState(() {
        _log =
            '✅ BAŞARILI: Tüm oylar, yorumlar, aktiviteler ve sayaçlar sıfırlandı!';
      });
    } catch (e) {
      setState(
          () => _log = '❌ HATA: Veriler sıfırlanırken bir sorun oluştu: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _slugify(String text) {
    String slug = text.toLowerCase();
    slug = slug
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
    slug = slug.replaceAll(RegExp(r'[^\w\s-]+'), '').replaceAll(' ', '-');
    slug = slug.replaceAll(RegExp(r'--+'), '-');
    slug = slug.replaceAll(RegExp(r'^-|-$'), '');
    return slug;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dev Admin Paneli ⚙️')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_busy)
                const LinearProgressIndicator()
              else
                Container(height: 4),
              const SizedBox(height: 8),
              Text(
                _log,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Divider(height: 32),
              OutlinedButton.icon(
                onPressed: _busy ? null : _createAgendaPolls,
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12)),
                icon: const Icon(Icons.add_to_photos_outlined),
                label: const Text('Anket Verilerini Güncelle',
                    style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _busy ? null : _resetAllData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.delete_forever_outlined),
                label: const Text('Tüm Verileri Sıfırla',
                    style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Anket verilerini ve "Ne Olmuştu?" hikayelerini içeren liste
  List<Map<String, dynamic>> _getPollsList() {
    return [
      {
        'question': 'Sence Fatih Altaylı\'nın tutukluluk kararı doğru muydu?',
        'options': ['Evet, doğruydu', 'Hayır, yanlıştı'],
        'news_summary':
            'Kalemlerin sustuğu bir gece... Tanınmış gazeteci Fatih Altaylı, bir köşe yazısındaki ifadeleri nedeniyle "suçu ve suçluyu övme" iddiasıyla başlatılan soruşturma sonrası kendini parmaklıklar ardında buldu. Kamuoyu, bu kararın basın özgürlüğüne vurulmuş bir darbe olup olmadığını tartışırken, adliye koridorları "ifade hürriyeti" kavramının sınırlarını yeniden çiziyordu.'
      },
      {
        'question': 'Ayşe Ateş davasının gidişatından memnun musun?',
        'options': ['Evet, memnunum', 'Hayır, değilim'],
        'news_summary':
            'Adalet arayışı bir sembole dönüştü. Eşi Sinan Ateş\'in öldürülmesinin ardından Ayşe Ateş, hukuk mücadelesinin en ön saflarında yer aldı. Davanın siyasi yankıları devam ederken, Ayşe Ateş\'in kararlı duruşu ve "perde arkası aydınlatılsın" haykırışı, Türkiye\'nin adalet sistemine olan güvenini sorgulatan bir süreci başlattı.'
      },
      {
        'question': 'Türkiye\'de sence de bir ekonomik kriz var mı?',
        'options': ['Evet, var', 'Hayır, yok'],
        'news_summary':
            'Market sepetleri hafiflerken, cüzdanlardaki yangın büyüyor. Artan enflasyon ve düşen alım gücü, milyonlarca ailenin bütçesini alt üst etti. Kimi uzmanlar bunun geçici bir dalgalanma olduğunu söylerken, sokaktaki vatandaş için durum çok daha netti: "Geçinemiyoruz!" Tartışmalar, rakamların ötesinde, insan hikayeleri üzerinden devam ediyor.'
      },
      {
        'question': 'Yeni vergi reformu sence adil mi?',
        'options': ['Adil', 'Değil'],
        'news_summary':
            'Hükümet, ekonomiyi düzeltme amacıyla yeni bir vergi paketi hazırladı. "Az kazanandan az, çok kazanandan çok" sloganıyla yola çıkılsa da, paketin detayları ortaya çıktıkça özellikle orta direğin ve küçük esnafın yükünün artacağı endişeleri yükseldi. Bu reform, gerçekten de vergi adaletini sağlayacak mı, yoksa makas daha da mı açılacak?'
      },
      {
        'question': 'Sokak hayvanları için en doğru çözüm sence hangisi?',
        'options': ['Uyutulmalı', 'Kısırlaştırılmalı'],
        'news_summary':
            'Masum bakışlar ve artan endişeler... Şehirlerdeki sahipsiz hayvan popülasyonu, toplumu ikiye bölen bir soruna dönüştü. Bir yanda güvenlik endişesiyle radikal çözümler isteyenler, diğer yanda "yaşam hakkı kutsaldır" diyerek kısırlaştırma ve rehabilitasyonu savunanlar. Bu hassas denge, vicdanları ve yasaları karşı karşıya getiriyor.'
      },
      {
        'question': 'Sinan Ateş suikastının aydınlatılacağına inanıyor musun?',
        'options': ['İnanıyorum', 'İnanmıyorum'],
        'news_summary':
            'Ankara\'nın kalbinde sıkılan bir kurşun, siyasetin dehlizlerinde yankılanmaya devam ediyor. Eski Ülkü Ocakları Başkanı Sinan Ateş\'in katledilmesi, basit bir cinayetin çok ötesinde, karmaşık ilişkiler ağını ve derin bağlantıları ortaya serdi. Kamuoyu, adaletin bu karanlık tünelin sonundaki ışığı yakıp yakamayacağını merakla bekliyor.'
      },
      {
        'question':
            'Yapay zeka gelecekte insanlık için bir tehdit oluşturur mu?',
        'options': ['Evet, oluşturur', 'Hayır, oluşturmaz'],
        'news_summary':
            'Düşünen makineler aramızda. Sanat üreten, metin yazan, hatta insanlarla sohbet eden yapay zeka, bir zamanlar bilim kurgu olan bir geleceği bugüne taşıdı. Bu teknolojik devrim, insanlığın en büyük yardımcısı mı olacak, yoksa kontrolümüzden çıkıp varoluşsal bir tehdide mi dönüşecek? Geri sayım çoktan başladı.'
      },
      {
        'question':
            'Sence Türkiye 2030 yılına kadar Avrupa Birliği\'ne girebilir mi?',
        'options': ['Evet, girebilir', 'Hayır, giremez'],
        'news_summary':
            'Yarım asrı deviren bir rüya... Türkiye\'nin Avrupa Birliği\'ne tam üyelik hedefi, siyasi gelgitler ve değişen küresel dinamikler arasında bir ileri bir geri gidiyor. Bir nesil bu hedefle büyüdü, ancak yeni nesiller için bu ihtimal giderek daha uzak görünüyor. Peki, bu hedef hala gerçekçi mi, yoksa geçmişte kalmış bir ideal mi?'
      },
      {
        'question': 'Asgari ücrete yılda tek zam yapılması yeterli mi?',
        'options': ['Evet, yeterli', 'Hayır, yetersiz'],
        'news_summary':
            'Enflasyon canavarı maaşları eritirken, gözler asgari ücret pazarlıklarına çevrildi. Hükümetin "yılda tek zam" politikası, alım gücünü korumaya yetecek mi? Milyonlarca çalışan, ay sonunu getirme mücadelesi verirken, bu kararın sofralarına nasıl yansıyacağını endişeyle bekliyor.'
      },
      {
        'question':
            'Sence sosyal medya fenomenlerine yönelik denetimler artırılmalı mı?',
        'options': ['Evet, artırılmalı', 'Hayır, gerek yok'],
        'news_summary':
            'Lüks hayatlar, şaibeli kazançlar... Bir zamanlar sadece eğlence kaynağı olan sosyal medya, vergi kaçırma ve kara para aklama iddialarıyla sarsıldı. Gözaltına alınan fenomenler, bu dijital dünyanın aslında ne kadar denetimsiz olduğunu gözler önüne serdi. Şimdi soruluyor: Bu ışıltılı hayatların bedelini kim ödüyor?'
      },
    ];
  }
}
