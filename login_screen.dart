import 'package:flutter/material.dart';
import '../auth_service.dart';

class LoginScreen extends StatelessWidget {
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.person_outline),
              label: Text('Sign in Anonymously'),
              onPressed: () async {
                final user = await _auth.signInAnonymously();
                if (user != null) {
                  print("Anonymous login success: ${user.uid}");
                }
              },
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.login),
              label: Text('Sign in with Google'),
              onPressed: () async {
                final user = await _auth.signInWithGoogle();
                if (user != null) {
                  print("Google login success: ${user.uid}");
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
