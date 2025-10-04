import 'package:flutter/material.dart';
import 'package:vodid_prototype2/core/constants/strings.dart';
import 'package:vodid_prototype2/core/widgets/empty_state.dart';

/// Arama ekranı.
/// Şimdilik mock arama özelliği var, ileride Firestore query ile bağlanabilir.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _query = "";

  void _onSearch() {
    setState(() {
      _query = _controller.text.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _query.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.search),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Aramak için yaz...",
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    ),
                    onSubmitted: (_) => _onSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _onSearch,
                  child: const Icon(Icons.search),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: hasQuery
                  ? _buildResults()
                  : const EmptyState(message: "Aramak için bir şey yazın"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    // Şimdilik dummy sonuçlar
    final results = ["Anket 1", "Anket 2", "Anket 3"]
        .where((item) => item.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    if (results.isEmpty) {
      return const EmptyState(message: "Sonuç bulunamadı");
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return ListTile(
          leading: const Icon(Icons.poll_outlined),
          title: Text(item),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Seçildi: $item")),
            );
          },
        );
      },
    );
  }
}
