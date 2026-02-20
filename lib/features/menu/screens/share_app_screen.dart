import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:private_4t_app/core/widgets/app_header.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class ShareAppScreen extends StatefulWidget {
  const ShareAppScreen({super.key});

  @override
  State<ShareAppScreen> createState() => _ShareAppScreenState();
}

class _ShareAppScreenState extends State<ShareAppScreen> with AnalyticsScreenMixin {
  // Generate the complete share message
  
  @override
  String get screenName => 'ShareAppscreen';
  
  Future<String> _generateShareMessage() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final appName = packageInfo.appName;

    return '''🎓 $appName - تطبيق التعلم الذكي

تطبيق تعليمي متطور يوفر:
📚 دروس فيديو تعليمية عالية الجودة
🎯 حجز دروس خصوصية مع أفضل المعلمين
📖 مكتبة تعليمية شاملة ومتنوعة
🎬 مقاطع تعليمية قصيرة (Clips)
💬 تواصل مباشر مع المعلمين والطلاب

📱 تحميل التطبيق:
• Android: https://play.google.com/store/apps/details?id=com.private_4t.app
• iOS: https://apps.apple.com/app/private-4t/id6596749497

🚀 ابدأ رحلتك التعليمية معنا الآن!''';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.background,
        appBar: const AppHeader(
          title: 'مشاركة التطبيق',
          showBackButton: true,
          showLogo: false,
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(height: 24.h),
                _buildShareOptions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.accent, context.accentSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Icon(Icons.share, size: 48.sp, color: Colors.white),
          SizedBox(height: 16.h),
          Text(
            'شارك تطبيق Private 4T',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            'ساعد أصدقاءك في الحصول على تعليم أفضل',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildShareOptions(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildShareButton(
              'مشاركة عامة',
              'شارك التطبيق مع جميع جهات الاتصال',
              Icons.share,
              context.primary,
              () => _shareApp(context),
            ),
            SizedBox(height: 16.h),
            _buildShareButton(
              'واتساب',
              'مشاركة عبر تطبيق الواتساب',
              Icons.message,
              context.accent,
              () => _shareToWhatsApp(context),
            ),
            SizedBox(height: 16.h),
            _buildShareButton(
              'تيليجرام',
              'مشاركة عبر تطبيق التيليجرام',
              Icons.send,
              context.accentSecondary,
              () => _shareToTelegram(context),
            ),
            SizedBox(height: 16.h),
            _buildShareButton(
              'نسخ الرابط',
              'انسخ رابط التطبيق للمشاركة',
              Icons.copy,
              context.secondary,
              () => _copyLink(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareButton(String title, String description, IconData icon,
      Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, size: 24.sp, color: color),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 16.sp, fontWeight: FontWeight.w600)),
                  SizedBox(height: 4.h),
                  Text(description,
                      style: TextStyle(
                          fontSize: 14.sp, color: context.secondary)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16.sp, color: context.secondary),
          ],
        ),
      ),
    );
  }

  Future<void> _shareApp(BuildContext context) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final appName = packageInfo.appName;
    final appVersion = packageInfo.version;

    final shareText = '''$appName v$appVersion

تطبيق تعليمي متطور يوفر:
• دروس فيديو تعليمية
• حجز دروس خصوصية
• مكتبة تعليمية شاملة
• محتوى تعليمي عالي الجودة

موقع الويب: https://private-4t.com

تحميل التطبيق:
• Android: https://play.google.com/store/apps/details?id=com.private_4t.app
• iOS: https://apps.apple.com/app/private-4t/id123456789

جرب التطبيق الآن!''';

    await SharePlus.instance.share(ShareParams(text: shareText));
  }

  Future<void> _shareToWhatsApp(BuildContext context) async {
    try {
      final message = await _generateShareMessage();
      final encodedMessage = Uri.encodeComponent(message);
      final whatsappUrl = 'whatsapp://send?text=$encodedMessage';

      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl));
      } else {
        // Fallback to web WhatsApp
        final webWhatsApp = 'https://wa.me/?text=$encodedMessage';
        await launchUrl(Uri.parse(webWhatsApp),
            mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('خطأ في فتح واتساب. تأكد من تثبيت التطبيق.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'مشاركة عامة',
              textColor: Colors.white,
              onPressed: () => _shareApp(context),
            ),
          ),
        );
      }
    }
  }

  Future<void> _shareToTelegram(BuildContext context) async {
    try {
      final message = await _generateShareMessage();
      final encodedMessage = Uri.encodeComponent(message);
      final telegramUrl = 'tg://msg?text=$encodedMessage';

      if (await canLaunchUrl(Uri.parse(telegramUrl))) {
        await launchUrl(Uri.parse(telegramUrl));
      } else {
        // Fallback to web Telegram
        final webTelegram = 'https://t.me/share/url?text=$encodedMessage';
        await launchUrl(Uri.parse(webTelegram),
            mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('خطأ في فتح تيليجرام. تأكد من تثبيت التطبيق.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'مشاركة عامة',
              textColor: Colors.white,
              onPressed: () => _shareApp(context),
            ),
          ),
        );
      }
    }
  }

  Future<void> _copyLink(BuildContext context) async {
    try {
      const appLink = 'https://private-4t.com';
      await Clipboard.setData(const ClipboardData(text: appLink));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم نسخ رابط التطبيق بنجاح'),
            backgroundColor: context.primary,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'مشاركة',
              textColor: Colors.white,
              onPressed: () => _shareApp(context),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطأ في نسخ الرابط'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
