import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthServicesignUp {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<Map<String, dynamic>> signUp(String email, String password) async {
    try {// Firebase يقوم تلقائياً بتخزين المستخدم الجديد
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      ); // بعد إنشاء الحساب، يمكنك إضافة بيانات إضافية للمستخدم
      User? user = userCredential.user; //  تحديث اسم المستخدم (اختياري)
      await user?.updateDisplayName(email.split('@')[0]); // اسم من البريد
      await user?.sendEmailVerification();
      return {
        'success': true,
        'user': user,
        'message': ' تم إنشاء الحساب بنجاح! تم إرسال بريد التأكيد.',
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = ' هذا البريد الإلكتروني مسجل بالفعل';
          break;
        case 'weak-password':
          message = ' كلمة المرور ضعيفة (يجب أن تكون 6 أحرف على الأقل)';
          break;
        case 'invalid-email':
          message = ' البريد الإلكتروني غير صالح';
          break;
        case 'operation-not-allowed':
          message = ' خدمة إنشاء الحساب معطلة في Firebase Console';
          break;
        default:
          message = ' حدث خطأ: ${e.message}';
      }
      return {
        'success': false,
        'user': null,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'user': null,
        'message': ' حدث خطأ غير متوقع: $e',
      };
    }
  }
}
