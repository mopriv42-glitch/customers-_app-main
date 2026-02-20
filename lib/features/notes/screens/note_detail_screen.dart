import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/models/lib_item_model.dart';
import 'package:private_4t_app/core/services/download_service.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class NoteDetailScreen extends ConsumerStatefulWidget {
  final String itemId;

  const NoteDetailScreen({
    super.key,
    required this.itemId,
  });

  @override
  ConsumerState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends ConsumerState<NoteDetailScreen>
    with TickerProviderStateMixin , AnalyticsScreenMixin {
  
  @override
  String get screenName => 'NoteDetailscreen';
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _commentController = TextEditingController();
  LibItemModel? _itemModel;
  List<String> _comments = [];
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ApiProviders.libraryProvider).getItem(context, widget.itemId);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _handleDownload() async {
    final fileName = _itemModel?.name;
    final fileUrl = _itemModel?.file?.url ?? '';

    if (fileUrl.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يمكن تحميل الملف - رابط غير صحيح'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (fileName == null || fileName.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يمكن تحميل الملف - اسم غير صحيح'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    setState(() => _isDownloading = true);

    try {
      // Download file with proper downloads folder integration
      final savedPath =
          await DownloadService.downloadFileWithNotification(fileUrl, fileName);

      setState(() => _isDownloading = false);

      if (savedPath != null && mounted) {
        // Extract just the file name from the full path for display
        final displayFileName = savedPath.split('/').last;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تم التحميل بنجاح! ✅',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('الملف: $displayFileName'),
                const Text('📁 تم حفظه في مجلد التحميل'),
              ],
            ),
            backgroundColor: const Color(0xFF28A745),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'عرض الملف',
              textColor: Colors.white,
              onPressed: () {
                // Option to open file manager or show file
                _showFileLocation(savedPath);
              },
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل في تحميل الملف. تحقق من الاتصال والأذونات'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() => _isDownloading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في التحميل: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showFileLocation(String filePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.folder, color: context.primary),
              SizedBox(width: 8.w),
              Text('موقع الملف', style: TextStyle(fontSize: 16.sp)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'تم حفظ الملف في:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SelectableText(
                  filePath,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '💡 يمكنك العثور على الملف في تطبيق "ملفاتي" أو "Files" في مجلد التحميل',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Try to open file manager (basic implementation)
                _openFileManager();
              },
              child: const Text('فتح مدير الملفات'),
            ),
          ],
        );
      },
    );
  }

  void _openFileManager() async {
    try {
      // Try to open file manager app
      const String fileManagerPackage = 'com.android.documentsui';
      final Uri fileManagerUri = Uri.parse('package:$fileManagerPackage');

      if (await canLaunchUrl(fileManagerUri)) {
        await launchUrl(fileManagerUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback - open Downloads folder in browser
        const String downloadsUri = 'content://downloads/';
        final Uri uri = Uri.parse(downloadsUri);

        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'لا يمكن فتح مدير الملفات. ابحث عن الملف في مجلد التحميل يدوياً'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يمكن فتح مدير الملفات'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(ApiProviders.libraryProvider);
    bool isLoading = provider.isLoading;

    if (!isLoading && provider.libItemModel != null) {
      _itemModel = provider.libItemModel!;
      _comments = provider.libItemModel!.comments!.map((c) => c.body).toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6D9), // Brand background
      body: SafeArea(
        child: isLoading
            ? CommonComponents.loadingDataFromServer()
            : SingleChildScrollView(
                child: Column(
                  children: [
                    // Header with action buttons
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () => context.pop(),
                                icon: Icon(
                                  Icons.arrow_back_ios,
                                  color: const Color(0xFF482099),
                                  size: 20.sp,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '${_itemModel?.name.toString()}',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF482099),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: _handleDownload,
                                    icon: _isDownloading
                                        ? SizedBox(
                                            width: 20.w,
                                            height: 20.h,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.w,
                                              valueColor:
                                                  const AlwaysStoppedAnimation<
                                                      Color>(
                                                Color(0xFF482099),
                                              ),
                                            ),
                                          )
                                        : Icon(
                                            Icons.download,
                                            color: const Color(0xFF482099),
                                            size: 20.sp,
                                          ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Document Content
                    SizedBox(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: _itemModel?.file?.url != null &&
                              _itemModel!.file!.url.isNotEmpty
                          ? SfPdfViewer.network(
                              _itemModel?.file?.url.toString() ?? '',
                            )
                          // WebView(
                          //   url:
                          //   'https://docs.google.com/gview?embedded=true&url=${_itemModel?.file?.url.toString() ?? 'https://www.orimi.com/pdf-test.pdf'}',
                          //   fileName: _itemModel?.file?.fileName.toString() ??
                          //       _itemModel?.name.toString() ??
                          //       '',
                          // )
                          : const Placeholder(),
                    ),
                    // Download and Share Section
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Download Button
                              SizedBox(
                                width: double.infinity,
                                height: 48.h,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _isDownloading ? null : _handleDownload,
                                  icon: _isDownloading
                                      ? SizedBox(
                                          width: 20.w,
                                          height: 20.h,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.w,
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                    Color>(Colors.white),
                                          ),
                                        )
                                      : const Icon(Icons.download,
                                          color: Colors.white),
                                  label: Text(
                                    _isDownloading
                                        ? 'جاري التحميل...'
                                        : 'تحميل الملف',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF482099),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 16.h),
                              // Share Section
                              Row(
                                children: [
                                  Text(
                                    'مشاركة',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF482099),
                                    ),
                                  ),
                                  const Spacer(),
                                  _buildShareButton(
                                      Icons.send, Colors.blue, 'Telegram'),
                                  SizedBox(width: 12.w),
                                  _buildShareButton(
                                      Icons.whatshot, Colors.green, 'WhatsApp'),
                                  SizedBox(width: 12.w),
                                ],
                              ),
                              SizedBox(height: 16.h),
                              // Comments Section
                              // Comment Input
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _commentController,
                                      decoration: InputDecoration(
                                        hintText: 'أضف تعليقاً ... *',
                                        hintStyle: TextStyle(
                                          fontSize: 14.sp,
                                          color: const Color(0xFF8C6042)
                                              .withOpacity(0.6),
                                        ),
                                        filled: true,
                                        fillColor: const Color(0xFFF9F6D9),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12.r),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16.w,
                                          vertical: 12.h,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Container(
                                    height: 48.h,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF8C6042),
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: IconButton(
                                      onPressed: () async {
                                        if (_commentController
                                            .text.isNotEmpty) {
                                          // Handle comment submissio
                                          final result = await ref
                                              .read(
                                                  ApiProviders.libraryProvider)
                                              .addComment(
                                                context: context,
                                                comment: _commentController.text
                                                    .toString(),
                                              );

                                          if (result) {
                                            var newComments = _comments;
                                            newComments.add(
                                              _commentController.text
                                                  .toString(),
                                            );
                                            _commentController.clear();
                                            setState(() {
                                              _comments = newComments;
                                            });
                                          }
                                        }
                                      },
                                      icon: Icon(
                                        Icons.send,
                                        color: Colors.white,
                                        size: 20.sp,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12.h),
                              Row(
                                children: [
                                  Text(
                                    'التعليقات',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF482099),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12.h),
                              if (_comments.isNotEmpty)
                                ..._comments.reversed.map(
                                  (c) => Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.all(8.r),
                                        child: Text(
                                          c,
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      const Divider(),
                                    ],
                                  ),
                                ),
                              if (_comments.isEmpty)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'لا يوجد تعليات',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        color: context.accent,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildShareButton(IconData icon, Color color, String platform) {
    final url =
        "https://private-4t.com/client/preview/1?url=https://private-4t.com/education-library/item/${_itemModel?.id.toString()}";

    return GestureDetector(
      onTap: () {
        switch (platform) {
          case "Facebook":
            shareOnFacebook(url);
            break;
          case "WhatsApp":
            shareOnWhatsApp(url);
            break;
          case "Twitter":
            shareOnX(url);
            break;
          case "Telegram":
            shareOnTelegram(url);
            break;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم مشاركة الملف عبر $platform'),
            backgroundColor: color,
          ),
        );
      },
      child: Container(
        width: 40.w,
        height: 40.h,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20.sp,
        ),
      ),
    );
  }

  void shareOnFacebook(String url) async {
    final facebookUrl =
        Uri.parse("https://www.facebook.com/sharer/sharer.php?u=$url");

    if (await canLaunchUrl(facebookUrl)) {
      await launchUrl(facebookUrl, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch Facebook';
    }
  }

  void shareOnTelegram(String url) async {
    final telegramUrl = Uri.parse("https://t.me/share/url?url=$url");

    if (await canLaunchUrl(telegramUrl)) {
      await launchUrl(telegramUrl, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch Telegram';
    }
  }

  void shareOnWhatsApp(String url) async {
    final whatsappUrl =
        Uri.parse("https://wa.me/?text=${Uri.encodeComponent(url)}");

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch WhatsApp';
    }
  }

  void shareOnX(String url) async {
    final xUrl = Uri.parse(
        "https://twitter.com/intent/tweet?url=${Uri.encodeComponent(url)}");

    if (await canLaunchUrl(xUrl)) {
      await launchUrl(xUrl, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch X (Twitter)';
    }
  }
}
