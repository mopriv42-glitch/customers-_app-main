import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:private_4t_app/app_config/api_keys.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/app_config/api_requests.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/core/services/navigation_service.dart';
import 'package:private_4t_app/core/widgets/app_header.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class HelpSupportScreen extends ConsumerStatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  ConsumerState<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends ConsumerState<HelpSupportScreen> with AnalyticsScreenMixin {
  
  @override
  String get screenName => 'HelpSupportscreen';
  
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.background,
        appBar: const AppHeader(
          title: 'مساعدة ودعم',
          showBackButton: true,
          showLogo: false,
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                SizedBox(height: 24.h),
                _buildHelpOptions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.secondary, context.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Icon(Icons.help_outline, size: 32.sp, color: Colors.white),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'كيف يمكننا مساعدتك؟',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'نحن هنا للإجابة على أسئلتك',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpOptions(BuildContext context) {
    return Expanded(
      child: ListView(
        children: [
          _buildHelpOption(
            context,
            'الأسئلة الشائعة',
            'إجابات للأسئلة الأكثر شيوعاً',
            Icons.quiz,
            context.primary,
            onTap: _showFAQ,
          ),
          // _buildHelpOption(
          //   context,
          //   'تواصل معنا',
          //   'تواصل مع فريق الدعم الفني',
          //   Icons.message,
          //   context.accentSecondary,
          // ),
          _buildHelpOption(
            context,
            _isLoading ? 'جاري الاتصال...' : 'تواصل مع الإدارة',
            _isLoading
                ? 'جاري البحث عن غرفة المساعدة'
                : 'تواصل مباشر مع الإدارة عبر Matrix',
            _isLoading ? Icons.hourglass_empty : Icons.admin_panel_settings,
            _isLoading ? Colors.grey : context.primary,
            onTap: _isLoading ? null : _contactAdmin,
          ),
          // _buildHelpOption(
          //   context,
          //   'دليل المستخدم',
          //   'تعلم كيفية استخدام التطبيق',
          //   Icons.book,
          //   context.accent,
          // ),
          _buildHelpOption(
            context,
            'الإبلاغ عن مشكلة',
            'أبلغنا عن أي مشكلة تواجهها',
            Icons.bug_report,
            context.secondary,
            onTap: _reportBug,
          ),
          _buildHelpOption(
            context,
            'تقييم التطبيق',
            'شاركنا رأيك وقيم التطبيق',
            Icons.star,
            context.accent,
            onTap: _rateApp,
          ),
          _buildHelpOption(
            context,
            'معلومات التطبيق',
            'الإصدار والتحديثات الجديدة',
            Icons.info,
            context.primary,
            onTap: _showAboutApp,
          ),
        ],
      ),
    );
  }

  void _showAboutApp() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info, color: context.primary),
            const SizedBox(width: 8),
            const Text('حول التطبيق'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAboutItem('اسم التطبيق', packageInfo.appName),
            _buildAboutItem(
              'الإصدار',
              '${packageInfo.version} (${packageInfo.buildNumber})',
            ),
            _buildAboutItem('النظام', Theme.of(context).platform.name),
            _buildAboutItem(
              'تاريخ البناء',
              DateTime.now().toString().split(' ')[0],
            ),
            const SizedBox(height: 16),
            const Text(
              'Private 4T - منصة تعليمية شاملة',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'نوفر لك أفضل تجربة تعليمية مع دروس تفاعلية ومحتوى عالي الجودة.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showPrivacyPolicy();
            },
            child: const Text('سياسة الخصوصية'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() async {
    const String privacyUrl = 'https://private-4t.com/privacy';
    final Uri uri = Uri.parse(privacyUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar('لا يمكن فتح الرابط');
    }
  }

  Widget _buildAboutItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  void _showFAQ() async {
    const String termsUrl = 'https://private-4t.com/faq';
    final Uri uri = Uri.parse(termsUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar('لا يمكن فتح الرابط');
    }
  }

  void _reportBug() {
    final bugController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('إبلاغ عن مشكلة'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('صف المشكلة التي واجهتها:'),
                SizedBox(height: 16.h),
                TextField(
                  controller: bugController,
                  decoration: const InputDecoration(
                    hintText: 'أكتب وصف المشكلة هنا...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final bug = bugController.text.trim();
                  if (bug.isEmpty) {
                    _showSnackBar("يجب كتابة المشكلة قبل ارسالها");
                    return;
                  }

                  await ref
                      .read(ApiProviders.settingProvider)
                      .reportBug(context: context, bug: bug);

                  if (context.mounted) {
                    Navigator.pop(context);
                    _showSnackBar('تم إرسال المشكلة بنجاح');
                  }
                },
                child: const Text('إرسال'),
              ),
            ],
          ),
    );
  }

  void _rateApp() async {
    // Try to open app store for rating
    const String appStoreUrl =
        'https://apps.apple.com/app/private-4t/id6596749497';
    const String playStoreUrl =
        'https://play.google.com/store/apps/details?id=com.private_4t.app';

    try {
      Uri uri;
      if (Theme
          .of(context)
          .platform == TargetPlatform.iOS) {
        uri = Uri.parse(appStoreUrl);
      } else {
        uri = Uri.parse(playStoreUrl);
      }

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('لا يمكن فتح متجر التطبيقات');
      }
    } catch (e) {
      _showSnackBar('خطأ في فتح متجر التطبيقات');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: context.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildHelpOption(BuildContext context, String title,
      String description, IconData icon, Color color,
      {VoidCallback? onTap}) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: onTap ?? () {},
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
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
              if (onTap != null && onTap == _contactAdmin && _isLoading)
                SizedBox(
                  width: 16.sp,
                  height: 16.sp,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(context.primary),
                  ),
                )
              else
                Icon(Icons.arrow_forward_ios,
                    size: 16.sp, color: context.secondary),
            ],
          ),
        ),
      ),
    );
  }

  /// Contact admin via Matrix help room
  Future<void> _contactAdmin() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get user token for authentication
      final token = await CommonComponents.getSavedData(ApiKeys.userToken);
      if (token == null) {
        if (mounted) {
          CommonComponents.showCustomizedSnackBar(
            context: context,
            title: 'يرجى تسجيل الدخول أولاً',
          );
        }
        return;
      }

      // Make API request to get Matrix help room ID
      final response = await ApiRequests.postApiRequest(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: 'me/matrix/help-room',
        headers: {
          'Authorization': 'Bearer $token',
        },
        body: {},
        showLoadingWidget: false, // We're handling loading state manually
      );

      if (response != null &&
          response['data'] != null &&
          response['data']['room_id'] != null) {
        final roomId = response['data']['room_id'];

        if (mounted) {
          // Navigate to Matrix room timeline
          NavigationService.navigateToRoomTimeline(context, roomId);
        }
      } else {
        if (mounted) {
          CommonComponents.showCustomizedSnackBar(
            context: context,
            title: 'لم يتم العثور على غرفة المساعدة',
          );
        }
      }
    } catch (e) {
      debugPrint('Error getting Matrix help room: $e');
      if (mounted) {
        CommonComponents.showCustomizedSnackBar(
          context: context,
          title: 'حدث خطأ أثناء الاتصال بالإدارة',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
