import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:private_4t_app/core/widgets/app_header.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class InviteFriendsScreen extends StatefulWidget {
  const InviteFriendsScreen({super.key});

  @override
  State<InviteFriendsScreen> createState() => _InviteFriendsScreenState();
}

class _InviteFriendsScreenState extends State<InviteFriendsScreen> with AnalyticsScreenMixin {
  static  String inviteLink = Platform.isAndroid ? 'https://play.google.com/store/apps/details?id=com.private_4t.app':"https://apps.apple.com/app/private-4t/id123456789";

  // Generate the complete share message
  
  @override
  String get screenName => 'InviteFriendsscreen';
  
  Future<String> _generateShareMessage() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final appName = packageInfo.appName;

    return '''🎓 انضم إليّ في تطبيق $appName!

تطبيق تعليمي متطور يوفر:
📚 دروس فيديو تعليمية عالية الجودة
🎯 حجز دروس خصوصية مع أفضل المعلمين
📖 مكتبة تعليمية شاملة
🎬 مقاطع تعليمية قصيرة (Clips)
💬 تواصل مباشر مع المعلمين

تحميل التطبيق:
📱 Android: https://play.google.com/store/apps/details?id=com.private_4t.app
🍎 iOS: https://apps.apple.com/app/private-4t/id123456789

جرب التطبيق الآن وابدأ رحلتك التعليمية! 🚀''';
  }

  // Copy text to clipboard
  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم نسخ $label بنجاح'),
          backgroundColor: context.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Share via WhatsApp
  Future<void> _shareViaWhatsApp() async {
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
          const SnackBar(
            content: Text('خطأ في فتح واتساب. تأكد من تثبيت التطبيق.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Share via Telegram
  Future<void> _shareViaTelegram() async {
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
          const SnackBar(
            content: Text('خطأ في فتح تيليجرام. تأكد من تثبيت التطبيق.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Share via system share sheet (More option)
  Future<void> _shareViaMore() async {
    try {
      final box = context.findRenderObject() as RenderBox?;
      final message = await _generateShareMessage();

      await SharePlus.instance.share(
        ShareParams(
          text: message,
          subject: 'دعوة لتطبيق Private 4T',
          sharePositionOrigin:
              box != null ? box.localToGlobal(Offset.zero) & box.size : null,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطأ في المشاركة'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.background,
        appBar: const AppHeader(
          title: 'دعوة الأصدقاء',
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
                _buildInviteOptions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.accentSecondary, context.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Icon(Icons.person_add, size: 48.sp, color: Colors.white),
          SizedBox(height: 16.h),
          Text(
            'ادع أصدقاءك وامنح الجميع تجربة تعليمية رائعة',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            'شارك كود الدعوة أو الرابط مع أصدقائك',
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

  Widget _buildInviteOptions() {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // _buildInviteCard(
            //   'كود الدعوة',
            //   inviteCode,
            //   Icons.qr_code,
            //   'انسخ واشارك',
            //   context.primary,
            //   () => _copyToClipboard(inviteCode, 'كود الدعوة'),
            // ),
            // SizedBox(height: 16.h),
            _buildInviteCard(
              'رابط التطبيق',
              inviteLink,
              Icons.link,
              'انسخ الرابط',
              context.accentSecondary,
              () => _copyToClipboard(inviteLink, 'رابط الدعوة'),
            ),
            SizedBox(height: 24.h),
            _buildShareButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteCard(String title, String content, IconData icon,
      String buttonText, Color color, VoidCallback onPressed) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 24.sp, color: color),
              SizedBox(width: 12.w),
              Text(title,
                  style:
                      TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(content,
                style:
                    TextStyle(fontSize: 14.sp, color: context.primaryText)),
          ),
          SizedBox(height: 12.h),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(backgroundColor: color),
            child:
                Text(buttonText, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButtons() {
    return Row(
      children: [
        Expanded(
            child: _buildShareButton(
                'واتساب', Icons.message, context.accent, _shareViaWhatsApp)),
        SizedBox(width: 12.w),
        Expanded(
            child: _buildShareButton('تيليجرام', Icons.send,
                context.accentSecondary, _shareViaTelegram)),
        SizedBox(width: 12.w),
        Expanded(
            child: _buildShareButton(
                'المزيد', Icons.share, context.primary, _shareViaMore)),
      ],
    );
  }

  Widget _buildShareButton(
      String title, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(vertical: 12.h),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20.sp),
          SizedBox(height: 4.h),
          Text(title, style: TextStyle(color: Colors.white, fontSize: 12.sp)),
        ],
      ),
    );
  }
}
