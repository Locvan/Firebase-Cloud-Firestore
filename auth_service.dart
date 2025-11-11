import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Thêm clientId cho Web
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: "25142275189-dfldonvm9vodspcvdmgjm6mk32650d9j.apps.googleusercontent.com", // copy từ Google Cloud
  );
  Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print("Error signing in with Google: $e");
      return null;
    }
  }
  Future<User?> signInAnonymously() async {
    final userCredential = await _auth.signInAnonymously();
    return userCredential.user;
  }
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }
  Stream<User?> get userChanges => _auth.userChanges();
}