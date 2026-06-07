import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../home/ui/public_profile_screen.dart'; // Ensure correct path for Public Profile
import 'video_call_screen.dart';

// GLOBAL VARIABLES TO CONTROL NOTIFICATIONS
String? globalCurrentActiveRoomId;
ValueNotifier<bool> globalNotificationsEnabled = ValueNotifier(true);

class ChatRoomScreen extends StatefulWidget {
  final String roomId;
  final String partnerName;
  final String partnerId;

  const ChatRoomScreen({
    super.key,
    required this.roomId,
    required this.partnerName,
    required this.partnerId,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // App ko bata do ke hum is room mein hain, taake yahan ki notification na aaye
    globalCurrentActiveRoomId = widget.roomId;
  }

  @override
  void dispose() {
    // Jab chat se bahar jayen toh room id clear kar dein
    globalCurrentActiveRoomId = null;
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || currentUser == null) return;

    _messageController.clear();

    await _firestore
        .collection('requests')
        .doc(widget.roomId)
        .collection('messages')
        .add({
          'senderId': currentUser!.uid,
          'text': text,
          'timestamp': FieldValue.serverTimestamp(),
        });

    await _firestore.collection('requests').doc(widget.roomId).update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _onOpenLink(LinkableElement link) async {
    final Uri uri = Uri.parse(link.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch ${link.url}');
    }
  }

  // 📂 MODERN ATTACHMENT BOTTOM SHEET
  void _showAttachmentSheet(Color surfaceColor, Color textColor, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(50),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAttachOption(
                    Icons.image_rounded,
                    Colors.purpleAccent,
                    'Gallery',
                  ),
                  _buildAttachOption(
                    Icons.camera_alt_rounded,
                    Colors.pinkAccent,
                    'Camera',
                  ),
                  _buildAttachOption(
                    Icons.insert_drive_file_rounded,
                    Colors.blueAccent,
                    'Document',
                  ),
                  _buildAttachOption(
                    Icons.mic_rounded,
                    Colors.orangeAccent,
                    'Audio',
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachOption(IconData icon, Color color, String label) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$label sharing coming soon!')));
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // 👤 FETCH AND OPEN PUBLIC PROFILE
  Future<void> _openPartnerProfile() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final doc = await _firestore
          .collection('users')
          .doc(widget.partnerId)
          .get();
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (doc.exists) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PublicProfileScreen(
              userData: doc.data()!,
              userId: widget.partnerId,
            ),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not load profile.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark
        ? const Color(0xFF09090B)
        : const Color(0xFFF0F2F5);
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
      appBar: _buildChatAppBar(surfaceColor, textColor, accentColor, textMuted),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('requests')
                  .doc(widget.roomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  return Center(
                    child: Text(
                      'Say hi to ${widget.partnerName}! 👋',
                      style: TextStyle(
                        color: textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  );

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  physics: const BouncingScrollPhysics(),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    final bool isMe = data['senderId'] == currentUser?.uid;
                    final String msgText = data['text'] ?? '';
                    final Timestamp? timestamp =
                        data['timestamp'] as Timestamp?;

                    return _buildModernChatBubble(
                      msgText,
                      isMe,
                      timestamp,
                      accentColor,
                      isDark,
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInputArea(
            surfaceColor,
            accentColor,
            textColor,
            textMuted,
            isDark,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildChatAppBar(
    Color surfaceColor,
    Color textColor,
    Color accentColor,
    Color textMuted,
  ) {
    return AppBar(
      backgroundColor: surfaceColor,
      elevation: 0.5,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: textColor,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: GestureDetector(
        onTap: _openPartnerProfile,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: accentColor.withAlpha(20),
              child: Text(
                widget.partnerName[0].toUpperCase(),
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.partnerName,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Workspace Active',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        // 📞 AUDIO CALL BUTTON
        IconButton(
          icon: Icon(Icons.call_rounded, color: accentColor, size: 22),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoCallScreen(
                  roomId: widget.roomId,
                  partnerName: widget.partnerName,
                  isVideoCall: false,
                ),
              ),
            );
          },
        ),
        // 🎥 VIDEO CALL BUTTON
        IconButton(
          icon: Icon(Icons.videocam_rounded, color: accentColor, size: 26),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoCallScreen(
                  roomId: widget.roomId,
                  partnerName: widget.partnerName,
                  isVideoCall: true,
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildModernChatBubble(
    String text,
    bool isMe,
    Timestamp? timestamp,
    Color accentColor,
    bool isDark,
  ) {
    String timeString = '';
    if (timestamp != null)
      timeString = DateFormat('h:mm a').format(timestamp.toDate());

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMe
                  ? accentColor
                  : (isDark ? const Color(0xFF27272A) : Colors.white),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SelectableLinkify(
              onOpen: _onOpenLink,
              text: text,
              style: TextStyle(
                color: isMe
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black87),
                fontSize: 15,
                height: 1.3,
              ),
              linkStyle: TextStyle(
                color: isMe ? Colors.white : accentColor,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeString,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                Icon(Icons.done_all_rounded, size: 14, color: accentColor),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInputArea(
    Color surfaceColor,
    Color accentColor,
    Color textColor,
    Color textMuted,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 24),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(top: BorderSide(color: Colors.grey.withAlpha(20))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            icon: Icon(
              Icons.add_circle_outline_rounded,
              color: textMuted,
              size: 26,
            ),
            onPressed: () => _showAttachmentSheet(
              surfaceColor,
              textColor,
              isDark,
            ), // Trigger Bottom Sheet
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF09090B)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                style: TextStyle(color: textColor, fontSize: 15),
                cursorColor: accentColor,
                maxLines: 5,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Message...',
                  hintStyle: TextStyle(color: textMuted.withAlpha(150)),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
