import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tow_way_shop/auth/signInWithGoogleService.dart';
import '../admin/admin_products.dart';
import '../customer/products_page.dart';
import '../home_screenPage.dart' show HomeScreen;
import 'Admin_Login.dart';
import 'SignInSerivce.dart';
import 'signUpService.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  final AuthService authService = AuthService();
  final AuthServicesignIn authServicesignIn = AuthServicesignIn();
  final AuthServicesignUp authServicesignUp = AuthServicesignUp();
  final AuthServiceadmin authServicesadmin = AuthServiceadmin();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isAdminLogin = false;
  bool _isLoginMode = true; // true = تسجيل دخول, false = إنشاء حساب

  /// ✅ إضافة متغير لتحديد ألوان الوضع الحالي
  Color get _primaryColor => _isAdminLogin ? Colors.deepPurple : Colors.blue;
  Color get _secondaryColor => _isAdminLogin ? Colors.deepPurpleAccent : Colors.lightBlue;
  Color get _backgroundColor => _isAdminLogin ? Colors.deepPurple.shade50 : Colors.blue.shade50;

  /// ✅ التصحيح: إصلاح دالة _submit بالكامل
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isAdminLogin) {
        await _handleAdminLogin();
      } else if (_isLoginMode) {
        await _handleSignIn();
      } else {
        await _handleSignUp();
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// ✅ دالة تسجيل دخول المدير
  Future<void> _handleAdminLogin() async {
    bool success = await authServicesadmin.adminLogin(
      emailController.text.trim(),
      passwordController.text,
    );

    if (success && mounted) {
      _showSuccess('تم تسجيل دخول المدير بنجاح');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AdminProductsPage()),
      );
    } else if (mounted) {
      _showError('بيانات الدخول غير صحيحة');
    }
  }

  /// ✅ دالة تسجيل دخول العميل
  Future<void> _handleSignIn() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty) {
      _showError('الرجاء إدخال البريد الإلكتروني');
      return;
    }
    if (password.isEmpty) {
      _showError('الرجاء إدخال كلمة المرور');
      return;
    }
    setState(() => _isLoading = true);

    final result = await authServicesignIn.signIn(email, password);

    setState(() => _isLoading = false);

    if (result['success'] == true && mounted) {
      _showSuccess(result['message']);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ProductsScreen()),
      );
    } else if (mounted) {
      _showError(result['message']);
    }
  }
  Future<void> _handleSignUp() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    if (email.isEmpty) {
      _showError('الرجاء إدخال البريد الإلكتروني');
      return;
    }
    if (password.isEmpty) {
      _showError('الرجاء إدخال كلمة المرور');
      return;
    }
    if (password.length < 6) {
      _showError('كلمة المرور يجب أن تكون 6 أحرف على الأقل');
      return;
    }
    if (password != confirmPassword) {
      _showError('كلمة المرور غير متطابقة مع تأكيد كلمة المرور');
      return;
    }

    setState(() => _isLoading = true);

    final result = await authServicesignUp.signUp(email, password);

    setState(() => _isLoading = false);

    if (result['success'] == true && mounted) {
      _showSuccess(result['message']);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ProductsScreen()),
      );
    } else if (mounted) {
      _showError(result['message']);
    }
  }
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isAdminLogin ? 'تسجيل دخول صاحب العمل' : 'تسجيل دخول العميل',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: _primaryColor,
        centerTitle: true,
        elevation: 4,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isAdminLogin
                ? [Colors.deepPurple, Colors.deepPurpleAccent]
                : [Colors.blue, Colors.lightBlueAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [ //  التبديل بين العميل وصاحب العمل مع تغيير
                      _buildRoleSelector(),
                      SizedBox(height: 30),
                      Icon(
                        _isLoginMode ? Icons.login : Icons.person_add,
                        size: 60,
                        color: Colors.white,
                      ),
                      SizedBox(height: 10),
                      Text(
                        _getTitle(),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 10,
                              color: Colors.black26,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 30),
                      _buildEmailField(),
                      SizedBox(height: 15), // حقل كلمة المرور
                      _buildPasswordField(),
                      SizedBox(height: 15), // حقل تأكيد كلمة المرور
                      if (!_isLoginMode && !_isAdminLogin) ...[
                        _buildConfirmPasswordField(),
                        SizedBox(height: 15),
                      ], // زر الإجراء الرئيسي
                      _buildSubmitButton(),
                      SizedBox(height: 10), // تبديل وضع تسجيل الدخول / إنشاء حساب
                      if (!_isAdminLogin) _buildToggleModeButton(),

                      SizedBox(height: 10), // زر تسجيل الدخول بجوجل
                      if (!_isAdminLogin) _buildGoogleSignInButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildRoleSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isAdminLogin = false;
                  _clearFields();
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isAdminLogin ? Colors.blue : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person,
                      color: !_isAdminLogin ? Colors.white : Colors.grey,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'أنا عميل',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: !_isAdminLogin ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isAdminLogin = true;
                  _clearFields();
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isAdminLogin ? Colors.deepPurple : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.business,
                      color: _isAdminLogin ? Colors.white : Colors.grey,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'صاحب العمل',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _isAdminLogin ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildEmailField() {
    return TextFormField(
      controller: emailController,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: _isAdminLogin ? 'البريد الإلكتروني لصاحب العمل' : 'البريد الإلكتروني',
        hintText: "example@email.com",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        prefixIcon: Icon(Icons.email, color: _primaryColor),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) return 'البريد الإلكتروني مطلوب';
        if (!value.contains('@')) return 'البريد الإلكتروني غير صحيح';
        return null;
      },
    );
  }
  Widget _buildPasswordField() {
    return TextFormField(
      controller: passwordController,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: "كلمة المرور",
        hintText: "********",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        prefixIcon: Icon(Icons.lock, color: _primaryColor),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
      ),
      obscureText: true,
      validator: (value) {
        if (value == null || value.isEmpty) return 'كلمة المرور مطلوبة';
        return null;
      },
    );
  }
  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: confirmPasswordController,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: "تأكيد كلمة المرور",
        hintText: "********",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        prefixIcon: Icon(Icons.lock_outline, color: _primaryColor),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
      ),
      obscureText: true,
      validator: (value) {
        if (value == null || value.isEmpty) return 'تأكيد كلمة المرور مطلوب';
        if (value != passwordController.text) return 'كلمة المرور غير متطابقة';
        return null;
      },
    );
  }
  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _submit,
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 50),
        backgroundColor: _primaryColor,  //  تغيير لون الزر حسب نوع المستخدم
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 3,
      ),
      child: _isLoading
          ? SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      )
          : Text(
        _getButtonText(),
        style: TextStyle(fontSize: 18),
      ),
    );
  }
  Widget _buildToggleModeButton() {
    return TextButton(
      onPressed: () {
        setState(() {
          _isLoginMode = !_isLoginMode;
          _clearFields();
        });
      },
      child: Text(
        _isLoginMode
            ? "ليس لديك حساب؟ إنشاء حساب جديد"
            : "لديك حساب بالفعل؟ تسجيل الدخول",
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }
  Widget _buildGoogleSignInButton() {
    return OutlinedButton(
      onPressed: _isLoading ? null : _handleGoogleSignIn,
      style: OutlinedButton.styleFrom(
        minimumSize: Size(double.infinity, 50),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.g_mobiledata_outlined, size: 24, color: Colors.red),
          SizedBox(width: 10),
          Text("تسجيل الدخول بواسطة Google", style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    final result = await authService.signInWithGoogle();
    setState(() => _isLoading = false);
    if (result['success'] == true && mounted) {
      _showSuccess(result['message']);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } else if (mounted) {
      _showError(result['message']);
    }
  }
  void _clearFields() {
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
  }
  String _getTitle() {
    if (_isAdminLogin) {
      return _isLoginMode ? 'تسجيل دخول صاحب العمل' : 'إنشاء حساب صاحب العمل';
    }
    return _isLoginMode ? 'تسجيل دخول العميل' : 'إنشاء حساب جديد';
  }
  String _getButtonText() {
    if (_isAdminLogin) return 'دخول صاحب العمل';
    return _isLoginMode ? 'تسجيل دخول' : 'إنشاء حساب';
  }
}