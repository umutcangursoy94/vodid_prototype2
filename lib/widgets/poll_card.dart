import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:vodid_prototype2/widgets/comments_sheet.dart'; // Bu dosyayı da düzelteceğiz

class PollCard extends StatefulWidget {
  final DocumentSnapshot pollDoc;
  final VideoPlayerController? videoController;

  const PollCard({
    super.key,
    required this.pollDoc,
    this.videoController,
  });

  @override
  State<PollCard> createState() => _PollCardState();
}

class _PollCardState extends State<PollCard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Güvenli ve anlık oy verme fonksiyonu
  Future<void> _vote(int optionIndex) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final pollRef = widget.pollDoc.reference;
    final voteRef = pollRef.collection('votes').doc(user.uid);

    await _firestore.runTransaction((transaction) async {
      final voteDoc = await transaction.get(voteRef);
      if (voteDoc.exists) return; // Zaten oy vermiş
      transaction.set(voteRef, {'option': optionIndex});
      transaction.update(pollRef, {
        'option${optionIndex + 1}_votes': FieldValue.increment(1),
      });
    });
  }

  // Yorumları gösteren fonksiyon
  void _showComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsSheet(pollId: widget.pollDoc.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pollData = widget.pollDoc.data() as Map<String, dynamic>;
    
    // TASARIM SIFIRLAMA: Orijinal arayüz birebir geri getirildi
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Video Arka Planı
        if (widget.videoController != null && widget.videoController!.value.isInitialized)
          Center(
            child: AspectRatio(
              aspectRatio: widget.videoController!.value.aspectRatio,
              child: VideoPlayer(widget.videoController!),
            ),
          )
        else
          const Center(child: CircularProgressIndicator(color: Colors.black)),

        // 2. Orijinal Gradyan Efekti (Metinlerin okunabilirliği için)
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.6),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withOpacity(0.8)
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.4, 0.6, 1.0],
            ),
          ),
        ),

        // 3. Arayüz Elementleri
        Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 20, left: 20, right: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Sol Taraf (Soru ve Butonlar)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pollData['question'] ?? 'Soru yüklenemedi',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildVoteSection(),
                  ],
                ),
              ),
              // Sağ Taraf (Yan Menü)
              _buildSideMenu(pollData),
            ],
          ),
        ),
      ],
    );
  }

  // Oy verme ve sonuçları gösteren bölüm
  Widget _buildVoteSection() {
    final user = _auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: widget.pollDoc.reference.collection('votes').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          // Oy verme butonları
          final pollData = widget.pollDoc.data() as Map<String, dynamic>;
          return Column(
            children: [
              _buildVoteButton(0, pollData['option1']),
              const SizedBox(height: 12),
              _buildVoteButton(1, pollData['option2']),
            ],
          );
        } else {
          // Sonuç barları
          return _buildResultsSection();
        }
      },
    );
  }

  // Orijinal Buton Tasarımı
  Widget _buildVoteButton(int index, String text) {
    return GestureDetector(
      onTap: () => _vote(index),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
  
  // Orijinal Sonuç Barı Tasarımı
  Widget _buildResultsSection() {
    return StreamBuilder<DocumentSnapshot>(
      stream: widget.pollDoc.reference.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 124); // Butonlarla aynı yüksekliği kapla
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final votes1 = data['option1_votes'] ?? 0;
        final votes2 = data['option2_votes'] ?? 0;
        final total = votes1 + votes2;
        return Column(
          children: [
            _buildResultBar(data['option1'], votes1, total),
            const SizedBox(height: 12),
            _buildResultBar(data['option2'], votes2, total),
          ],
        );
      },
    );
  }

  Widget _buildResultBar(String option, int votes, int total) {
    double percentage = total == 0 ? 0 : votes / total;
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          FractionallySizedBox(
            widthFactor: percentage,
            child: Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(12))),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(option, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                Text("${(percentage * 100).toStringAsFixed(0)}%", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Orijinal Yan Menü Tasarımı
  Widget _buildSideMenu(Map<String, dynamic> pollData) {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const CircleAvatar(radius: 24, backgroundColor: Colors.white), // Profil resmi
          const SizedBox(height: 24),
          _buildSideMenuItem(Icons.comment_outlined, pollData['comment_count'] ?? 0, _showComments),
          const SizedBox(height: 24),
          _buildSideMenuItem(Icons.share_outlined, 0, () {}), // Paylaşma
        ],
      ),
    );
  }

  Widget _buildSideMenuItem(IconData icon, int count, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(height: 4),
          Text(count.toString(), style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}