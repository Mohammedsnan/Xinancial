import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthServicesignIn {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<Map<String, dynamic>> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return {
        'success': true,
        'user': userCredential.user,
        'message': ' تم تسجيل الدخول بنجاح',
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = ' لا يوجد مستخدم مسجل بهذا البريد';
          break;
        case 'wrong-password':
          message = ' كلمة المرور غير صحيحة';
          break;
        case 'invalid-email':
          message = ' البريد الإلكتروني غير صالح';
          break;
        default:
          message = ' حدث خطأ: ${e.message}';
      }
      return {
        'success': false,
        'user': null,
        'message': message,
      };
    }
  }

}
