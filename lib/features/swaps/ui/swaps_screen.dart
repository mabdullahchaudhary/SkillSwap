import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SwapsScreen extends StatefulWidget {
  const SwapsScreen({super.key});

  @override
  State<SwapsScreen> createState() => _SwapsScreenState();
}

class _SwapsScreenState extends State<SwapsScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _updateRequestStatus(String docId, String newStatus) async {
    try {
      await _firestore.collection('requests').doc(docId).update({
        'status': newStatus,
      });
    } catch (e) {
      debugPrint("Error updating request: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark
        ? const Color(0xFF09090B)
        : const Color(0xFFF8F9FA);
    final Color surfaceColor = isDark ? const Color(0xFF18181B) : Colors.white;
    final Color accentColor = isDark
        ? const Color(0xFF00E5FF)
        : const Color(0xFF007BFF);
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color textMuted = isDark
        ? const Color(0xFFA1A1AA)
        : Colors.grey[600]!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'My Swaps',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          bottom: TabBar(
            indicatorColor: accentColor,
            labelColor: accentColor,
            unselectedLabelColor: textMuted,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'Received'),
              Tab(text: 'Sent Requests'),
            ],
          ),
        ),
        body: currentUser == null
            ? const Center(child: Text("Please log in to see requests."))
            : TabBarView(
                children: [
                  _buildReceivedTab(
                    surfaceColor,
                    accentColor,
                    textColor,
                    textMuted,
                  ),
                  _buildSentTab(
                    surfaceColor,
                    accentColor,
                    textColor,
                    textMuted,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildReceivedTab(
    Color surfaceColor,
    Color accentColor,
    Color textColor,
    Color textMuted,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('requests')
          .where('receiverId', isEqualTo: currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return _buildEmptyState('No requests received yet.', textMuted);

        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final t1 =
              (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
          final t2 =
              (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
          if (t1 == null) return -1;
          if (t2 == null) return 1;
          return t2.compareTo(t1);
        });

        return ListView.separated(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: 100,
          ),
          physics: const BouncingScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final String senderName = data['senderName'] ?? 'Unknown User';
            final String message = data['message'] ?? '';
            final String status = data['status'] ?? 'pending';

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withAlpha(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: accentColor.withAlpha(20),
                        child: Text(
                          senderName[0].toUpperCase(),
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          senderName,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      _buildStatusPill(status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),

                  if (status == 'pending') ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () =>
                                _updateRequestStatus(doc.id, 'rejected'),
                            child: const Text(
                              'Decline',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () =>
                                _updateRequestStatus(doc.id, 'accepted'),
                            child: const Text(
                              'Accept',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSentTab(
    Color surfaceColor,
    Color accentColor,
    Color textColor,
    Color textMuted,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('requests')
          .where('senderId', isEqualTo: currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return _buildEmptyState(
            'You haven\'t sent any requests yet.',
            textMuted,
          );

        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final t1 =
              (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
          final t2 =
              (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
          if (t1 == null) return -1;
          if (t2 == null) return 1;
          return t2.compareTo(t1);
        });

        return ListView.separated(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: 100,
          ),
          physics: const BouncingScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final String receiverName = data['receiverName'] ?? 'Unknown User';
            final String message = data['message'] ?? '';
            final String status = data['status'] ?? 'pending';

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withAlpha(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'To: ',
                        style: TextStyle(color: textMuted, fontSize: 13),
                      ),
                      Expanded(
                        child: Text(
                          receiverName,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      _buildStatusPill(status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 13,
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusPill(String status) {
    Color bgColor = Colors.orange.withAlpha(20);
    Color textColor = Colors.orange;
    String text = 'Pending';

    if (status == 'accepted') {
      bgColor = Colors.green.withAlpha(20);
      textColor = Colors.green;
      text = 'Accepted';
    } else if (status == 'rejected') {
      bgColor = Colors.redAccent.withAlpha(20);
      textColor = Colors.redAccent;
      text = 'Declined';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg, Color textMuted) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.handshake_rounded,
            size: 60,
            color: Colors.grey.withAlpha(50),
          ),
          const SizedBox(height: 16),
          Text(msg, style: TextStyle(color: textMuted, fontSize: 14)),
        ],
      ),
    );
  }
}
