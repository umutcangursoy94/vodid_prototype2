import 'package:flutter/material.dart';
import 'package:vodid_prototype2/core/widgets/empty_state.dart';
import 'package:vodid_prototype2/core/widgets/loading.dart';

/// Genel amaçlı liste ekranı.
/// Firestore veya başka kaynaklardan alınan verileri listelemek için kullanılabilir.
/// title: AppBar başlığı
/// itemBuilder: her öğe için widget oluşturucu
/// items: liste elemanları
/// isLoading: yüklenme durumu
class GenericListScreen<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final bool isLoading;
  final Widget Function(BuildContext, T) itemBuilder;
  final VoidCallback? onRetry;

  const GenericListScreen({
    super.key,
    required this.title,
    required this.items,
    required this.itemBuilder,
    this.isLoading = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: isLoading
          ? const Loading()
          : items.isEmpty
              ? EmptyState(
                  message: "Gösterilecek öğe yok",
                  onRetry: onRetry,
                )
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) =>
                      itemBuilder(context, items[index]),
                ),
    );
  }
}
