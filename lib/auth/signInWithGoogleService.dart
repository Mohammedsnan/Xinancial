import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return {
          'success': false,
          'user': null,
          'message': ' تم إلغاء تسجيل الدخول',
        };
      }
      final GoogleSignInAuthentication googleAuth = await googleUser
          .authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await _auth.signInWithCredential(
          credential);
      return {
        'success': true,
        'user': userCredential.user,
        'message': ' تم تسجيل الدخول بواسطة Google بنجاح',
      };
    } catch (e) {
      return {
        'success': false,
        'user': null,
        'message': ' حدث خطأ: $e',
      };
    }
  }
}
