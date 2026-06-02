import 'package:flutter/material.dart';
import 'package:skill_swap/main.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

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
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.withAlpha(51)),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: textColor,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Text(
                    'REGULATIONS',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: accentColor.withAlpha(51)),
                    ),
                    child: IconButton(
                      icon: Icon(
                        isDark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        color: isDark
                            ? Colors.amberAccent
                            : Colors.indigoAccent,
                        size: 20,
                      ),
                      onPressed: () => themeNotifier.value = isDark
                          ? ThemeMode.light
                          : ThemeMode.dark,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                physics: const BouncingScrollPhysics(),
                children: [
                  Text(
                    'Welcome to SkillSwap',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please review our community guidelines before proceeding. These rules ensure a safe and professional environment for all members.',
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildPremiumRuleCard(
                    icon: Icons.handshake_rounded,
                    title: '01. Fair Swap Policy',
                    description:
                        'SkillSwap operates strictly on a barter system. Exchanging monetary funds for services is strictly prohibited and will result in immediate account termination.',
                    surfaceColor: surfaceColor,
                    accentColor: accentColor,
                    textColor: textColor,
                    textMuted: textMuted,
                  ),
                  const SizedBox(height: 16),
                  _buildPremiumRuleCard(
                    icon: Icons.verified_user_rounded,
                    title: '02. Identity & Verification',
                    description:
                        'All users must verify their email addresses. Impersonation, fake profiles, or misrepresenting your skill level violates our core terms of service.',
                    surfaceColor: surfaceColor,
                    accentColor: accentColor,
                    textColor: textColor,
                    textMuted: textMuted,
                  ),
                  const SizedBox(height: 16),
                  _buildPremiumRuleCard(
                    icon: Icons.gavel_rounded,
                    title: '03. Zero Tolerance Policy',
                    description:
                        'Harassment, hate speech, spamming, and unprofessional conduct are not tolerated. Users can report violations, triggering manual review by our moderation team.',
                    surfaceColor: surfaceColor,
                    accentColor: accentColor,
                    textColor: textColor,
                    textMuted: textMuted,
                  ),
                  const SizedBox(height: 16),
                  _buildPremiumRuleCard(
                    icon: Icons.privacy_tip_rounded,
                    title: '04. Data Privacy',
                    description:
                        'Your data is secured using industry-standard encryption. We do not sell your personal information or chat logs to third-party advertisers.',
                    surfaceColor: surfaceColor,
                    accentColor: accentColor,
                    textColor: textColor,
                    textMuted: textMuted,
                  ),
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: accentColor.withAlpha(127),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'I UNDERSTAND',
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumRuleCard({
    required IconData icon,
    required String title,
    required String description,
    required Color surfaceColor,
    required Color accentColor,
    required Color textColor,
    required Color textMuted,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withAlpha(25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 24, color: accentColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: TextStyle(color: textMuted, height: 1.6, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
