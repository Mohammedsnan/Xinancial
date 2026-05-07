import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();


  User? getCurrentUser() {
    return _auth.currentUser;
  }
  //  تحديث بيانات المستخدم
  Future<void> updateUserProfile({String? name, String? photoURL}) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.updateDisplayName(name);
      await user.updatePhotoURL(photoURL);
      await user.reload();
    }
  }
}