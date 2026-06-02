import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // V7 Standard: instance use karna lazmi hai
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static bool _isGoogleInitialized = false;

  // 1. SIGNUP
  Future<String> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName(name);
        await user.sendEmailVerification();
        await _auth.signOut();
        return "Success: Verification email sent. Please check your inbox.";
      }
      return "Error: Could not create user.";
    } on FirebaseAuthException catch (e) {
      return e.message ?? "An unknown error occurred";
    } catch (e) {
      return e.toString();
    }
  }

  // 2. LOGIN
  Future<String> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;
      if (user != null) {
        if (!user.emailVerified) {
          await _auth.signOut();
          return "Unverified: Please verify your email before logging in.";
        }
        return "Success";
      }
      return "Error: User not found.";
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Invalid email or password.";
    }
  }

  // 3. GOOGLE AUTH
  Future<String> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        await _auth.signInWithPopup(googleProvider);
        return "Success";
      } else {
        if (!_isGoogleInitialized) {
          await _googleSignIn.initialize();
          _isGoogleInitialized = true;
        }

        final GoogleSignInAccount? googleUser = await _googleSignIn
            .authenticate();
        if (googleUser == null) return "Cancelled by user";

        final GoogleSignInAuthentication googleAuth = googleUser.authentication;
        final clientAuth = await googleUser.authorizationClient.authorizeScopes(
          ['email', 'profile'],
        );

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: clientAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await _auth.signInWithCredential(credential);
        return "Success";
      }
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Google Sign-In failed.";
    } catch (e) {
      return "Error: ${e.toString()}";
    }
  }

  // 4. FORGOT PASSWORD
  Future<String> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return "Success: Password reset link sent to your email.";
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Could not send reset link.";
    }
  }

  // 5. UPDATE PROFILE
  Future<String> updateProfileInfo({
    required String newName,
    required String newEmail,
    String? currentPassword,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) return "Error: No user logged in.";

    try {
      if (newName != user.displayName && newName.isNotEmpty) {
        await user.updateDisplayName(newName);
      }

      if (newEmail != user.email && newEmail.isNotEmpty) {
        if (currentPassword == null || currentPassword.isEmpty) {
          return "PASSWORD_REQUIRED";
        }

        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);

        await user.verifyBeforeUpdateEmail(newEmail);
        return "Success: Profile updated. A verification link has been sent to your new email.";
      }
      return "Success: Profile updated successfully.";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') return "Error: Incorrect password.";
      return e.message ?? "Failed to update profile.";
    } catch (e) {
      return "Error: ${e.toString()}";
    }
  }

  // 6. CHANGE PASSWORD
  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) return "Error: No user logged in.";

    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      return "Success: Password updated successfully.";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password')
        return "Error: Incorrect current password.";
      return e.message ?? "Failed to update password.";
    } catch (e) {
      return "Error: ${e.toString()}";
    }
  }

  // 7. DELETE ACCOUNT
  Future<String> deleteAccount(String password) async {
    User? user = _auth.currentUser;
    if (user == null) return "Error: No user logged in.";

    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      await user.delete();
      return "Success";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') return "Error: Incorrect password.";
      return e.message ?? "Failed to delete account.";
    } catch (e) {
      return "Error: ${e.toString()}";
    }
  }

  // 8. UPLOAD PROFILE PICTURE (THE IMGBB HACK - 100% FREE)
  Future<String> uploadProfilePicture(XFile imageFile) async {
    User? user = _auth.currentUser;
    if (user == null) return "Error: No user logged in.";

    try {
      // 1. Convert image to Base64
      final Uint8List imgData = await imageFile.readAsBytes();
      String base64Image = base64Encode(imgData);

      // 2. ImgBB API Endpoint (Paste your key here)
      const String imgbbApiKey = "21bfcff544aa6da37124fbc51f896f0d";
      final Uri url = Uri.parse('https://api.imgbb.com/1/upload');

      // 3. Send the image to ImgBB
      final response = await http.post(
        url,
        body: {'key': imgbbApiKey, 'image': base64Image},
      );

      // 4. Parse the response and save the URL to Firebase Auth
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final String liveImageUrl =
            jsonResponse['data']['url']; // The direct image link

        await user.updatePhotoURL(liveImageUrl);
        return "Success";
      } else {
        return "Error: Server rejected the image. Status: ${response.statusCode}";
      }
    } catch (e) {
      return "Error: Failed to upload image. ${e.toString()}";
    }
  }

  // 9. LOGOUT
  Future<void> logOut() async {
    await _auth.signOut();
    if (!kIsWeb) await _googleSignIn.signOut();
  }
}
