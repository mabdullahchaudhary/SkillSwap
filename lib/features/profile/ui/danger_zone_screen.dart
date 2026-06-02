import 'dart:math';
import 'package:flutter/material.dart';
import '../../authentication/data/auth_repository.dart';
import '../../authentication/ui/login_screen.dart';

class DangerZoneScreen extends StatefulWidget {
  const DangerZoneScreen({super.key});

  @override
  State<DangerZoneScreen> createState() => _DangerZoneScreenState();
}

class _DangerZoneScreenState extends State<DangerZoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _quizController = TextEditingController();
  final AuthRepository _authRepo = AuthRepository();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // Anti-Bot Math Quiz Variables
  late int _num1;
  late int _num2;
  late int _correctAnswer;

  @override
  void initState() {
    super.initState();
    _generateQuiz();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _quizController.dispose();
    super.dispose();
  }

  void _generateQuiz() {
    final random = Random();
    _num1 = random.nextInt(10) + 1; // 1 to 10
    _num2 = random.nextInt(10) + 1; // 1 to 10
    _correctAnswer = _num1 + _num2;
  }

  Future<void> _handleDeleteAccount() async {
    if (!_formKey.currentState!.validate()) return;

    // Verify Anti-Bot Quiz manually before hitting backend
    if (_quizController.text.trim() != _correctAnswer.toString()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect math answer. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() {
        _generateQuiz(); // Regenerate quiz on failure
        _quizController.clear();
      });
      return;
    }

    setState(() => _isLoading = true);

    String result = await _authRepo.deleteAccount(
      _passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result == "Success") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account permanently deleted.'),
          backgroundColor: Colors.orange,
        ),
      );
      // Navigate straight to Login & clear history
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result), backgroundColor: Colors.redAccent),
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
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color textMuted = isDark
        ? const Color(0xFFA1A1AA)
        : Colors.grey[600]!;
    const Color dangerColor = Colors.redAccent;

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
          'Danger Zone',
          style: TextStyle(
            color: dangerColor,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Warning Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: dangerColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: dangerColor.withAlpha(80),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: dangerColor,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'PERMANENT DELETION',
                      style: TextStyle(
                        color: dangerColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This action cannot be undone. All your messages, swaps, trust badges, and profile data will be permanently wiped from our servers.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Step 1: Password
              Text(
                'Step 1: Verify Identity',
                style: TextStyle(
                  color: textMuted,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              _buildDangerTextField(
                controller: _passwordController,
                hint: 'Enter your password',
                icon: Icons.lock_outline_rounded,
                isPassword: true,
                surfaceColor: surfaceColor,
                dangerColor: dangerColor,
                textColor: textColor,
                textMuted: textMuted,
              ),
              const SizedBox(height: 24),

              // Step 2: Anti-Bot Quiz
              Text(
                'Step 2: Anti-Bot Verification',
                style: TextStyle(
                  color: textMuted,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              _buildDangerTextField(
                controller: _quizController,
                hint: 'What is $_num1 + $_num2?',
                icon: Icons.calculate_outlined,
                isPassword: false,
                isNumber: true,
                surfaceColor: surfaceColor,
                dangerColor: dangerColor,
                textColor: textColor,
                textMuted: textMuted,
              ),
              const SizedBox(height: 40),

              // Final Delete Button
              GestureDetector(
                onTap: _isLoading ? null : _handleDeleteAccount,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: dangerColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: dangerColor.withAlpha(80),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'DELETE MY ACCOUNT',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 2.0,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDangerTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isPassword,
    bool isNumber = false,
    required Color surfaceColor,
    required Color dangerColor,
    required Color textColor,
    required Color textMuted,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: textColor, fontSize: 16),
      cursorColor: dangerColor,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: textMuted.withAlpha(178), fontSize: 14),
        prefixIcon: Icon(icon, color: textMuted),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: textMuted,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withAlpha(25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withAlpha(25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: dangerColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
      validator: (value) => value!.trim().isEmpty ? 'Required field' : null,
    );
  }
}
