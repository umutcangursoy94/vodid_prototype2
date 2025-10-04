import 'package:flutter/material.dart';
import 'package:vodid_prototype2/core/constants/strings.dart';
import 'package:vodid_prototype2/core/widgets/empty_state.dart';

/// Kullanıcının verdiği oyları listeleyen ekran.
/// Şimdilik mock veriler ile çalışıyor, ileride Firestore ile bağlanacak.
class MyVotesScreen extends StatelessWidget {
  const MyVotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Firestore üzerinden kullanıcının oyları çekilecek
    final mockVotes = [
      {"question": "Yapay zekâ işleri yok edecek mi?", "answer": "Evet"},
      {"question": "Uzay turizmi mümkün olacak mı?", "answer": "Hayır"},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.votes),
      ),
      body: mockVotes.isEmpty
          ? const EmptyState(message: "Henüz oy kullanmadınız")
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: mockVotes.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final vote = mockVotes[index];
                return ListTile(
                  leading: const Icon(Icons.how_to_vote),
                  title: Text(vote["question"]!),
                  subtitle: Text("Senin cevabın: ${vote["answer"]}"),
                );
              },
            ),
    );
  }
}
