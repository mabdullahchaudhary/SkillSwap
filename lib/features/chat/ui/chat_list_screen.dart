import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Active Workspaces',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        actions: [
          // 🔔 NOTIFICATION TOGGLE BUTTON
          ValueListenableBuilder<bool>(
            valueListenable: globalNotificationsEnabled,
            builder: (context, isEnabled, child) {
              return IconButton(
                icon: Icon(
                  isEnabled
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_off_rounded,
                  color: isEnabled ? accentColor : textMuted,
                ),
                onPressed: () {
                  globalNotificationsEnabled.value = !isEnabled;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        globalNotificationsEnabled.value
                            ? 'In-App Notifications Enabled 🔔'
                            : 'In-App Notifications Disabled 🔕',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: currentUser == null
          ? const Center(child: Text("Please log in to see your workspaces."))
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('requests')
                  .where('status', isEqualTo: 'accepted')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  return _buildEmptyState(
                    'No active swaps yet. Start requesting!',
                    textMuted,
                  );

                final activeChats = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['senderId'] == currentUser!.uid ||
                      data['receiverId'] == currentUser!.uid;
                }).toList();

                final Set<String> seenPartners = {};
                final List<DocumentSnapshot> uniqueChats = [];

                for (var doc in activeChats) {
                  final data = doc.data() as Map<String, dynamic>;
                  final isMeSender = data['senderId'] == currentUser!.uid;
                  final String chatPartnerId = isMeSender
                      ? data['receiverId']
                      : data['senderId'];

                  if (!seenPartners.contains(chatPartnerId)) {
                    seenPartners.add(chatPartnerId);
                    uniqueChats.add(doc);
                  }
                }

                if (uniqueChats.isEmpty)
                  return _buildEmptyState('No active swaps yet.', textMuted);

                return ListView.separated(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 10,
                    bottom: 100,
                  ),
                  physics: const BouncingScrollPhysics(),
                  itemCount: uniqueChats.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = uniqueChats[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final isMeSender = data['senderId'] == currentUser!.uid;
                    final String chatPartnerId = isMeSender
                        ? data['receiverId']
                        : data['senderId'];
                    final String chatPartnerName = isMeSender
                        ? data['receiverName']
                        : data['senderName'];

                    return _buildChatTile(
                      chatPartnerName,
                      chatPartnerId,
                      doc.id,
                      surfaceColor,
                      accentColor,
                      textColor,
                      textMuted,
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildChatTile(
    String partnerName,
    String partnerId,
    String roomId,
    Color surfaceColor,
    Color accentColor,
    Color textColor,
    Color textMuted,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomScreen(
              roomId: roomId,
              partnerName: partnerName,
              partnerId: partnerId,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withAlpha(20)),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: accentColor.withAlpha(20),
              child: Text(
                partnerName[0].toUpperCase(),
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    partnerName,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to enter workspace',
                    style: TextStyle(color: textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg, Color textMuted) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_rounded, size: 60, color: Colors.grey.withAlpha(50)),
          const SizedBox(height: 16),
          Text(msg, style: TextStyle(color: textMuted, fontSize: 14)),
        ],
      ),
    );
  }
}
