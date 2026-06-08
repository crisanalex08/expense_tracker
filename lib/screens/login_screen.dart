import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import '../services/snackbar_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  final auth = AuthService();

  void login() async {
      try {
        await auth.login(emailCtrl.text, passCtrl.text);
        SnackbarService.showMessage(context, "Login successful", success: true);
      } catch (e) {
        SnackbarService.showMessage(context, "Login failed", success: false);
      }
  }

    void signInWithGoogle() async {
    try {
      await auth.signInWithGoogle();
    } catch (e) {
      SnackbarService.showMessage(context, "Google sign-in failed", success: false);
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
            const Text("Login", style: TextStyle(fontSize: 28)),

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
              onPressed: login,
              child: const Text("Login"),
            ),

            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: signInWithGoogle,
              icon: const Icon(Icons.login),
              label: const Text('Sign in with Google'),
            ),

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RegisterScreen(),
                  ),
                );
              },
              child: const Text("Create account"),
            ),
          ],
        ),
      ),
    );
  }
}