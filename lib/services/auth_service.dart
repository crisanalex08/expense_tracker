import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  GoogleSignIn _googleSignIn() {
    return GoogleSignIn(
      scopes: const ['email'],
    );
  }

  Never _throwGoogleSignInConfigError(Object error) {
    throw StateError(
      'Google Sign-In is not configured for this Android app. '
      'Check that Firebase Authentication has Google enabled, '
      'the Android app SHA-1 is registered, and the app has a '
      'valid web client ID in google-services.json.',
    );
  }

  Future<User?> register(String email, String password) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  Future<User?> login(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Stream<User?> get userStream => _auth.authStateChanges();

  /// Sign in with Google and return the Firebase [UserCredential].
  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser;
    try {
      googleUser = await _googleSignIn().signIn();
    } on PlatformException catch (error) {
      if (error.code == 'channel-error') {
        _throwGoogleSignInConfigError(error);
      }
      rethrow;
    }

    if (googleUser == null) return null; // user aborted

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await _auth.signInWithCredential(credential);
  }

  /// Link the current signed-in user with a Google account.
  /// Throws FirebaseAuthException on failure.
  Future<UserCredential?> linkWithGoogle() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw FirebaseAuthException(code: 'no-current-user', message: 'No signed-in user to link.');

    final GoogleSignInAccount? googleUser;
    try {
      googleUser = await _googleSignIn().signIn();
    } on PlatformException catch (error) {
      if (error.code == 'channel-error') {
        _throwGoogleSignInConfigError(error);
      }
      rethrow;
    }

    if (googleUser == null) return null; // user aborted

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await currentUser.linkWithCredential(credential);
  }

  /// Unlink Google provider from the current user.
  Future<User?> unlinkGoogle() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    await currentUser.unlink('google.com');
    // Refresh user
    await currentUser.reload();
    return _auth.currentUser;
  }
}