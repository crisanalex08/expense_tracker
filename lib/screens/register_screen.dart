import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/snackbar_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  final auth = AuthService();

  void showMessage(String message, {required bool success}) {
    SnackbarService.showMessage(context, message, success: success);
  }

  void register() async {
    try {
      await auth.register(emailCtrl.text, passCtrl.text);
      Navigator.pop(context);
    } catch (e) {
      showMessage("Registration failed", success: false);
    }
  }

  void signInWithGoogle() async {
    try {
      await auth.signInWithGoogle();
      // On success, authStateChanges will navigate away; close this screen if mounted.
      if (mounted) Navigator.pop(context);
    } catch (e) {
      showMessage("Google sign-in failed", success: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Register", style: TextStyle(fontSize: 28)),

            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: "Email"),
            ),

            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: register,
              child: const Text("Register"),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: signInWithGoogle,
              icon: const Icon(Icons.login),
              label: const Text('Register with Google'),
            ),
          ],
        ),
      ),
    );
  }
}