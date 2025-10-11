import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// DOĞRU DOSYA YOLU KULLANILDI:
import 'package:vodid_prototype2/screens/summary/summary_screen.dart'; 

class MyVotesScreen extends StatefulWidget {
  const MyVotesScreen({super.key});

  @override
  State<MyVotesScreen> createState() => _MyVotesScreenState();
}

class _MyVotesScreenState extends State<MyVotesScreen> {
  late final Future<List<QueryDocumentSnapshot>> _myVotesFuture;

  @override
  void initState() {
    super.initState();
    _myVotesFuture = _fetchMyVotes();
  }

  Future<List<QueryDocumentSnapshot>> _fetchMyVotes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final votesSnapshot = await FirebaseFirestore.instance
        .collectionGroup('votes')
        .where('userId', isEqualTo: user.uid)
        .get();

    if (votesSnapshot.docs.isEmpty) return [];

    final Set<String> pollIds = {};
    final List<Future<DocumentSnapshot>> pollFutures = [];

    for (var voteDoc in votesSnapshot.docs) {
      final pollRef = voteDoc.reference.parent.parent;
      if (pollRef != null && !pollIds.contains(pollRef.id)) {
        pollIds.add(pollRef.id);
        pollFutures.add(pollRef.get());
      }
    }
    final pollSnapshots = await Future.wait(pollFutures);
    return pollSnapshots.cast<QueryDocumentSnapshot>().toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Verdiğim Oylar',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<List<QueryDocumentSnapshot>>(
        future: _myVotesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Oylar yüklenirken bir hata oluştu.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Henüz hiç oy kullanmamışsın.'));
          }
          final myVotedPolls = snapshot.data!;

          return ListView.separated(
            itemCount: myVotedPolls.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (context, index) {
              final pollDoc = myVotedPolls[index];
              final pollData = pollDoc.data() as Map<String, dynamic>?;

              if (pollData == null) return const SizedBox.shrink();

              final question = pollData['question'] ?? 'Anket sorusu yok';
              final pollId = pollDoc.id;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(
                  question,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // DOĞRU DOSYA YOLU KULLANILDI:
                      builder: (context) => SummaryScreen(initialPollId: pollId),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}