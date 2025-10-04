import 'package:flutter/material.dart';
import 'package:vodid_prototype2/core/constants/strings.dart';
import 'package:vodid_prototype2/core/widgets/empty_state.dart';

/// Özet ekranı.
/// Kullanıcının anketler, oylar ve yorumlarla ilgili özet bilgilerini gösterecek.
/// Şimdilik mock içerik ile çalışıyor.
class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Firestore veya servis entegrasyonu ile gerçek veriler gelecek
    final mockStats = {
      "totalPolls": 5,
      "totalVotes": 12,
      "totalComments": 3,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.summary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: mockStats.isEmpty
            ? const EmptyState(message: "Özet bilgisi bulunamadı")
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Toplam Anket: ${mockStats["totalPolls"]}",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Toplam Oy: ${mockStats["totalVotes"]}",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Toplam Yorum: ${mockStats["totalComments"]}",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text("Özet ekranı mock veriler ile çalışıyor"),
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text("Verileri Güncelle"),
                  )
                ],
              ),
      ),
    );
  }
}
