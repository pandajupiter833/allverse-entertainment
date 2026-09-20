import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signUp(
    String email,
    String password,
    String username,
  ) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (userCredential.user != null) {
      await userCredential.user!.updateDisplayName(username.trim());
      await userCredential.user!.reload();
    }
    return _auth.currentUser;
  }

  Future<User?> signIn(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    return userCredential.user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
