import 'package:shared_preferences/shared_preferences.dart';

class AuthServiceadmin {

  Future<bool> adminLogin(String email, String password) async {
    try {
      // بيانات المدير الثابتة (يمكن تغييرها)
      if (email == "admin@towshop.com" && password == "Admin@123") {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isAdminLoggedIn', true);
        await prefs.setString('userRole', 'admin');
        return true;
      }
      return false;
    } catch (e) {
      print("Admin Login Error: $e");
      return false;
    }
  }
}