import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'auth/auth_service.dart';
import 'auth/signInWithGoogleService.dart';
import 'auth/signOutScervice.dart';

class HomeScreen extends StatelessWidget {
  final AuthService authService = AuthService();
  final AuthServiceSignOut authServiceSignOut = AuthServiceSignOut();

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text("الصفحة الرئيسية"),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await authServiceSignOut.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => AuthScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // عرض صورة المستخدم
              CircleAvatar(
                radius: 50,
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: user?.photoURL == null
                    ? Icon(Icons.person, size: 50)
                    : null,
                backgroundColor: Colors.grey[300],
              ),
              SizedBox(height: 20),
              // عرض اسم المستخدم
              Text(
                user?.displayName ?? 'مرحباً بك',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              // عرض البريد الإلكتروني
              Text(
                user?.email ?? 'No email',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 5),
              // عرض حالة التحقق من البريد
              if (user != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: user.emailVerified ? Colors.green[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.emailVerified
                        ? ' البريد الإلكتروني مؤكد'
                        : ' البريد الإلكتروني غير مؤكد',
                    style: TextStyle(
                      fontSize: 12,
                      color: user.emailVerified ? Colors.green[800] : Colors.orange[800],
                    ),
                  ),
                ),
              SizedBox(height: 5),
              // عرض UID
              Text(
                'UID: ${user?.uid ?? 'Unknown'}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              SizedBox(height: 5),
              // عرض تاريخ إنشاء الحساب
              if (user?.metadata.creationTime != null)
                Text(
                  'تاريخ الإنشاء: ${user!.metadata.creationTime!.day}/${user.metadata.creationTime!.month}/${user.metadata.creationTime!.year}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              SizedBox(height: 30),
              // زر تسجيل الخروج
              ElevatedButton.icon(
                onPressed: () async {
                  await authServiceSignOut.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => AuthScreen()),
                  );
                },
                icon: Icon(Icons.logout),
                label: Text("تسجيل خروج"),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(200, 50),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}