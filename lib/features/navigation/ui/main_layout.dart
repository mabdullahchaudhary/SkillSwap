import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../home/ui/home_feed_screen.dart';
import '../../swaps/ui/swaps_screen.dart';
import '../../chat/ui/chat_list_screen.dart';
import '../../profile/ui/profile_screen.dart';
import '../../chat/ui/chat_room_screen.dart'; // Global variables ke liye import

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  StreamSubscription? _notificationSubscription;

  final List<Widget> _screens = const [
    HomeFeedScreen(),
    SwapsScreen(),
    ChatListScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _listenForNewMessages();
  }

  // 🚀 ULTRA-MODERN MINIMAL NOTIFICATION ENGINE
  void _listenForNewMessages() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _notificationSubscription = FirebaseFirestore.instance
        .collection('requests')
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.modified) {
              final data = change.doc.data();
              if (data != null && data['lastMessage'] != null) {
                // Checks: Notifications ON hain aur banda kisi aur room mein toh nahi?
                if (globalNotificationsEnabled.value &&
                    change.doc.id != globalCurrentActiveRoomId) {
                  String partnerName = data['senderId'] == user.uid
                      ? data['receiverName']
                      : data['senderName'];

                  if (mounted) {
                    // Theme colors extract kar rahe hain notification design ke liye
                    final bool isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    final Color surfaceColor = isDark
                        ? const Color(0xFF18181B)
                        : Colors.white;
                    final Color textColor = isDark
                        ? Colors.white
                        : Colors.black87;
                    final Color textMuted = isDark
                        ? const Color(0xFFA1A1AA)
                        : Colors.grey[600]!;
                    final Color accentColor = isDark
                        ? const Color(0xFF00E5FF)
                        : const Color(0xFF007BFF);

                    ScaffoldMessenger.of(
                      context,
                    ).hideCurrentSnackBar(); // Purani fauran hatao
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        elevation: 15,
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: surfaceColor,
                        // Yeh margin notification ko screen ke TOP par bhej dega!
                        margin: EdgeInsets.only(
                          bottom: MediaQuery.of(context).size.height - 160,
                          left: 20,
                          right: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: Colors.grey.withAlpha(20),
                            width: 1,
                          ),
                        ),
                        duration: const Duration(seconds: 3),
                        content: Row(
                          children: [
                            // Minimal Icon Container
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: accentColor.withAlpha(20),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.chat_bubble_rounded,
                                color: accentColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Text Area
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    partnerName,
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    data['lastMessage'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: textMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                }
              }
            }
          }
        });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
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
    final Color unselectedColor = isDark
        ? const Color(0xFFA1A1AA)
        : Colors.grey[500]!;

    return Scaffold(
      backgroundColor: bgColor,
      body: IndexedStack(index: _currentIndex, children: _screens),
      extendBody: true,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: 24,
            top: 8,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 75,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: surfaceColor.withAlpha(180),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.grey.withAlpha(30),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(30),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildAnimatedNavItem(
                      icon: Icons.explore_rounded,
                      label: 'Explore',
                      index: 0,
                      accentColor: accentColor,
                      unselectedColor: unselectedColor,
                    ),
                    _buildAnimatedNavItem(
                      icon: Icons.handshake_rounded,
                      label: 'Swaps',
                      index: 1,
                      accentColor: accentColor,
                      unselectedColor: unselectedColor,
                    ),
                    _buildAnimatedNavItem(
                      icon: Icons.forum_rounded,
                      label: 'Workspace',
                      index: 2,
                      accentColor: accentColor,
                      unselectedColor: unselectedColor,
                    ),
                    _buildAnimatedNavItem(
                      icon: Icons.person_pin_rounded,
                      label: 'Profile',
                      index: 3,
                      accentColor: accentColor,
                      unselectedColor: unselectedColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedNavItem({
    required IconData icon,
    required String label,
    required int index,
    required Color accentColor,
    required Color unselectedColor,
  }) {
    final bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.fastOutSlowIn,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 12,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withAlpha(35) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 26,
              color: isSelected ? accentColor : unselectedColor,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 350),
              curve: Curves.fastOutSlowIn,
              child: isSelected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
