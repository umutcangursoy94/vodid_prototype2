import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GenericListScreen extends StatelessWidget {
  final String title;
  final Stream<QuerySnapshot> stream;
  final Widget Function(BuildContext context, DocumentSnapshot doc) itemBuilder;
  final String emptyMessage;

  const GenericListScreen({
    super.key,
    required this.title,
    required this.stream,
    required this.itemBuilder,
    this.emptyMessage = 'Burada gösterilecek bir şey yok.',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  emptyMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return itemBuilder(context, docs[index]);
            },
          );
        },
      ),
    );
  }
}
