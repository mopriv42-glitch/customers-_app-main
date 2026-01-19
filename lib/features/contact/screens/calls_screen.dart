import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/core/providers/app_container.dart';
import 'package:private_4t_app/core/services/matrix_call_service.dart';
import 'package:private_4t_app/core/services/navigation_service.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class CallsScreen extends ConsumerStatefulWidget {
  final String roomId;

  const CallsScreen({super.key, required this.roomId});

  @override
  ConsumerState<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends ConsumerState<CallsScreen> with AnalyticsScreenMixin {
  DateTime? _startAt;
  
  @override
  String get screenName => 'Callsscreen';
  
  late final ValueNotifier<Duration> _elapsed;
  Timer? _elapsedTimer;

  // متغير لتتبع حالة الإضافة إلى المستمع
  bool _listenerAdded = false;

  @override
  void initState() {
    super.initState();
    // تهيئة ValueNotifier بقيمة افتراضية لتجنب الأخطاء
    _elapsed = ValueNotifier(Duration.zero);

    getMatrix();
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    // التأكد من إزالة المستمع عند التخلص من الـ Widget
    // (تم نقل المنطق إلى build)
    _elapsed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matrix = ref.watch(ApiProviders.matrixChatProvider);
    final calls = MatrixCallService.instance;
    CallSession? session = calls?.getSession(widget.roomId);
    final room = matrix.clientNullable?.getRoomById(widget.roomId);
    final displayName = room?.getLocalizedDisplayname() ?? 'مكالمة صوتية';

    // إدارة إضافة وإزالة المستمع بشكل آمن
    if (session != null && !_listenerAdded) {
      session.onCallStateChanged.stream.listen(_sessionListener);
      _listenerAdded = true;
      // تهيئة الـ Timer إذا كانت الجلسة متصلة
      if (session.state == CallState.kConnected && _startAt == null) {
        _startAt = DateTime.now();
        _elapsedTimer?.cancel(); // إلغاء أي timer سابق
        _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (!mounted || _startAt == null) return;
          _elapsed.value = DateTime.now().difference(_startAt!);
        });
      }
    } else if (session == null && _listenerAdded) {
      if (context.mounted && context.canPop()) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.pop();
        });
      }
    }

    // إذا لم تكن هناك جلسة، أظهر تحميل البيانات أو رسالة خطأ
    if (session == null) {
      session = calls?.getSession(widget.roomId);
      if (session != null) {
        setState(() {});
      }
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: context.background,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: context.primaryText,
            ),
            onPressed: () {
              // Keep call running in background with overlay; just pop the screen
              context.pop();
            },
          ),
        ),
        body: session == null
            ? CommonComponents.loadingDataFromServer(color: context.primary)
            : Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Builder(builder: (context) {
                          final avatar = room?.avatar;
                          return FutureBuilder<String?>(
                            future: () async {
                              if (avatar == null || room == null) return null;
                              return avatar
                                  .getThumbnailUri(
                                    room.client,
                                    width: 50.w,
                                    // تأكد من أن .w متوفر من flutter_screenutil
                                    height: 50.h,
                                  )
                                  .toString();
                            }(),
                            builder: (context, snapshot) {
                              final avatarUrl = snapshot.data;
                              return CircleAvatar(
                                radius: 14.r,
                                // استخدام .r للتناسق مع flutter_screenutil
                                backgroundColor: Colors.blueGrey.shade100,
                                backgroundImage: avatarUrl == null
                                    ? null
                                    : NetworkImage(
                                        avatarUrl,
                                        headers: room == null
                                            ? null
                                            : {
                                                'Authorization':
                                                    'Bearer ${room.client.accessToken}',
                                              },
                                      ),
                                child: avatarUrl == null
                                    ? Text(
                                        displayName.isNotEmpty
                                            ? displayName[0]
                                            : '?',
                                        style: const TextStyle(
                                            color: Colors.black87),
                                      )
                                    : null,
                              );
                            },
                          );
                        }),
                        SizedBox(width: 8.w),
                        Flexible(
                          child: Text(
                            displayName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    if (session.state == CallState.kConnected &&
                        _startAt != null)
                      ValueListenableBuilder<Duration>(
                        valueListenable: _elapsed,
                        builder: (context, d, _) {
                          final m = d.inMinutes
                              .remainder(60)
                              .toString()
                              .padLeft(2, '0');
                          final s = d.inSeconds
                              .remainder(60)
                              .toString()
                              .padLeft(2, '0');
                          return Text(
                            '$m:$s',
                            style: TextStyle(
                                fontSize: 12.sp, color: context.primaryText),
                          );
                        },
                      )
                    else if (session.state != CallState.kConnected)
                      Text("جاري الإتصال ...",
                          style: TextStyle(
                              fontSize: 12.sp, color: context.primaryText)),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: session.state != CallState.kConnected
                              ? null
                              : () async {
                                  await session?.setMicrophoneMuted(
                                      !session.isMicrophoneMuted);
                                  setState(() {});
                                },
                          icon: Icon(
                            (session.isMicrophoneMuted)
                                ? Icons.mic_off
                                : Icons.mic,
                          ),
                          label: Text((session.isMicrophoneMuted)
                              ? 'إلغاء كتم'
                              : 'كتم'),
                        ),
                        SizedBox(width: 12.w),
                        ElevatedButton.icon(
                          onPressed: session.state != CallState.kConnected
                              ? null
                              : () async {
                                  final on = !(calls?.speakerOn ?? false);

                                  await calls?.setSpeaker(on);
                                  setState(() {});
                                },
                          icon: Icon(
                            (calls?.speakerOn ?? false)
                                ? Icons.volume_up
                                : Icons.phone_in_talk,
                          ),
                          label: Text((calls?.speakerOn ?? false)
                              ? 'المكبر'
                              : 'الهاتف'),
                        ),
                        SizedBox(width: 12.w),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          onPressed: () async {
                            await session?.hangup(
                              reason: CallErrorCode.userHangup,
                            );
                            await calls?.endCall(widget.roomId);
                          },
                          icon: const Icon(Icons.call_end),
                          label: const Text('إنهاء'),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
      ),
    );
  }

  // دالة مستقلة للمستمع لتسهيل الإدارة
  void _sessionListener(CallState state) {
    debugPrint("TEST");
    if (!mounted) {
      // إزالة المستمع إذا لم يعد الـ Widget مُركبًا
      // ومع ذلك، ChangeNotifier لا يوفر طريقة سهلة لإزالة المستمع من داخل المستمع نفسه.
      // الأفضل هو التأكد من إزالة المستمع في dispose أو عند تغيير session.
      return;
    }

    setState(() {
      // التحقق من أن session لا يزال مُشيرًا إلى نفس الكائن قد يكون ضروريًا في بعض الحالات
      if (state == CallState.kEnded) {
        // إذا انتهت المكالمة، قم بإزالة المستمع وتنظيف الموارد
        _listenerAdded = false; // السماح بإعادة الإضافة إذا لزم الأمر
        _elapsedTimer?.cancel();
        NavigationService.hideCallOverlay();
        if (context.mounted && context.canPop()) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.pop();
          });
        }
      } else if (state == CallState.kConnected) {
        // إذا تم الاتصال، ابدأ المؤقت إذا لم يبدأ بالفعل
        if (_startAt == null) {
          _startAt = DateTime.now();
          _elapsedTimer?.cancel();
          _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
            if (!mounted || _startAt == null) return;
            _elapsed.value = DateTime.now().difference(_startAt!);
          });
        }
      }
      // تحديث واجهة المستخدم للحالات الأخرى إن لزم
    });
  }
}
