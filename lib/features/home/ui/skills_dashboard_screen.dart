import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SkillsDashboardScreen extends StatefulWidget {
  const SkillsDashboardScreen({super.key});

  @override
  State<SkillsDashboardScreen> createState() => _SkillsDashboardScreenState();
}

class _SkillsDashboardScreenState extends State<SkillsDashboardScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. ADD SKILL BOTTOM SHEET
  void _showAddSkillSheet(bool isOffer) {
    final TextEditingController skillController = TextEditingController();
    String selectedLevel = 'Beginner';
    final List<String> levels = ['Beginner', 'Intermediate', 'Advanced'];
    bool isSaving = false;

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
                    isOffer
                        ? 'What can you teach?'
                        : 'What do you want to learn?',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: skillController,
                    style: TextStyle(color: textColor, fontSize: 16),
                    cursorColor: accentColor,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'e.g., UI/UX Design, Flutter...',
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
                  const SizedBox(height: 20),

                  Text(
                    'PROFICIENCY LEVEL',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    children: levels.map((lvl) {
                      final isSelected = selectedLevel == lvl;
                      return ChoiceChip(
                        label: Text(
                          lvl,
                          style: TextStyle(
                            color: isSelected ? Colors.white : textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: isOffer
                            ? accentColor
                            : Colors.orangeAccent,
                        backgroundColor: isDark
                            ? const Color(0xFF09090B)
                            : const Color(0xFFF8F9FA),
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected
                                ? Colors.transparent
                                : Colors.grey.withAlpha(30),
                          ),
                        ),
                        onSelected: (selected) {
                          if (selected)
                            setSheetState(() => selectedLevel = lvl);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isOffer
                            ? accentColor
                            : Colors.orangeAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (skillController.text.trim().isNotEmpty) {
                                setSheetState(() => isSaving = true);
                                await _addSkillToDatabase(
                                  skillController.text.trim(),
                                  selectedLevel,
                                  isOffer,
                                );
                                if (!context.mounted) return;
                                Navigator.pop(context);
                              }
                            },
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Save Skill',
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

  // 2. EDIT BIO & LINKS BOTTOM SHEET
  void _showEditDetailsSheet(
    String currentBio,
    String currentWeb,
    String currentGit,
  ) {
    final TextEditingController bioController = TextEditingController(
      text: currentBio,
    );
    final TextEditingController webController = TextEditingController(
      text: currentWeb,
    );
    final TextEditingController gitController = TextEditingController(
      text: currentGit,
    );
    bool isSaving = false;

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
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
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
                      'Edit About & Links',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildTextInput(
                      bioController,
                      'Short Bio',
                      'Tell others about yourself...',
                      isDark,
                      textColor,
                      accentColor,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    _buildTextInput(
                      webController,
                      'Personal Website (Optional)',
                      'https://...',
                      isDark,
                      textColor,
                      accentColor,
                    ),
                    const SizedBox(height: 16),
                    _buildTextInput(
                      gitController,
                      'GitHub Link (Optional)',
                      'https://github.com/...',
                      isDark,
                      textColor,
                      accentColor,
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
                        onPressed: isSaving
                            ? null
                            : () async {
                                setSheetState(() => isSaving = true);
                                await _saveDetailsToDatabase(
                                  bioController.text.trim(),
                                  webController.text.trim(),
                                  gitController.text.trim(),
                                );
                                if (!context.mounted) return;
                                Navigator.pop(context);
                              },
                        child: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Save Details',
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
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextInput(
    TextEditingController controller,
    String label,
    String hint,
    bool isDark,
    Color textColor,
    Color accentColor, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: textColor, fontSize: 14),
          cursorColor: accentColor,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.withAlpha(150)),
            filled: true,
            fillColor: isDark
                ? const Color(0xFF09090B)
                : const Color(0xFFF8F9FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  // DATABASE FUNCTIONS
  Future<void> _addSkillToDatabase(
    String skillName,
    String level,
    bool isOffer,
  ) async {
    if (currentUser == null) return;
    final docRef = _firestore.collection('users').doc(currentUser!.uid);
    final fieldName = isOffer ? 'offers' : 'needs';
    final newSkill = {'name': skillName, 'level': level};
    await docRef.set({
      fieldName: FieldValue.arrayUnion([newSkill]),
    }, SetOptions(merge: true));
  }

  Future<void> _deleteSkillFromDatabase(
    Map<String, dynamic> skillToRemove,
    bool isOffer,
  ) async {
    if (currentUser == null) return;
    final docRef = _firestore.collection('users').doc(currentUser!.uid);
    final fieldName = isOffer ? 'offers' : 'needs';
    await docRef.update({
      fieldName: FieldValue.arrayRemove([skillToRemove]),
    });
  }

  Future<void> _saveDetailsToDatabase(
    String bio,
    String web,
    String git,
  ) async {
    if (currentUser == null) return;
    final docRef = _firestore.collection('users').doc(currentUser!.uid);
    await docRef.set({
      'bio': bio,
      'website': web,
      'github': git,
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF09090B) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color textMuted = isDark
        ? const Color(0xFFA1A1AA)
        : Colors.grey[600]!;

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
        title: Text(
          'My Dashboard',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
      ),
      body: currentUser == null
          ? const Center(child: Text("Please log in first"))
          : StreamBuilder<DocumentSnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(currentUser!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());
                final data = snapshot.data?.data() as Map<String, dynamic>?;

                final List<dynamic> offers = data?['offers'] ?? [];
                final List<dynamic> needs = data?['needs'] ?? [];
                final String bio = data?['bio'] ?? '';
                final String website = data?['website'] ?? '';
                final String github = data?['github'] ?? '';

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // BIO & LINKS SECTION
                      _buildCleanSectionHeader(
                        'ABOUT & LINKS',
                        'Add your bio and portfolio.',
                        Colors.teal,
                        () => _showEditDetailsSheet(bio, website, github),
                      ),
                      const SizedBox(height: 20),
                      if (bio.isEmpty && website.isEmpty && github.isEmpty)
                        _buildEmptyState(
                          'No bio or links added yet.',
                          textMuted,
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF18181B)
                                : Colors.teal.withAlpha(10),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.teal.withAlpha(30),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (bio.isNotEmpty)
                                Text(
                                  bio,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              if (bio.isNotEmpty &&
                                  (website.isNotEmpty || github.isNotEmpty))
                                const SizedBox(height: 12),
                              if (website.isNotEmpty)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.language_rounded,
                                      size: 14,
                                      color: Colors.teal,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        website,
                                        style: TextStyle(
                                          color: Colors.teal,
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              if (website.isNotEmpty && github.isNotEmpty)
                                const SizedBox(height: 6),
                              if (github.isNotEmpty)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.code_rounded,
                                      size: 14,
                                      color: Colors.teal,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        github,
                                        style: TextStyle(
                                          color: Colors.teal,
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 48),
                      Divider(color: Colors.grey.withAlpha(20), height: 1),
                      const SizedBox(height: 36),

                      // SKILLS SECTION
                      _buildCleanSectionHeader(
                        'I CAN TEACH',
                        'Add skills you want to offer.',
                        const Color(0xFF007BFF),
                        () => _showAddSkillSheet(true),
                      ),
                      const SizedBox(height: 20),
                      offers.isEmpty
                          ? _buildEmptyState('No skills added yet.', textMuted)
                          : Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: offers
                                  .map(
                                    (skill) => _buildCleanSkillCard(
                                      skill,
                                      const Color(0xFF007BFF),
                                      true,
                                      isDark,
                                      textColor,
                                    ),
                                  )
                                  .toList(),
                            ),

                      const SizedBox(height: 48),
                      Divider(color: Colors.grey.withAlpha(20), height: 1),
                      const SizedBox(height: 36),

                      _buildCleanSectionHeader(
                        'I WANT TO LEARN',
                        'Add skills you are looking for.',
                        Colors.orange,
                        () => _showAddSkillSheet(false),
                      ),
                      const SizedBox(height: 20),
                      needs.isEmpty
                          ? _buildEmptyState(
                              'No learning goals added yet.',
                              textMuted,
                            )
                          : Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: needs
                                  .map(
                                    (skill) => _buildCleanSkillCard(
                                      skill,
                                      Colors.orange,
                                      false,
                                      isDark,
                                      textColor,
                                    ),
                                  )
                                  .toList(),
                            ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildCleanSectionHeader(
    String title,
    String subtitle,
    Color accentColor,
    VoidCallback onAdd,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accentColor.withAlpha(30)),
            ),
            child: Icon(Icons.add_rounded, color: accentColor, size: 22),
          ),
        ),
      ],
    );
  }

  Widget _buildCleanSkillCard(
    dynamic skill,
    Color color,
    bool isOffer,
    bool isDark,
    Color textColor,
  ) {
    final Map<String, dynamic> skillData = skill as Map<String, dynamic>;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : color.withAlpha(10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(40), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                skillData['name'],
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                skillData['level'],
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          GestureDetector(
            onTap: () => _deleteSkillFromDatabase(skillData, isOffer),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: color.withAlpha(200),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg, Color textMuted) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(10),
        border: Border.all(
          color: Colors.grey.withAlpha(20),
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(color: textMuted, fontSize: 13),
      ),
    );
  }
}
