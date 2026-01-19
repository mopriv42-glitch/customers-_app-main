import 'dart:io';
import 'dart:ui' as ui;

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:private_4t_app/app_config/api_keys.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/app_config/api_requests.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/core/providers/offline_mode_provider.dart';
import 'package:private_4t_app/core/services/navigation_service.dart';
import 'package:private_4t_app/core/widgets/app_header.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with AnalyticsScreenMixin {
  
  @override
  String get screenName => 'Settingsscreen';
  
  String _selectedLanguage = 'العربية';
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _offlineModeEnabled = false;
  bool _biometricEnabled = false;
  bool _crashReportsEnabled = true;
  bool _syncOnWifiOnly = true;
  bool _autoDownloadEnabled = false;

  final List<String> _languages = ['العربية', 'English'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
      _checkPermissions();
    });
  }

  Future<void> _loadSettings() async {
    // Load settings from shared preferences or storage
    setState(() {
      // Initialize with current locale if available
      _selectedLanguage =
          context.locale.languageCode == 'ar' ? 'العربية' : 'English';

      // Initialize dark mode based on current theme
      _darkModeEnabled = ref.read(ApiProviders.themeProvider) == ThemeMode.dark;

      // Initialize offline mode settings
      final offlineState = ref.read(offlineModeProvider);
      _offlineModeEnabled = offlineState.isOfflineModeEnabled;
      _syncOnWifiOnly = offlineState.syncOnWifiOnly;
      _autoDownloadEnabled = offlineState.autoDownloadEnabled;
    });
  }

  Future<void> _checkPermissions() async {
    // Check current notification permission status
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    setState(() {
      _notificationsEnabled = isAllowed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.background,
        appBar: const AppHeader(title: 'الإعدادات', showBackButton: true),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              _buildConnectionStatus(),
              SizedBox(height: 16.h),
              // _buildAppSettingsSection(),
              // SizedBox(height: 16.h),
              _buildPrivacySection(),
              SizedBox(height: 16.h),
              _buildAccountSection(),
              SizedBox(height: 16.h),
              _buildSupportSection(),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Consumer(
      builder: (context, ref, child) {
        final offlineState = ref.watch(offlineModeProvider);

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: offlineState.connectionStatusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: offlineState.connectionStatusColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                offlineState.isConnected
                    ? (offlineState.isWifiConnected
                        ? Icons.wifi
                        : Icons.signal_cellular_4_bar)
                    : Icons.wifi_off,
                color: offlineState.connectionStatusColor,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'حالة الاتصال',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: context.primary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      offlineState.connectionStatus,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: offlineState.connectionStatusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (offlineState.isOfflineModeEnabled)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'وضع غير متصل',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppSettingsSection() {
    return _buildSection('إعدادات التطبيق', [
      // if (!Platform.isIOS)
      //   _buildSettingItem(
      //     'اللغة',
      //     _selectedLanguage,
      //     Icons.language,
      //     onTap: () => _showLanguageDialog(),
      //   ),
      _buildSwitchItem(
        'الوضع الليلي',
        _darkModeEnabled,
        Icons.dark_mode,
        onChanged: (value) => _toggleDarkMode(value),
      ),
      // _buildSwitchItem(
      //   'الوضع غير المتصل',
      //   _offlineModeEnabled,
      //   Icons.offline_bolt,
      //   onChanged: (value) => _toggleOfflineMode(value),
      // ),
      if (_offlineModeEnabled) ...[
        _buildSwitchItem(
          'المزامنة عبر WiFi فقط',
          _syncOnWifiOnly,
          Icons.wifi,
          onChanged: (value) => _toggleSyncOnWifiOnly(value),
        ),
        _buildSwitchItem(
          'التحميل التلقائي',
          _autoDownloadEnabled,
          Icons.download,
          onChanged: (value) => _toggleAutoDownload(value),
        ),
        _buildSettingItem(
          'مزامنة يدوية',
          'اضغط للمزامنة الآن',
          Icons.sync,
          onTap: () => _manualSync(),
        ),
      ],
    ]);
  }

  Widget _buildNotificationSection() {
    return _buildSection('إعدادات الإشعارات', [
      _buildSwitchItem(
        'الإشعارات',
        _notificationsEnabled,
        Icons.notifications,
        onChanged: (value) => _toggleNotifications(value),
      ),
      _buildSwitchItem(
        'الصوت',
        _soundEnabled,
        Icons.volume_up,
        onChanged: (value) {
          setState(() {
            _soundEnabled = value;
          });
        },
      ),
      _buildSwitchItem(
        'الاهتزاز',
        _vibrationEnabled,
        Icons.vibration,
        onChanged: (value) {
          setState(() {
            _vibrationEnabled = value;
          });
        },
      ),
      _buildSettingItem(
        'إعدادات الإشعارات المتقدمة',
        'إدارة أنواع الإشعارات',
        Icons.tune,
        onTap: () => _showAdvancedNotificationSettings(),
      ),
    ]);
  }

  Widget _buildPrivacySection() {
    return _buildSection('الخصوصية والأمان', [
      _buildSwitchItem(
        'تقارير الأخطاء',
        _crashReportsEnabled,
        Icons.bug_report,
        onChanged: (value) {
          setState(() {
            _crashReportsEnabled = value;
          });
        },
      ),
      _buildSettingItem(
        'سياسة الخصوصية',
        'عرض سياسة الخصوصية',
        Icons.privacy_tip,
        onTap: () => _showPrivacyPolicy(),
      ),
      _buildSettingItem(
        'شروط الاستخدام',
        'عرض الشروط والأحكام',
        Icons.article,
        onTap: () => _showTermsOfService(),
      ),
    ]);
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.secondary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: context.primaryText,
            ),
          ),
          SizedBox(height: 16.h),
          ...children.expand(
            (child) => [
              child,
              if (child != children.last)
                Divider(
                  height: 24.h,
                  color: context.secondary.withValues(alpha: 0.3),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Settings functionality methods
  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      // Request notification permission
      bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (!isAllowed) {
        await AwesomeNotifications().requestPermissionToSendNotifications();
        isAllowed = await AwesomeNotifications().isNotificationAllowed();
      }

      setState(() {
        _notificationsEnabled = isAllowed;
      });

      if (isAllowed) {
        _showSnackBar('تم تفعيل الإشعارات');
      } else {
        _showSnackBar('يرجى السماح بالإشعارات من إعدادات النظام');
      }
    } else {
      setState(() {
        _notificationsEnabled = false;
      });
      _showSnackBar('تم إلغاء الإشعارات');
    }
  }

  void _toggleDarkMode(bool value) {
    setState(() {
      _darkModeEnabled = value;
    });

    // Use Theme Provider to change theme
    final themeNotifier = ref.read(ApiProviders.themeProvider.notifier);
    themeNotifier.setTheme(value ? ThemeMode.dark : ThemeMode.light);

    _showSnackBar(
      value ? 'تم تفعيل الوضع الليلي 🌙' : 'تم إلغاء الوضع الليلي ☀️',
    );
  }

  void _toggleOfflineMode(bool value) {
    setState(() {
      _offlineModeEnabled = value;
    });

    // Use Offline Mode Provider
    ref.read(offlineModeProvider.notifier).setOfflineMode(value);

    _showSnackBar(
      value ? 'تم تفعيل الوضع غير المتصل 📴' : 'تم إلغاء الوضع غير المتصل 📶',
    );
  }

  void _toggleSyncOnWifiOnly(bool value) {
    setState(() {
      _syncOnWifiOnly = value;
    });

    ref.read(offlineModeProvider.notifier).setSyncOnWifiOnly(value);

    _showSnackBar(
      value ? 'سيتم المزامنة عبر WiFi فقط 📶' : 'سيتم المزامنة عبر أي اتصال 📡',
    );
  }

  void _toggleAutoDownload(bool value) {
    setState(() {
      _autoDownloadEnabled = value;
    });

    ref.read(offlineModeProvider.notifier).setAutoDownload(value);

    _showSnackBar(
      value ? 'تم تفعيل التحميل التلقائي ⬇️' : 'تم إلغاء التحميل التلقائي',
    );
  }

  void _manualSync() {
    ref.read(offlineModeProvider.notifier).manualSync();
    _showSnackBar('تم بدء المزامنة اليدوية 🔄');
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Check if biometric is available
      bool isBiometricAvailable =
          await Permission.microphone.isGranted; // Placeholder
      if (isBiometricAvailable) {
        setState(() {
          _biometricEnabled = true;
        });
        _showSnackBar('تم تفعيل المصادقة البيومترية');
      } else {
        _showSnackBar('المصادقة البيومترية غير متاحة على هذا الجهاز');
      }
    } else {
      setState(() {
        _biometricEnabled = false;
      });
      _showSnackBar('تم إلغاء المصادقة البيومترية');
    }
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر اللغة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _languages.map((language) {
            return RadioListTile<String>(
              title: Text(language),
              value: language,
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });

                _changeLanguage(value!);

                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  void _changeLanguage(String language) {
    if (language == 'العربية') {
      context.setLocale(const Locale('ar'));
    } else {
      context.setLocale(const Locale('en'));
    }
    _showSnackBar('تم تغيير اللغة إلى $language');
  }

  void _showAdvancedNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعدادات الإشعارات المتقدمة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('يمكنك إدارة أنواع الإشعارات التالية:'),
            const SizedBox(height: 16),
            _buildNotificationTypeItem('إشعارات الكورسات الجديدة', true),
            _buildNotificationTypeItem('إشعارات التحديثات', true),
            _buildNotificationTypeItem('إشعارات المواعيد', false),
            _buildNotificationTypeItem('إشعارات النظام', true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTypeItem(String title, bool enabled) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(title)),
        Switch(
          value: enabled,
          onChanged: (value) {
            // Handle notification type toggle
          },
        ),
      ],
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

  void _showTermsOfService() async {
    const String termsUrl = 'https://private-4t.com/terms';
    final Uri uri = Uri.parse(termsUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar('لا يمكن فتح الرابط');
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

  Widget _buildAccountSection() {
    return _buildSection('إدارة الحساب', [
      // _buildSettingItem(
      //   'تغيير كلمة المرور',
      //   'تحديث كلمة المرور',
      //   Icons.lock,
      //   onTap: () => _showChangePassword(),
      // ),
      _buildSettingItem(
        'تسجيل الخروج',
        'الخروج من التطبيق',
        Icons.logout,
        onTap: () => _showLogoutDialog(),
        textColor: context.error,
      ),
      _buildSettingItem(
        'حذف الحساب',
        'حذف الحساب نهائياً',
        Icons.delete_forever,
        onTap: () => _showDeleteAccountDialog(),
        textColor: context.error,
      ),
    ]);
  }

  Widget _buildSupportSection() {
    return _buildSection('الدعم والمساعدة', [
      _buildSettingItem(
        'تواصل معنا',
        'إرسال رسالة للدعم',
        Icons.support_agent,
        onTap: () => _showContactSupport(),
      ),
      _buildSettingItem(
        'الأسئلة الشائعة',
        'إجابات للأسئلة المتكررة',
        Icons.help,
        onTap: () => _showFAQ(),
      ),
      _buildSettingItem(
        'إبلاغ عن مشكلة',
        'أرسل تقرير عن خطأ',
        Icons.bug_report,
        onTap: () => _reportBug(),
      ),
      _buildSettingItem(
        'تقييم التطبيق',
        'ساعدنا بتقييمك',
        Icons.star_rate,
        onTap: () => _rateApp(),
      ),
      _buildSettingItem(
        'حول التطبيق',
        'معلومات الإصدار والتطبيق',
        Icons.info,
        onTap: () => _showAboutApp(),
      ),
    ]);
  }

  Widget _buildSettingItem(
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? context.secondary),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: textColor ?? context.primaryText,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 14.sp, color: context.secondaryText),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16.sp,
        color: context.secondary,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchItem(
    String title,
    bool value,
    IconData icon, {
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: context.secondary),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: context.primaryText,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: context.primary,
      ),
    );
  }

  void _showChangePassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغيير كلمة المرور'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'كلمة المرور الحالية',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.h),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'كلمة المرور الجديدة',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.h),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'تأكيد كلمة المرور الجديدة',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم تغيير كلمة المرور بنجاح'),
                  backgroundColor: context.success,
                ),
              );
            },
            child: Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref
                  .read(ApiProviders.loginProvider)
                  .userLogout(context: context);

              if (context.mounted) {
                Navigator.pop(context);
                context.go('/welcome');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: context.error),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الحساب'),
        content: Column(
          children: [
            Text(
              'هل أنت متأكد من حذف الحساب؟ هذا الإجراء لا يمكن التراجع عنه.',
              style: TextStyle(fontSize: 14.sp, color: context.secondaryText),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: noteController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'اكتب سبب الحذف هنا...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(
                    color: context.secondary.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: context.border, width: 2),
                ),
                contentPadding: EdgeInsets.all(12.r),
              ),
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
              final note = noteController.text.trim();
              if (note.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('يرجى كتابة سبب الحذف'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              await ref.read(ApiProviders.loginProvider).deleteAccount(
                    context: context,
                    notes: noteController.text.toString(),
                  );
            },
            style: ElevatedButton.styleFrom(backgroundColor: context.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  // Additional methods for support section
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
      builder: (context) => AlertDialog(
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
    const String appStoreUrl = 'https://apps.apple.com/app/private-4t';
    const String playStoreUrl =
        'https://play.google.com/store/apps/details?id=com.private_4t.app';

    try {
      Uri uri;
      if (Theme.of(context).platform == TargetPlatform.iOS) {
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

  Future<void> _showContactSupport() async {
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
    }
  }
}
