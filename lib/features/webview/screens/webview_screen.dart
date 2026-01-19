import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/core/widgets/app_header.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  final String? title;
  final List<String>? images;

  const WebViewScreen({
    super.key,
    required this.url,
    this.title,
    this.images,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> with AnalyticsScreenMixin {
  
  @override
  String get screenName => 'Webviewscreen';
  
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _currentTitle;
  double _loadingProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _loadingProgress = 0.0;
            });
          },
          onProgress: (int progress) {
            setState(() {
              _loadingProgress = progress / 100.0;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            _updateTitle();
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
            _showErrorDialog();
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _updateTitle() async {
    try {
      final title = await _controller.getTitle();
      if (title != null && title.isNotEmpty && mounted) {
        setState(() {
          _currentTitle = title;
        });
      }
    } catch (e) {
      debugPrint('Error getting page title: $e');
    }
  }

  void _showErrorDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('webview.loading_error'.tr()),
        content: Text('webview.loading_error_message'.tr()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            child: Text('webview.close'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _controller.reload();
            },
            child: Text('webview.retry'.tr()),
          ),
        ],
      ),
    );
  }

  void _showImagesDialog() {
    if (widget.images == null || widget.images!.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text('webview.attached_images'.tr()),
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: widget.images!.length,
                  itemBuilder: (context, index) {
                    final imageUrl = widget.images![index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 16.h),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200.h,
                              color: Colors.grey[200],
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 48.sp,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      'webview.image_load_error'.tr(),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 200.h,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.background,
      appBar: AppHeader(
        title: widget.title ?? _currentTitle ?? 'webview.title'.tr(),
        showBackButton: true,
        additionalActions: [
          if (widget.images != null && widget.images!.isNotEmpty)
            IconButton(
              icon: Badge(
                label: Text('${widget.images!.length}'),
                child: const Icon(Icons.photo_library),
              ),
              onPressed: _showImagesDialog,
              tooltip: 'webview.view_attached_images'.tr(),
            ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'refresh':
                  await _controller.reload();
                  break;
                case 'forward':
                  if (await _controller.canGoForward()) {
                    await _controller.goForward();
                  }
                  break;
                case 'back':
                  if (await _controller.canGoBack()) {
                    await _controller.goBack();
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8.w),
                    Text('webview.refresh'.tr()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'back',
                child: Row(
                  children: [
                    Icon(Icons.arrow_back),
                    SizedBox(width: 8.w),
                    Text('webview.back'.tr()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'forward',
                child: Row(
                  children: [
                    const Icon(Icons.arrow_forward),
                    SizedBox(width: 8.w),
                    Text('webview.forward'.tr()),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Loading progress bar
          if (_isLoading)
            LinearProgressIndicator(
              value: _loadingProgress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(context.primary),
            ),
          // WebView
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}
