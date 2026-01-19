import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

/// مكون ويب فيو ذكي لعرض عناوين URL أو ملفات (PDF, Word, إلخ) باستخدام Google Docs Viewer.
class WebView extends StatefulWidget {
  /// عنوان URL للملف أو الصفحة المراد عرضها.
  final String url;

  /// (اختياري) اسم الملف لعرضه في شريط العنوان.
  final String? fileName;

  /// (اختياري) ما إذا كان سيتم استخدام Google Docs Viewer لمعاينة الملفات.
  /// الافتراضي: true. إذا كان خطأً، سيتم تحميل عنوان URL مباشرةً.
  final bool useGoogleDocsViewer;

  const WebView({
    Key? key,
    required this.url,
    this.fileName,
    this.useGoogleDocsViewer = false,
  }) : super(key: key);

  @override
  State<WebView> createState() => _SmartWebViewState();
}

class _SmartWebViewState extends State<WebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  /// يقوم بتهيئة وتكوين WebViewController.
  Future<void> _initializeWebView() async {
    // تكوين خاص بكل منصة
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
    WebViewController.fromPlatformCreationParams(params);

    // تكوين WebView
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..supportsSetScrollBarsEnabled()
      ..setVerticalScrollBarEnabled(true)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _loadError = null;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            // التعامل مع أخطاء تحميل الموارد (خاصة الخطأ الرئيسي للإطار)
            if (error.isForMainFrame == true) {
              setState(() {
                _isLoading = false;
                _loadError =
                'Error loading page: ${error.description} (${error.errorCode})';
                // يمكنك تسجيل التفاصيل هنا إذا لزم الأمر
                // print('WebView Main Frame Error: ${error.description}');
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            // السماح بجميع طلبات التنقل داخل الـ WebView
            // يمكنك إضافة قيود هنا إذا أردت منع التنقل إلى مواقع خارجية
            return NavigationDecision.navigate;
          },
          // onUrlChange: (UrlChange change) { // متاح في إصدارات أحدث
          //   print('Url changed to: ${change.url}');
          // },
        ),
      );

    // تحديد عنوان URL النهائي للتحميل
    String finalUrl;
    if (widget.useGoogleDocsViewer) {
      // بناء عنوان URL لـ Google Docs Viewer لمعاينة الملفات
      finalUrl =
      'https://docs.google.com/gview?embedded=true&url=${Uri.encodeFull(widget.url)}';
    } else {
      // تحميل عنوان URL مباشرةً
      finalUrl = widget.url;
    }

    // تحميل عنوان URL في WebView
    controller.loadRequest(Uri.parse(finalUrl));

    setState(() {
      _controller = controller;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // عرض WebView
          WebViewWidget(controller: _controller,),

          // مؤشر التحميل
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),

          // رسالة الخطأ
          if (_loadError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _loadError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        // إعادة تحميل الـ WebView
                        setState(() {
                          _isLoading = true;
                          _loadError = null;
                        });
                        _initializeWebView(); // أعد التهيئة وإعادة التحميل
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}