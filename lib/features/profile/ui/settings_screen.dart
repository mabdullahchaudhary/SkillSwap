import 'package:flutter/material.dart';
import 'package:skill_swap/main.dart';
import 'danger_zone_screen.dart';
import 'change_password_screen.dart';
import '../../authentication/data/auth_repository.dart';
import '../../authentication/ui/login_screen.dart';
import '../../authentication/ui/forgot_password_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoggingOut = false;

  Future<void> _handleLogout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        final Color surfaceColor = isDark
            ? const Color(0xFF18181B)
            : Colors.white;
        final Color textColor = isDark ? Colors.white : Colors.black87;

        return AlertDialog(
          backgroundColor: surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Log Out',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to log out of SkillSwap?',
            style: TextStyle(color: Colors.grey[500]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Log Out',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() => _isLoggingOut = true);
      await AuthRepository().logOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
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
          'Settings',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoggingOut
          ? const Center(
              child: CircularProgressIndicator(color: Colors.redAccent),
            )
          : ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                _buildSectionHeader('Preferences', accentColor),
                _buildSettingsTile(
                  title: 'App Theme',
                  subtitle: isDark ? 'Dark Mode' : 'Light Mode',
                  icon: isDark
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  surfaceColor: surfaceColor,
                  textColor: textColor,
                  textMuted: textMuted,
                  accentColor: accentColor,
                  trailing: Switch(
                    value: isDark,
                    activeColor: accentColor,
                    onChanged: (value) {
                      themeNotifier.value = value
                          ? ThemeMode.dark
                          : ThemeMode.light;
                    },
                  ),
                ),
                const SizedBox(height: 24),

                _buildSectionHeader('Security', accentColor),
                _buildSettingsTile(
                  title: 'Change Password',
                  subtitle: 'Update your login password',
                  icon: Icons.password_rounded,
                  surfaceColor: surfaceColor,
                  textColor: textColor,
                  textMuted: textMuted,
                  accentColor: accentColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChangePasswordScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildSettingsTile(
                  title: 'Forgot Password',
                  subtitle: 'Send a reset link to your email',
                  icon: Icons.lock_reset_rounded,
                  surfaceColor: surfaceColor,
                  textColor: textColor,
                  textMuted: textMuted,
                  accentColor: accentColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                _buildSectionHeader('Account Actions', Colors.redAccent),
                _buildSettingsTile(
                  title: 'Log Out',
                  subtitle: 'Sign out of your account safely',
                  icon: Icons.logout_rounded,
                  surfaceColor: surfaceColor,
                  textColor: Colors.redAccent,
                  textMuted: textMuted,
                  accentColor: Colors.redAccent,
                  onTap: _handleLogout,
                ),
                const SizedBox(height: 12),
                _buildSettingsTile(
                  title: 'Deactivate Account',
                  subtitle: 'Temporarily disable your profile',
                  icon: Icons.person_off_rounded,
                  surfaceColor: surfaceColor,
                  textColor: textColor,
                  textMuted: textMuted,
                  accentColor: Colors.orangeAccent,
                  onTap: () {
                    print("Open Deactivation Logic");
                  },
                ),
                const SizedBox(height: 12),
                _buildSettingsTile(
                  title: 'Delete Account',
                  subtitle: 'Permanently remove all data',
                  icon: Icons.delete_forever_rounded,
                  surfaceColor: surfaceColor,
                  textColor: Colors.redAccent,
                  textMuted: textMuted,
                  accentColor: Colors.redAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DangerZoneScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color surfaceColor,
    required Color textColor,
    required Color textMuted,
    required Color accentColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withAlpha(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else
              Icon(Icons.chevron_right_rounded, color: textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
