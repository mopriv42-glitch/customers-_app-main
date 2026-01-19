import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/core/widgets/app_header.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';


class InvitationsScreen extends ConsumerStatefulWidget {
  const InvitationsScreen({super.key});

  @override
  ConsumerState<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends ConsumerState<InvitationsScreen> with AnalyticsScreenMixin {
  
  @override
  String get screenName => 'Invitationsscreen';
  
  List<Map<String, dynamic>> _invitations = [];
  bool _isLoading = true;
  Set<String> _processingInvitations = {};

  @override
  void initState() {
    super.initState();
    _loadInvitations();
  }

  Future<void> _loadInvitations() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final matrixProvider = ref.read(ApiProviders.matrixChatProvider);
      final invitations = await matrixProvider.getAllInvitationDetails();

      if (mounted) {
        setState(() {
          _invitations = invitations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل الدعوات: $e'),
            backgroundColor: context.error,
          ),
        );
      }
    }
  }

  Future<void> _handleInvitation(String roomId, bool accept) async {
    if (_processingInvitations.contains(roomId)) return;

    setState(() => _processingInvitations.add(roomId));

    try {
      final matrixProvider = ref.read(ApiProviders.matrixChatProvider);
      final success = accept
          ? await matrixProvider.acceptInvitation(roomId)
          : await matrixProvider.rejectInvitation(roomId);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(accept ? 'تم قبول الدعوة بنجاح' : 'تم رفض الدعوة'),
              backgroundColor: context.success,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Remove from local list
          setState(() {
            _invitations.removeWhere((inv) => inv['roomId'] == roomId);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(accept ? 'فشل في قبول الدعوة' : 'فشل في رفض الدعوة'),
              backgroundColor: context.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: context.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingInvitations.remove(roomId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.background,
        appBar: AppHeader(
          title: 'دعوات المحادثات',
          showBackButton: true,
          onBackPressed: () => context.pop(),
        ),
        body: _isLoading
            ? _buildLoadingState()
            : _invitations.isEmpty
                ? _buildEmptyState()
                : _buildInvitationsList(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            context.background,
            context.surface.withOpacity(0.3),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(context.primary),
              strokeWidth: 3,
            ),
            SizedBox(height: 24.h),
            Text(
              'جاري تحميل الدعوات...',
              style: TextStyle(
                fontSize: 16.sp,
                color: context.secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            context.background,
            context.surface.withOpacity(0.3),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: context.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mail_outline,
                  size: 64.w,
                  color: context.primary,
                ),
              ),
              SizedBox(height: 32.h),
              Text(
                'لا توجد دعوات معلقة',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: context.primaryText,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              Text(
                'ستظهر هنا دعوات المحادثات والمجموعات الجديدة\nعندما يقوم أحد بدعوتك للانضمام',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: context.secondaryText,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              ElevatedButton.icon(
                onPressed: _loadInvitations,
                icon: Icon(Icons.refresh, size: 20.w),
                label: const Text('تحديث'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primary,
                  foregroundColor: Colors.white,
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvitationsList() {
    return RefreshIndicator(
      onRefresh: _loadInvitations,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _invitations.length,
        itemBuilder: (context, index) {
          final invitation = _invitations[index];
          return _buildInvitationCard(invitation);
        },
      ),
    );
  }

  Widget _buildInvitationCard(Map<String, dynamic> invitation) {
    final roomId = invitation['roomId'] as String;
    final roomName = invitation['roomName'] as String;
    final inviterDisplayName = invitation['inviterDisplayName'] as String;
    final isDirectChat = invitation['isDirectChat'] as bool;
    final memberCount = invitation['memberCount'] as int;
    final timestamp = invitation['timestamp'] as DateTime;
    final roomTopic = invitation['roomTopic'] as String?;
    final isProcessing = _processingInvitations.contains(roomId);

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: context.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient background
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.primary.withOpacity(0.1),
                  context.primary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
            ),
            child: Row(
              children: [
                // Avatar with enhanced design
                Container(
                  width: 56.w,
                  height: 56.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        context.primary,
                        context.primary.withOpacity(0.8),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: context.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isDirectChat ? Icons.person_rounded : Icons.group_rounded,
                    color: Colors.white,
                    size: 28.w,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Room name with better typography
                      Text(
                        roomName.isNotEmpty ? roomName : 'محادثة جديدة',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: context.primaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      // Invitation type with icon
                      Row(
                        children: [
                          Icon(
                            isDirectChat
                                ? Icons.chat_bubble_outline
                                : Icons.groups_outlined,
                            size: 16.w,
                            color: context.primary,
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              isDirectChat
                                  ? 'دعوة محادثة خاصة'
                                  : 'دعوة انضمام لمجموعة',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: context.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Time badge
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: context.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    _formatTime(timestamp),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: context.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content area
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Inviter info
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: context.surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_pin,
                        size: 20.w,
                        color: context.primary,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'دعوة من: ',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: context.secondaryText,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          inviterDisplayName.isNotEmpty
                              ? inviterDisplayName
                              : 'مستخدم غير معروف',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: context.primaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Additional info for groups
                if (!isDirectChat) ...[
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 18.w,
                        color: context.accent,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '$memberCount عضو في المجموعة',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: context.secondaryText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],

                // Room topic
                if (roomTopic != null && roomTopic.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: context.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: context.accent.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16.w,
                              color: context.accent,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'وصف المجموعة:',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: context.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          roomTopic,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: context.primaryText,
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 20.h),

                // Enhanced action buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: context.error.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isProcessing
                                ? null
                                : () => _handleInvitation(roomId, false),
                            borderRadius: BorderRadius.circular(12.r),
                            child: Container(
                              alignment: Alignment.center,
                              child: isProcessing
                                  ? SizedBox(
                                      height: 20.h,
                                      width: 20.w,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                context.error),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.close_rounded,
                                          color: context.error,
                                          size: 20.w,
                                        ),
                                        SizedBox(width: 8.w),
                                        Text(
                                          'رفض',
                                          style: TextStyle(
                                            color: context.error,
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Container(
                        height: 48.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              context.accent,
                              context.accent.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: context.accent.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isProcessing
                                ? null
                                : () => _handleInvitation(roomId, true),
                            borderRadius: BorderRadius.circular(12.r),
                            child: Container(
                              alignment: Alignment.center,
                              child: isProcessing
                                  ? SizedBox(
                                      height: 20.h,
                                      width: 20.w,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: 20.w,
                                        ),
                                        SizedBox(width: 8.w),
                                        Text(
                                          'قبول',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ساعة';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }
}
