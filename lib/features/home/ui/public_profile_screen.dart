import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PublicProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String userId;

  const PublicProfileScreen({
    super.key,
    required this.userData,
    required this.userId,
  });

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _showRequestSheet(BuildContext context, String receiverName) {
    final TextEditingController messageController = TextEditingController();
    bool isSending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        final Color surfaceColor = isDark
            ? const Color(0xFF18181B)
            : Colors.white;
        final Color accentColor = isDark
            ? const Color(0xFF00E5FF)
            : const Color(0xFF007BFF);
        final Color textColor = isDark ? Colors.white : Colors.black87;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  Text(
                    'Connect with $receiverName',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Introduce yourself and propose a skill swap.',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: messageController,
                    maxLines: 4,
                    style: TextStyle(color: textColor, fontSize: 14),
                    cursorColor: accentColor,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText:
                          'e.g., Hi! I can help you with Flutter if you can teach me a bit of UI/UX...',
                      hintStyle: TextStyle(color: Colors.grey.withAlpha(150)),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF09090B)
                          : const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: isSending
                          ? null
                          : () async {
                              if (messageController.text.trim().isNotEmpty) {
                                setSheetState(() => isSending = true);
                                await _sendSwapRequest(
                                  messageController.text.trim(),
                                );
                                if (!context.mounted) return;
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Request sent successfully! 🚀',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                      child: isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Send Request',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
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

  Future<void> _sendSwapRequest(String message) async {
    if (currentUser == null) return;

    if (currentUser!.uid == widget.userId) return;

    String roomId = currentUser!.uid.compareTo(widget.userId) < 0
        ? '${currentUser!.uid}_${widget.userId}'
        : '${widget.userId}_${currentUser!.uid}';

    final docRef = _firestore.collection('requests').doc(roomId);
    final docSnap = await docRef.get();

    if (docSnap.exists) {
      await docRef.update({
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      await docRef.set({
        'senderId': currentUser!.uid,
        'receiverId': widget.userId,
        'senderName': currentUser!.displayName ?? 'Skill Swapper',
        'receiverName': widget.userData['name'] ?? 'Unknown User',
        'message': message,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF09090B) : Colors.white;
    final Color surfaceColor = isDark
        ? const Color(0xFF18181B)
        : const Color(0xFFF8F9FA);
    final Color accentColor = isDark
        ? const Color(0xFF00E5FF)
        : const Color(0xFF007BFF);
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color textMuted = isDark
        ? const Color(0xFFA1A1AA)
        : Colors.grey[600]!;

    final String name = widget.userData['name'] ?? 'Skill Swapper';
    final String photoUrl = widget.userData['photoUrl'] ?? '';
    final List<dynamic> offers = widget.userData['offers'] ?? [];
    final List<dynamic> needs = widget.userData['needs'] ?? [];
    final String bio = widget.userData['bio'] ?? '';
    final String website = widget.userData['website'] ?? '';
    final String github = widget.userData['github'] ?? '';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textColor,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(top: BorderSide(color: Colors.grey.withAlpha(20))),
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          onPressed: () => _showRequestSheet(context, name),
          child: const Text(
            'Request Swap 🤝',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: accentColor.withAlpha(30),
                  backgroundImage: photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl.isEmpty
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '5.0',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            ' (12 Reviews)',
                            style: TextStyle(color: textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            if (bio.isNotEmpty) ...[
              Text(
                'ABOUT ME',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                bio,
                style: TextStyle(color: textColor, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 32),
            ],

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withAlpha(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'I CAN TEACH',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  offers.isEmpty
                      ? Text(
                          'Nothing added yet',
                          style: TextStyle(color: textMuted, fontSize: 13),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: offers
                              .map(
                                (skill) => _buildSkillChip(
                                  skill['name'],
                                  skill['level'],
                                  accentColor,
                                  isDark,
                                ),
                              )
                              .toList(),
                        ),

                  const SizedBox(height: 24),
                  Divider(color: Colors.grey.withAlpha(20), height: 1),
                  const SizedBox(height: 24),

                  Text(
                    'I WANT TO LEARN',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  needs.isEmpty
                      ? Text(
                          'Nothing added yet',
                          style: TextStyle(color: textMuted, fontSize: 13),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: needs
                              .map(
                                (skill) => _buildSkillChip(
                                  skill['name'],
                                  skill['level'],
                                  Colors.orange,
                                  isDark,
                                ),
                              )
                              .toList(),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            if (website.isNotEmpty || github.isNotEmpty) ...[
              Text(
                'LINKS & PORTFOLIO',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (website.isNotEmpty)
                    _buildLinkButton(
                      Icons.language_rounded,
                      'Website',
                      surfaceColor,
                      textColor,
                    ),
                  if (github.isNotEmpty)
                    _buildLinkButton(
                      Icons.code_rounded,
                      'GitHub',
                      surfaceColor,
                      textColor,
                    ),
                ],
              ),
              const SizedBox(height: 32),
            ],

            Text(
              'RECENT REVIEWS',
              style: TextStyle(
                color: textMuted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            _buildReviewCard(
              'Ali Khan',
              'Great mentor! Explained concepts very clearly.',
              surfaceColor,
              textColor,
              textMuted,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillChip(String label, String level, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : color.withAlpha(10),
        border: Border.all(color: color.withAlpha(30)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              level,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkButton(
    IconData icon,
    String label,
    Color surfaceColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withAlpha(20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(
    String reviewer,
    String text,
    Color surfaceColor,
    Color textColor,
    Color textMuted,
  ) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                reviewer,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => const Icon(
                    Icons.star_rounded,
                    color: Colors.amber,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(color: textMuted, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}
