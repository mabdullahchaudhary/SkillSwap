import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../authentication/data/auth_repository.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  User? currentUser = FirebaseAuth.instance.currentUser;
  final AuthRepository _authRepo = AuthRepository();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = currentUser?.displayName ?? '';
    _emailController.text = currentUser?.email ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final String fileName = image.name.toLowerCase();
      if (!fileName.endsWith('.jpg') &&
          !fileName.endsWith('.jpeg') &&
          !fileName.endsWith('.png') &&
          !fileName.endsWith('.webp')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Invalid format! Please upload a JPG, PNG, or WEBP image.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final int imageBytes = await image.length();
      if (imageBytes > 1048576) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image is too large! Maximum allowed size is 1 MB.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      setState(() => _isUploadingImage = true);

      String result = await _authRepo.uploadProfilePicture(image);

      if (!mounted) return;

      if (result == "Success") {
        await currentUser?.reload();
        setState(() {
          currentUser = FirebaseAuth.instance.currentUser;
          _isUploadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handleUpdateProfile({String? password}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String result = await _authRepo.updateProfileInfo(
      newName: _nameController.text.trim(),
      newEmail: _emailController.text.trim(),
      currentPassword: password,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result == "PASSWORD_REQUIRED") {
      _showPasswordDialog();
    } else if (result.startsWith("Success")) {
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

  void _showPasswordDialog() {
    final TextEditingController passwordController = TextEditingController();
    bool isObscure = true;

    showDialog(
      context: context,
      barrierDismissible: false,
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
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: surfaceColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(Icons.security_rounded, color: accentColor),
                  const SizedBox(width: 8),
                  Text(
                    'Security Check',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Please enter your current password to confirm email change.',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: isObscure,
                    style: TextStyle(color: textColor),
                    cursorColor: accentColor,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      hintStyle: TextStyle(color: Colors.grey.withAlpha(150)),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF09090B)
                          : const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isObscure ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () =>
                            setDialogState(() => isObscure = !isObscure),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    if (passwordController.text.isNotEmpty) {
                      _handleUpdateProfile(password: passwordController.text);
                    }
                  },
                  child: const Text(
                    'Verify',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
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
          'Edit Profile',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _isUploadingImage ? null : _pickAndUploadImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: accentColor.withAlpha(50),
                            width: 2,
                          ),
                        ),
                        child: _isUploadingImage
                            ? Padding(
                                padding: const EdgeInsets.all(28.0),
                                child: CircularProgressIndicator(
                                  color: accentColor,
                                  strokeWidth: 3,
                                ),
                              )
                            : currentUser?.photoURL != null
                            ? ClipOval(
                                child: Image.network(
                                  currentUser!.photoURL!,
                                  fit: BoxFit.cover,
                                  width: 100,
                                  height: 100,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(
                                        Icons.person,
                                        color: accentColor,
                                        size: 40,
                                      ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  _nameController.text.isNotEmpty
                                      ? _nameController.text[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w900,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: bgColor, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(20),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              _buildSmartTextField(
                controller: _nameController,
                hint: 'Full Name',
                icon: Icons.person_outline_rounded,
                surfaceColor: surfaceColor,
                accentColor: accentColor,
                textColor: textColor,
                textMuted: textMuted,
              ),
              const SizedBox(height: 20),

              _buildSmartTextField(
                controller: _emailController,
                hint: 'Email Address',
                icon: Icons.email_outlined,
                surfaceColor: surfaceColor,
                accentColor: accentColor,
                textColor: textColor,
                textMuted: textMuted,
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: textMuted, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Changing your email requires password verification.',
                      style: TextStyle(color: textMuted, fontSize: 12),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              GestureDetector(
                onTap: _isLoading ? null : () => _handleUpdateProfile(),
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
                            'SAVE CHANGES',
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

  Widget _buildSmartTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color surfaceColor,
    required Color accentColor,
    required Color textColor,
    required Color textMuted,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: textColor, fontSize: 16),
      cursorColor: accentColor,
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: TextStyle(color: textMuted.withAlpha(178), fontSize: 14),
        prefixIcon: Icon(icon, color: textMuted),
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
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
      ),
      validator: (value) =>
          value!.trim().isEmpty ? 'This field cannot be empty' : null,
    );
  }
}
