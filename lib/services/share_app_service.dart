// lib/services/share_app_service.dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ShareAppService {

  // رابط تحميل التطبيق - غيّره إلى رابطك الحقيقي
  static const String appDownloadLink = 'https://drive.google.com/your-app-link';

  // رابط متجر Google Play (بعد نشر التطبيق)
  static const String googlePlayLink = 'https://play.google.com/store/apps/details?id=com.towwayshop.customer';

  // رابط GitHub (بديل)
  static const String githubLink = 'https://github.com/yourusername/tow-way-shop/releases';

  // رابط Firebase App Distribution
  static const String firebaseDistLink = 'https://appdistribution.firebase.dev/your-app';

  /// مشاركة رابط التطبيق
  static Future<void> shareAppLink(BuildContext context) async {
    try {
      final String message = '''
🔥 حمل تطبيق TowWayShop الآن!

تسوق بسهولة وطلب المنتجات مباشرة من جوالك.

🔗 رابط التحميل: $appDownloadLink

📱 متوافق مع أندرويد
✨ تجربة تسوق ممتعة
🛍️ تشكيلة واسعة من المنتجات

__________________________
TowWayShop - متجرك الموثوق
''';

      await Share.share(message, subject: 'تحميل تطبيق TowWayShop');
    } catch (e) {
      _showError(context, 'حدث خطأ أثناء المشاركة');
    }
  }

  /// مشاركة بدون وصف طويل (سريعة)
  static Future<void> shareQuickLink(BuildContext context) async {
    await Share.share('🔗 حمل تطبيق TowWayShop: $appDownloadLink');
  }

  /// فتح رابط التحميل مباشرة
  static Future<void> openDownloadLink(BuildContext context) async {
    final Uri url = Uri.parse(appDownloadLink);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showError(context, 'لا يمكن فتح الرابط');
    }
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}