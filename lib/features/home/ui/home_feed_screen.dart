import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'skills_dashboard_screen.dart';
import 'public_profile_screen.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _syncUserDataToFirestore();
  }

  Future<void> _syncUserDataToFirestore() async {
    if (currentUser == null) return;
    final docRef = _firestore.collection('users').doc(currentUser!.uid);
    await docRef.set({
      'name': currentUser!.displayName ?? 'Skill Swapper',
      'photoUrl': currentUser!.photoURL ?? '',
      'email': currentUser!.email ?? '',
    }, SetOptions(merge: true));
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

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Explore',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withAlpha(30)),
            ),
            child: IconButton(
              icon: Icon(Icons.tune_rounded, color: textColor, size: 22),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SkillsDashboardScreen(),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
              style: TextStyle(color: textColor, fontSize: 15),
              cursorColor: accentColor,
              decoration: InputDecoration(
                hintText: 'Search for skills or people...',
                hintStyle: TextStyle(color: textMuted.withAlpha(150)),
                prefixIcon: Icon(Icons.search_rounded, color: textMuted),
                filled: true,
                fillColor: surfaceColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: accentColor, width: 1.5),
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No users found.',
                      style: TextStyle(color: textMuted),
                    ),
                  );
                }

                final users = snapshot.data!.docs.where((doc) {
                  if (doc.id == currentUser?.uid) return false;

                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final List<dynamic> offers = data['offers'] ?? [];
                  final List<dynamic> needs = data['needs'] ?? [];

                  if (_searchQuery.isEmpty) return true;
                  bool matchesName = name.contains(_searchQuery);
                  bool matchesOffer = offers.any(
                    (skill) => (skill['name'] ?? '')
                        .toString()
                        .toLowerCase()
                        .contains(_searchQuery),
                  );
                  bool matchesNeed = needs.any(
                    (skill) => (skill['name'] ?? '')
                        .toString()
                        .toLowerCase()
                        .contains(_searchQuery),
                  );
                  return matchesName || matchesOffer || matchesNeed;
                }).toList();

                if (users.isEmpty) {
                  return Center(
                    child: Text(
                      'No matching results.',
                      style: TextStyle(color: textMuted),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 10,
                    bottom: 100,
                  ),
                  physics: const BouncingScrollPhysics(),
                  itemCount: users.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final doc = users[index];
                    final userData = doc.data() as Map<String, dynamic>;
                    return _buildMinimalUserCard(
                      userData,
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
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalUserCard(
    Map<String, dynamic> user,
    String userId,
    Color surfaceColor,
    Color accentColor,
    Color textColor,
    Color textMuted,
  ) {
    final String name = user['name'] ?? 'Skill Swapper';
    final String photoUrl = user['photoUrl'] ?? '';
    final List<dynamic> offers = user['offers'] ?? [];
    final List<dynamic> needs = user['needs'] ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withAlpha(25), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PublicProfileScreen(userData: user, userId: userId),
                ),
              );
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
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
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'New User',
                            style: TextStyle(color: textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: textMuted),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.grey.withAlpha(30), height: 1),
          ),

          Text(
            'I CAN TEACH:',
            style: TextStyle(
              color: textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          offers.isEmpty
              ? Text(
                  'Nothing added yet',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
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
                          isOffer: true,
                        ),
                      )
                      .toList(),
                ),

          const SizedBox(height: 16),

          Text(
            'I WANT TO LEARN:',
            style: TextStyle(
              color: textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          needs.isEmpty
              ? Text(
                  'Nothing added yet',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: needs
                      .map(
                        (skill) => _buildSkillChip(
                          skill['name'],
                          skill['level'],
                          Colors.orangeAccent,
                          isOffer: false,
                        ),
                      )
                      .toList(),
                ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor.withAlpha(20),
                foregroundColor: accentColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                if (kDebugMode) {
                  print("Request Swap with $name");
                }
              },
              child: const Text(
                'Request Swap',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillChip(
    String label,
    String level,
    Color color, {
    required bool isOffer,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isOffer ? color.withAlpha(15) : Colors.transparent,
        border: Border.all(color: color.withAlpha(50)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              level,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
