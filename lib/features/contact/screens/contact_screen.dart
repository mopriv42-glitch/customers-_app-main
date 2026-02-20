import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
// Removed direct import of RoomTimelineScreen; navigation uses GoRouter via NavigationService
import 'package:matrix/matrix.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/core/models/user_model.dart';
import 'package:private_4t_app/core/providers/theme_provider.dart';
import 'package:private_4t_app/core/services/navigation_service.dart';
import 'package:private_4t_app/core/widgets/app_header.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class ContactScreen extends ConsumerStatefulWidget {
  const ContactScreen({super.key});

  @override
  ConsumerState<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends ConsumerState<ContactScreen> with AnalyticsScreenMixin {
  
  @override
  String get screenName => 'Contactscreen';
  
  int _selectedFilterIndex = 0;

  final List<String> _filters = ['دردشة', 'اتصال', 'جروبات'];
  final TextEditingController _callSearchCtrl = TextEditingController();
  bool _startingCall = false;
  bool _isAutoProvisioning = false;
  bool _autoProvisioningScheduled = false;

  Future<bool> _checkMatrixImageAvailable(String url, String? token) async {
    try {
      final uri = Uri.parse(url);
      final client = HttpClient();
      final req = await client.headUrl(uri);
      if (token != null) {
        req.headers.set('Authorization', 'Bearer $token');
      }
      final res = await req.close();
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final matrixProvider = ref.watch(ApiProviders.matrixChatProvider);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        floatingActionButton:
            matrixProvider.isInitialized && matrixProvider.isLoggedIn
                ? FloatingActionButton(
                    onPressed: () async {
                      final supportMixId = ref
                              .read(ApiProviders.loginProvider)
                              .loggedUser
                              ?.matrixUserSupportId ??
                          'support';
                      await _onStartCallByUserId(ref, supportMixId);
                    },
                    child: Icon(
                      Icons.call,
                      color: ref
                                  .read(ApiProviders.themeProvider.notifier)
                                  .currentBrand ==
                              BrandTheme.castle
                          ? Colors.white
                          : context.primary,
                      size: 35.sp,
                    ),
                  )
                : null,
        backgroundColor: context.background,
        appBar: AppHeader(
          title: 'التواصل',
          showBackButton: false,
          showLogo: true,
          additionalActions: [
            // Matrix Invitations Icon
            Consumer(builder: (context, ref, _) {
              final matrix = ref.watch(ApiProviders.matrixChatProvider);
              if (!matrix.isLoggedIn) return const SizedBox.shrink();

              final inviteCount = matrix.invitedRooms.length;

              return Stack(
                children: [
                  IconButton(
                    tooltip: 'دعوات Matrix',
                    icon: const Icon(Icons.mail_outline),
                    onPressed: () => context.push('/invitations'),
                  ),
                  if (inviteCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 12.w,
                          minHeight: 12.h,
                        ),
                        child: Text(
                          inviteCount > 99 ? '99+' : inviteCount.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            }),
            // Matrix Logout Button
            // Consumer(builder: (context, ref, _) {
            //   final matrix = ref.watch(ApiProviders.matrixChatProvider);
            //   if (!matrix.isLoggedIn) return const SizedBox.shrink();
            //   return IconButton(
            //     tooltip: 'تسجيل الخروج من Matrix',
            //     icon: const Icon(Icons.logout),
            //     onPressed: () async {
            //       final confirmed = await showDialog<bool>(
            //             context: context,
            //             builder: (ctx) => AlertDialog(
            //               title: const Text('تأكيد الخروج'),
            //               content: const Text(
            //                   'هل تريد تسجيل الخروج من محادثات Matrix؟'),
            //               actions: [
            //                 TextButton(
            //                   onPressed: () => Navigator.pop(ctx, false),
            //                   child: const Text('إلغاء'),
            //                 ),
            //                 TextButton(
            //                   onPressed: () => Navigator.pop(ctx, true),
            //                   child: const Text('تأكيد'),
            //                 ),
            //               ],
            //             ),
            //           ) ??
            //           false;
            //       if (!confirmed) return;
            //       await ref.read(ApiProviders.matrixChatProvider).logout();
            //       if (mounted) {
            //         setState(() {});
            //         ScaffoldMessenger.of(context).showSnackBar(
            //           const SnackBar(
            //               content: Text('تم تسجيل الخروج من Matrix')),
            //         );
            //       }
            //     },
            //   );
            // })
          ],
        ),
        body: Column(
          children: [
            _buildFilterTabs(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      height: 32.h,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: context.secondary.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: Row(
        children: _filters.asMap().entries.map((entry) {
          final index = entry.key;
          final filter = entry.value;
          final isSelected = index == _selectedFilterIndex;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                logButtonClick('contact_filter_tab', data: {
                  'filter_index': index,
                  'filter_name': filter,
                });
                setState(() {
                  _selectedFilterIndex = index;
                });
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? context.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? context.textOnPrimary
                        : context.primaryText,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedFilterIndex) {
      case 0:
        return _buildChatList();
      case 1:
        return _buildCallHistory();
      case 2:
        return _buildGroupsList();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  void dispose() {
    _callSearchCtrl.dispose();
    super.dispose();
  }

  /// Attempt automatic Matrix user provisioning
  Future<void> _attemptAutoProvisioning(
      WidgetRef ref, UserModel loggedUser) async {
    // Prevent multiple simultaneous provisioning attempts
    if (_isAutoProvisioning) return;

    setState(() {
      _isAutoProvisioning = true;
      _autoProvisioningScheduled = false; // Reset the scheduling flag
    });

    try {
      debugPrint(
          'Starting automatic Matrix provisioning for user: ${loggedUser.phone}');

      final matrixProvider = ref.read(ApiProviders.matrixChatProvider);

      // Check if user can be provisioned
      if (!matrixProvider.canAutoProvision(loggedUser)) {
        debugPrint('User cannot be auto-provisioned (missing phone number)');
        setState(() {
          _isAutoProvisioning = false;
          _autoProvisioningScheduled = false;
        });
        return;
      }

      // Perform auto-provisioning
      final result =
          await matrixProvider.autoProvisionUser(appUser: loggedUser);

      if (result.success) {
        debugPrint('Auto-provisioning successful: ${result.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('تم ربط حسابك بـ Matrix تلقائياً'),
              backgroundColor: context.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        debugPrint('Auto-provisioning failed: ${result.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل في الربط التلقائي: ${result.message}'),
              backgroundColor: context.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error during auto-provisioning: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الربط التلقائي: $e'),
            backgroundColor: context.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAutoProvisioning = false;
          _autoProvisioningScheduled = false;
        });
      }
    }
  }

  /// UI to show during auto-provisioning
  Widget _buildAutoProvisioningUI() {
    return Padding(
      padding: EdgeInsets.all(32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          SizedBox(height: 24.h),
          Text(
            'جاري ربط حسابك بـ Matrix...',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: context.primaryText,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            'يتم إعداد حسابك للمحادثات والمكالمات',
            style: TextStyle(
              fontSize: 14.sp,
              color: context.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Removed unused quick-action dialogs; can be reintroduced from a menu later.

  Widget _buildChatList() {
    return Consumer(
      builder: (context, ref, _) {
        final matrix = ref.watch(ApiProviders.matrixChatProvider);
        final loginProvider = ref.watch(ApiProviders.loginProvider);

        if (!matrix.isInitialized) {
          ref.read(ApiProviders.matrixChatProvider).init();
          return const Center(child: CircularProgressIndicator());
        }

        // Auto-provision user if they're logged into the app but not Matrix
        if (!matrix.isLoggedIn &&
            loginProvider.loggedUser != null &&
            !_isAutoProvisioning &&
            !_autoProvisioningScheduled) {
          // Schedule auto-provisioning after the current build frame
          _autoProvisioningScheduled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _attemptAutoProvisioning(ref, loginProvider.loggedUser!);
            }
          });
        }

        if (!matrix.canAutoProvision(loginProvider.loggedUser!)) {
          return _buildNotAutoProvision();
        }

        if (_isAutoProvisioning) {
          return _buildAutoProvisioningUI();
        }

        if (!matrix.isLoggedIn) {
          return _buildMatrixLogin(ref);
        }
        // Direct messages: fall back to 2-participant rooms if isDirectChat isn't reliable
        final rooms = matrix.joinedRooms
            .where((r) =>
                _looksLikeDm(r) &&
                !r.getParticipants().any((u) =>
                    u.id ==
                    _normalizeMxid(
                        loginProvider.loggedUser?.matrixUserSupportId ??
                            'support',
                        matrix.client.userID ?? '')))
            .toList();
        final invites = matrix.clientNullable?.rooms
                .where((r) => r.membership == Membership.invite)
                .toList(growable: false) ??
            const <Room>[];
        if (rooms.isEmpty) {
          return const Center(child: Text('لا توجد محادثات'));
        }
        return RefreshIndicator(
          onRefresh: () async => await matrix.startSync(),
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            children: [
              if (invites.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('دعوات (${invites.length})',
                        style: TextStyle(
                            fontSize: 14.sp, fontWeight: FontWeight.w700)),
                    TextButton(
                      onPressed: () => context.push('/invitations'),
                      child: Text(
                        'عرض الكل',
                        style: TextStyle(
                          color: const Color(0XFF222338),
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                // Show only first 2 invitations here
                ...invites.take(2).map((r) => Card(
                      margin: EdgeInsets.only(bottom: 8.h),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              const Color(0XFF222338).withOpacity(0.1),
                          child: Icon(
                            r.isDirectChat ? Icons.person : Icons.group,
                            color: const Color(0XFF222338),
                            size: 20.w,
                          ),
                        ),
                        title: Text(
                          r.getLocalizedDisplayname(),
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          r.isDirectChat ? 'دعوة محادثة' : 'دعوة مجموعة',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.black54,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () async {
                                final success = await ref
                                    .read(ApiProviders.matrixChatProvider)
                                    .rejectInvitation(r.id);
                                if (success && mounted) {
                                  setState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('تم رفض الدعوة'),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              icon: Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 20.w,
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                final success = await ref
                                    .read(ApiProviders.matrixChatProvider)
                                    .acceptInvitation(r.id);
                                if (success && mounted) {
                                  setState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('تم قبول الدعوة بنجاح'),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              icon: Icon(
                                Icons.check,
                                color: Colors.green,
                                size: 20.w,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                if (invites.length > 2)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Center(
                      child: TextButton(
                        onPressed: () => context.push('/invitations'),
                        child: Text(
                          'عرض ${invites.length - 2} دعوة أخرى',
                          style: TextStyle(
                            color: const Color(0XFF222338),
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: 12.h),
              ],
              ...rooms.map((room) {
                final lastEvent = room.lastEvent;
                final lastMessage = _readableLastEvent(lastEvent);
                final time = lastEvent == null
                    ? ''
                    : lastEvent.originServerTs
                        .toLocal()
                        .toString()
                        .substring(0, 16);
                final unread = room.notificationCount;
                final avatarUri = room.avatar
                    ?.getThumbnailUri(
                      room.client,
                      width: 56,
                      height: 56,
                    )
                    .toString();
                final chat = ChatData(
                  name: room.getLocalizedDisplayname(),
                  lastMessage: lastMessage,
                  time: time,
                  unreadCount: unread,
                  isOnline: false,
                  avatarUrl: avatarUri,
                  accessToken: matrix.client.accessToken,
                );
                return InkWell(
                  onTap: () {
                    logButtonClick('contact_chat_item', data: {
                      'room_id': room.id,
                      'room_name': chat.name,
                      'unread_count': chat.unreadCount,
                    });
                    NavigationService.navigateToRoomTimeline(context, room.id);
                  },
                  child: _buildChatItem(chat),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  String _readableLastEvent(dynamic ev) {
    if (ev == null) return '';
    try {
      if (ev.type == EventTypes.Message) {
        final mt = ev.messageType;
        if (mt == MessageTypes.Image) return 'صورة';
        if (mt == MessageTypes.Video) return 'فيديو';
        if (mt == MessageTypes.Audio) return 'صوت';
        if (mt == MessageTypes.File) return 'ملف';
        if (mt == MessageTypes.Location) return 'موقع';
        if (mt == MessageTypes.Emote) return ev.body;
        return ev.body ?? '';
      }
      if (ev.type == EventTypes.Sticker) return 'ملصق';
      if (ev.type == EventTypes.CallInvite) return 'مكالمة صوتية واردة';
      if (ev.type == EventTypes.CallAnswer) return 'تم الرد على المكالمة';
      if (ev.type == EventTypes.CallHangup) return 'انتهت المكالمة';
      if (ev.type == EventTypes.Redaction) return 'تم حذف رسالة';
      if (ev.type == EventTypes.Reaction) return 'تفاعل جديد';
      if (ev.type == EventTypes.RoomMember) {
        final action = ev.content?.tryGet<String>('membership');
        if (action == 'join') return 'انضمام جديد';
        if (action == 'leave') return 'مغادرة الغرفة';
        if (action == 'invite') return 'تم إرسال دعوة';
        return 'تحديث الأعضاء';
      }
      return ev.body ?? '';
    } catch (_) {
      return '';
    }
  }

  // Navigation handled inline via NavigationService where needed.

  Widget _buildMatrixLogin(WidgetRef ref) {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();
    final nameController = TextEditingController();

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'تسجيل الدخول إلى Matrix',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: context.primaryText,
            ),
          ),
          SizedBox(height: 24.h),

          // Admin API Authentication Section
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: context.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: context.primary.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تسجيل دخول تلقائي (مستحسن)',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: context.primary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'استخدم رقم الهاتف للدخول التلقائي',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: context.secondaryText,
                  ),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف',
                    hintText: '+1234567890',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'الاسم',
                    hintText: 'أدخل اسمك',
                  ),
                ),
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        final phone = phoneController.text.trim();
                        final name = nameController.text.trim();

                        if (phone.isEmpty || name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('يرجى إدخال رقم الهاتف والاسم'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        // Show loading
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) =>
                              const Center(child: CircularProgressIndicator()),
                        );

                        final provider =
                            ref.read(ApiProviders.matrixChatProvider);
                        final result = await provider.authenticateWithPhone(
                          phoneNumber: phone,
                          userName: name,
                        );

                        if (context.mounted) {
                          Navigator.pop(context); // Hide loading
                        }

                        if (result.success) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    result.message ?? 'تم تسجيل الدخول بنجاح'),
                                backgroundColor: context.success,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            // Reload the contact screen route to reflect the new session
                            context.go('/contact');
                          }
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text(result.message ?? 'فشل تسجيل الدخول'),
                                backgroundColor: context.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(context); // Hide loading
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('خطأ: ${e.toString()}'),
                              backgroundColor: context.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('تسجيل الدخول التلقائي'),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // Manual Login Section
          Text(
            'أو تسجيل دخول يدوي',
            style: TextStyle(
              fontSize: 14.sp,
              color: context.secondaryText,
            ),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: usernameController,
            decoration:
                const InputDecoration(labelText: 'المعرف أو اسم المستخدم'),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: passwordController,
            decoration: const InputDecoration(labelText: 'كلمة المرور'),
            obscureText: true,
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                try {
                  final provider = ref.read(ApiProviders.matrixChatProvider);
                  await provider.loginWithPassword(
                    usernameOrUserId: usernameController.text.trim(),
                    password: passwordController.text,
                  );
                  await provider.startSync();
                  if (context.mounted) {
                    // Reload the contact screen route to reflect the new session
                    context.go('/contact');
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.secondary,
                foregroundColor: Colors.white,
              ),
              child: const Text('تسجيل الدخول اليدوي'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(ChatData chat) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24.r),
            child: SizedBox(
              width: 48.w,
              height: 48.h,
              child: (chat.avatarUrl == null)
                  ? Container(
                      color: context.primary.withOpacity(0.1),
                      child: Center(
                        child: Text(
                          chat.name.isNotEmpty ? chat.name[0] : '?',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: context.primary,
                          ),
                        ),
                      ),
                    )
                  : FutureBuilder<bool>(
                      future: _checkMatrixImageAvailable(
                          chat.avatarUrl!, chat.accessToken),
                      builder: (context, snap) {
                        final ok = snap.data == true;
                        if (!ok) {
                          return Container(
                            color: context.primary.withOpacity(0.1),
                            child: Center(
                              child: Text(
                                chat.name.isNotEmpty ? chat.name[0] : '?',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: context.primary,
                                ),
                              ),
                            ),
                          );
                        }
                        return Image.network(
                          chat.avatarUrl!,
                          fit: BoxFit.cover,
                          headers: chat.accessToken == null
                              ? null
                              : {
                                  'Authorization': 'Bearer ${chat.accessToken}',
                                },
                          errorBuilder: (_, __, ___) {
                            return Container(
                              color: context.primary.withOpacity(0.1),
                              child: Center(
                                child: Text(
                                  chat.name.isNotEmpty ? chat.name[0] : '?',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: context.primary,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        chat.name,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: context.primaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Flexible(
                      flex: 0,
                      child: Text(
                        chat.time,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: context.secondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        chat.lastMessage,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: context.secondaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (chat.unreadCount > 0) ...[
                      SizedBox(width: 8.w),
                      Container(
                        constraints: BoxConstraints(minWidth: 20.w),
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: context.primary,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Center(
                          child: Text(
                            '${chat.unreadCount}',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: context.textOnPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallHistory() {
    return Consumer(builder: (context, ref, _) {
      final matrix = ref.watch(ApiProviders.matrixChatProvider);
      if (!matrix.isInitialized || !matrix.isLoggedIn) {
        return const Center(child: CircularProgressIndicator());
      }
      final header = _buildCallStartCard(ref);
      return FutureBuilder<List<CallData>>(
        future: _gatherCallHistoryFast(matrix),
        builder: (context, snap) {
          final list = snap.data;
          if (list == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            children: [
              header,
              SizedBox(height: 12.h),
              if (list.isEmpty)
                const Center(child: Text('لا يوجد سجل مكالمات'))
              else
                ...List.generate(list.length, (i) => _buildCallItem(list[i])),
            ],
          );
        },
      );
    });
  }

  Widget _buildCallStartCard(WidgetRef ref) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'بدء مكالمة عبر معرف المستخدم',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _callSearchCtrl,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(
                      hintText: '@user:matrix.private-4t.com أو user',
                      labelText: 'معرّف المستخدم',
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                SizedBox(
                  height: 40.h,
                  child: ElevatedButton.icon(
                    onPressed:
                        _startingCall ? null : () => _onStartCallByUserId(ref),
                    icon: _startingCall
                        ? SizedBox(
                            width: 16.w,
                            height: 16.w,
                            child:
                                const CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.call),
                    label: const Text('اتصال'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onStartCallByUserId(WidgetRef ref, [String? raw]) async {
    final matrix = ref.read(ApiProviders.matrixChatProvider);
    raw ??= _callSearchCtrl.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل معرف المستخدم أولًا')),
      );
      return;
    }
    
    logButtonClick('contact_start_call', data: {
      'user_id': raw,
    });
    
    setState(() => _startingCall = true);
    try {
      final mxid = _normalizeMxid(raw, matrix.client.userID ?? '');
      final room = await _findOrCreateDmRoom(matrix.client, mxid);
      if (room == null) {
        throw Exception('تعذر فتح محادثة مباشرة مع $mxid');
      }
      final calls = matrix.calls;
      if (calls == null) throw Exception('خدمة المكالمات غير متاحة');
      NavigationService.navigateToCall(context, room.id);
      await calls.startCall(room,CallType.kVoice);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _startingCall = false);
    }
  }

  Future<void> _onStartCallFromHistory(CallData callData, WidgetRef ref) async {
    logButtonClick('contact_call_from_history', data: {
      'contact_name': callData.name,
      'room_id': callData.roomId,
    });
    
    final matrix = ref.read(ApiProviders.matrixChatProvider);

    if (!matrix.isInitialized || !matrix.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب تسجيل الدخول أولاً')),
      );
      return;
    }

    setState(() => _startingCall = true);

    try {
      final room = matrix.client.getRoomById(callData.roomId);
      if (room == null) {
        throw Exception('لا يمكن العثور على الغرفة');
      }

      final calls = matrix.calls;
      if (calls == null) {
        throw Exception('خدمة المكالمات غير متاحة');
      }

      // Start voice call
      await calls.startCall(room,CallType.kVoice);

      // Navigate to call screen
      NavigationService.navigateToCall(context, room.id);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('بدء الاتصال مع ${callData.name}'),
          backgroundColor: context.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في بدء المكالمة: ${e.toString()}'),
          backgroundColor: context.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _startingCall = false);
    }
  }

  String _normalizeMxid(String input, String selfUserId) {
    // Derive domain from current user id: @localpart:domain
    final parts = selfUserId.split(':');
    final domain =
        parts.length > 1 ? parts.sublist(1).join(':') : 'matrix.private-4t.com';
    String local = input;
    if (!local.startsWith('@')) {
      // If user typed full domain already without @
      if (local.contains(':')) {
        local = '@$local';
      } else {
        local = '@$local:$domain';
      }
    } else if (!local.contains(':')) {
      local = '$local:$domain';
    }
    return local;
  }

  Future<Room?> _findOrCreateDmRoom(Client client, String userId) async {
    // 1) شوف إذا في غرفة DM موجودة مع نفس المستخدم
    final existing = client.rooms
        .where((r) => r.membership == Membership.join && r.isDirectChat);
    for (final r in existing) {
      try {
        final members = r.getParticipants();
        if (members.any((m) => m.id == userId)) {
          return r;
        }
      } catch (_) {}
    }

    // 2) إذا مش موجودة، اعمل DM جديد
    try {
      final roomId = await client.createRoom(
        isDirect: true,
        invite: [userId],
      );

      final directEvent = client.accountData['m.direct'];
      Map<String, dynamic> content = {};

      if (directEvent != null) {
        content = Map<String, dynamic>.from(directEvent.content);
      }

      // نضيف الـ room للـ userId
      final userRooms = (content[userId] as List?)?.cast<String>() ?? [];
      if (!userRooms.contains(roomId)) {
        userRooms.add(roomId);
      }
      content[userId] = userRooms;

      // تحديث m.direct
      await client.setAccountData(
        client.userID!, // userId
        'm.direct', // type
        content, // body
      );

      return client.getRoomById(roomId);
    } catch (_) {
      return null;
    }
  }

  Future<List<CallData>> _gatherCallHistoryFast(dynamic matrixProvider) async {
    final rooms = matrixProvider.joinedRooms as List<Room>;
    final userId = matrixProvider.client.userID;
    final futures = rooms.map((room) async {
      try {
        final tl = await room.getTimeline(limit: 1000).timeout(
            const Duration(seconds: 2),
            onTimeout: () => room.getTimeline(limit: 500));
        final invites = <String, Event>{};
        final hangups = <String, Event>{};
        for (final e in tl.events) {
          if (e.type == EventTypes.CallInvite) {
            final id = e.content['call_id'] as String?;
            if (id != null) invites[id] = e;
          } else if (e.type == EventTypes.CallHangup) {
            final id = e.content['call_id'] as String?;
            if (id != null) hangups[id] = e;
          }
        }
        final List<CallData> items = [];
        for (final entry in invites.entries) {
          final id = entry.key;
          final ev = entry.value;
          final end = hangups[id];
          final incoming = ev.senderId != userId;
          final type = end == null && incoming
              ? CallTypes.missed
              : (incoming ? CallTypes.incoming : CallTypes.outgoing);
          String duration = '';
          if (end != null) {
            final secs =
                end.originServerTs.difference(ev.originServerTs).inSeconds;
            final mm = (secs ~/ 60).toString().padLeft(1, '0');
            final ss = (secs % 60).toString().padLeft(2, '0');
            duration = '$mm:$ss';
          }
          final when = ev.originServerTs.toLocal().toString().substring(0, 16);
          items.add(CallData(
            name: room.getLocalizedDisplayname(),
            type: type,
            date: when,
            duration: duration,
            roomId: room.id,
            userId: room.isDirectChat ? room.directChatMatrixID : null,
          ));
        }
        return items;
      } catch (_) {
        return <CallData>[];
      }
    });
    final results = await Future.wait(futures).timeout(
        const Duration(seconds: 4),
        onTimeout: () => const <List<CallData>>[]);
    final all = results.expand((e) => e).toList();
    all.sort((a, b) => b.date.compareTo(a.date));
    return all;
  }

  Widget _buildCallItem(CallData call) {
    IconData callIcon;
    Color callColor;
    String callText;

    switch (call.type) {
      case CallTypes.incoming:
        callIcon = Icons.call_received;
        callColor = context.success;
        callText = 'وارد';
        break;
      case CallTypes.outgoing:
        callIcon = Icons.call_made;
        callColor = context.accentSecondary;
        callText = 'صادر';
        break;
      case CallTypes.missed:
        callIcon = Icons.call_missed;
        callColor = context.error;
        callText = 'مفقود';
        break;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.h,
            decoration: BoxDecoration(
              color: context.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: Center(
              child: Text(
                call.name.split(' ').first[0],
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: context.primary,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        call.name,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: context.primaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Consumer(
                      builder: (context, ref, child) {
                        return GestureDetector(
                          onTap: _startingCall
                              ? null
                              : () => _onStartCallFromHistory(call, ref),
                          child: Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: _startingCall
                                  ? context.disabled
                                  : context.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: _startingCall
                                ? SizedBox(
                                    width: 16.w,
                                    height: 16.w,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        context.primary,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.call,
                                    size: 16.sp,
                                    color: context.primary,
                                  ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(
                      callIcon,
                      size: 12.sp,
                      color: callColor,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '$callText • ${call.date}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: context.secondaryText,
                      ),
                    ),
                    if (call.duration.isNotEmpty) ...[
                      SizedBox(width: 8.w),
                      Text(
                        call.duration,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: context.secondaryText,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsList() {
    return Consumer(builder: (context, ref, _) {
      final matrix = ref.watch(ApiProviders.matrixChatProvider);
      if (!matrix.isInitialized || !matrix.isLoggedIn) {
        return const Center(child: CircularProgressIndicator());
      }
      // Groups: exclude DMs by flag or by participant-size fallback
      final rooms = matrix.joinedRooms.where((r) => !_looksLikeDm(r)).toList();
      if (rooms.isEmpty) {
        return const Center(child: Text('لا توجد مجموعات'));
      }
      return ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          final room = rooms[index];
          final lastEvent = room.lastEvent;
          final data = GroupData(
            name: room.getLocalizedDisplayname(),
            members: room.getParticipants().length,
            lastMessage: lastEvent?.body ?? '',
            time: lastEvent == null
                ? ''
                : lastEvent.originServerTs
                    .toLocal()
                    .toString()
                    .substring(0, 16),
            unreadCount: room.notificationCount,
          );
          return InkWell(
            onTap: () {
              logButtonClick('contact_group_item', data: {
                'room_id': room.id,
                'group_name': data.name,
                'members_count': data.members,
                'unread_count': data.unreadCount,
              });
              NavigationService.navigateToRoomTimeline(context, room.id);
            },
            child: _buildGroupItem(data),
          );
        },
      );
    });
  }

  Widget _buildGroupItem(GroupData group) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.h,
            decoration: BoxDecoration(
              color: context.accentSecondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: Center(
              child: Icon(
                Icons.group,
                size: 24.sp,
                color: context.accentSecondary,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        group.name,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: context.primaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      group.time,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: context.secondaryText,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        group.lastMessage,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: context.secondaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (group.unreadCount > 0) ...[
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: context.primary,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          '${group.unreadCount}',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: context.textOnPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  '${group.members} عضو',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: context.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotAutoProvision() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text("يرجى تحديث بيانات الشخصية أولاً"),
        TextButton(
            onPressed: () {
              context.push('/profile');
            },
            child: const Text("الملف الشخصي"))
      ],
    );
  }
}

bool _looksLikeDm(Room r) {
  try {
    // A DM usually has exactly 2 joined members including self
    final members = r.getParticipants();
    return r.isDirectChat || members.length <= 2 && members.isNotEmpty;
  } catch (_) {
    return false;
  }
}

class ChatData {
  final String name;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final bool isOnline;
  final String? avatarUrl;
  final String? accessToken;

  ChatData({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.isOnline,
    this.avatarUrl,
    this.accessToken,
  });
}

class CallData {
  final String name;
  final CallTypes type;
  final String date;
  final String duration;
  final String roomId;
  final String? userId;

  CallData({
    required this.name,
    required this.type,
    required this.date,
    required this.duration,
    required this.roomId,
    this.userId,
  });
}

enum CallTypes { incoming, outgoing, missed }

class GroupData {
  final String name;
  final int members;
  final String lastMessage;
  final String time;
  final int unreadCount;

  GroupData({
    required this.name,
    required this.members,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
  });
}
