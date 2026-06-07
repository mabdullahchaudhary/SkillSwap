import 'package:flutter/material.dart';
import '../../authentication/data/auth_repository.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final AuthRepository _authRepo = AuthRepository();
  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitPasswordChange() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String result = await _authRepo.changePassword(
      currentPassword: _currentPasswordController.text.trim(),
      newPassword: _newPasswordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.startsWith("Success")) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
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
          'Change Password',
          style: TextStyle(
            color: textColor,
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
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.password_rounded,
                  size: 48,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 32),

              Text(
                'Current Password',
                style: TextStyle(
                  color: textMuted,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              _buildPasswordField(
                controller: _currentPasswordController,
                hint: 'Enter current password',
                isObscure: _obscureCurrent,
                onToggle: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
                surfaceColor: surfaceColor,
                accentColor: accentColor,
                textColor: textColor,
                textMuted: textMuted,
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),

              Text(
                'New Password',
                style: TextStyle(
                  color: textMuted,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              _buildPasswordField(
                controller: _newPasswordController,
                hint: 'Enter new password',
                isObscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
                surfaceColor: surfaceColor,
                accentColor: accentColor,
                textColor: textColor,
                textMuted: textMuted,
                validator: (val) => val!.length < 8 ? 'Min 8 characters' : null,
              ),
              const SizedBox(height: 16),

              _buildPasswordField(
                controller: _confirmPasswordController,
                hint: 'Confirm new password',
                isObscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
                surfaceColor: surfaceColor,
                accentColor: accentColor,
                textColor: textColor,
                textMuted: textMuted,
                validator: (val) {
                  if (val!.isEmpty) return 'Required';
                  if (val != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              GestureDetector(
                onTap: _isLoading ? null : _submitPasswordChange,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentColor.withAlpha(204), accentColor],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withAlpha(102),
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
                            'UPDATE PASSWORD',
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool isObscure,
    required VoidCallback onToggle,
    required Color surfaceColor,
    required Color accentColor,
    required Color textColor,
    required Color textMuted,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      style: TextStyle(color: textColor, fontSize: 16),
      cursorColor: accentColor,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: textMuted.withAlpha(178), fontSize: 14),
        prefixIcon: Icon(Icons.lock_outline_rounded, color: textMuted),
        suffixIcon: IconButton(
          icon: Icon(
            isObscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: textMuted,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }
}
