import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:matrix/matrix.dart';
import 'package:path_provider/path_provider.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/core/services/matrix_call_service.dart';
import 'package:private_4t_app/core/services/matrix_messages_repository.dart';
import 'package:private_4t_app/core/services/matrix_notifications_bridge.dart';
import 'package:private_4t_app/core/services/navigation_service.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';
import 'package:video_player/video_player.dart';
import 'package:open_filex/open_filex.dart';

class RoomTimelineScreen extends ConsumerStatefulWidget {
  final String roomId;

  const RoomTimelineScreen({super.key, required this.roomId});

  @override
  ConsumerState<RoomTimelineScreen> createState() => _RoomTimelineScreenState();
}

class _RoomTimelineScreenState extends ConsumerState<RoomTimelineScreen>
    with AnalyticsScreenMixin {
  @override
  String get screenName => 'RoomTimelineScreen';

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _messageCtrl = TextEditingController();
  Timeline? _timeline;

  // Using simple ListView rendering for stability
  final GlobalKey _listKey = GlobalKey();
  StreamSubscription? _sub;
  StreamSubscription? _incSub;
  bool _isTyping = false;
  Event? _replyTo;
  bool _loadingMore = false;
  bool _hasMore = true;

  // Search state
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isSearching = false;
  final Map<String, GlobalKey> _eventKeys = {};
  List<String> _matchIds = const [];
  int _matchIndex = 0;

  // Voice recording
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordingPath;
  DateTime? _recordStartedAt;
  Timer? _recordTimer;
  Duration _recordElapsed = Duration.zero;
  bool _hasPendingVoice = false;
  final AudioPlayer _previewPlayer = AudioPlayer();
  bool _isPreviewPlaying = false;
  Duration _previewPos = Duration.zero;
  Duration _previewDur = Duration.zero;

  // Minimum number of displayable messages we try to keep loaded
  static const int _minVisibleTarget = 30;
  bool _rebuildScheduled = false;
  int _noGrowthTries = 0; // consecutive history requests with no new events
  // REST backfill state
  String? _restFromToken; // pagination token from REST API
  bool _restExhausted = false;

  bool _isDisplayable(Event ev, Timeline t) {
    final display = ev.getDisplayEvent(t);
    return display.type == EventTypes.Message ||
        display.type == EventTypes.Sticker;
  }

  List<Event> _visibleEvents() {
    final t = _timeline;
    if (t == null) return const [];
    return t.events.where((e) => _isDisplayable(e, t)).toList();
  }

  Future<void> _loadMoreVisible(
      {int minNewVisible = 15, int maxRequests = 8}) async {
    final t = _timeline;
    if (t == null || _loadingMore || !_hasMore) return;
    _loadingMore = true;
    int prevVisible = _visibleEvents().length;
    int prevEventsLen = t.events.length;
    try {
      for (int i = 0; i < maxRequests; i++) {
        // First try SDK backfill briefly
        bool grew = false;
        try {
          final before = t.events.length;
          await t.requestHistory().timeout(const Duration(seconds: 2));
          grew = t.events.length > before;
        } catch (_) {
          grew = false;
        }
        // If SDK didn't add anything, attempt REST backfill
        if (!grew && !_restExhausted) {
          await _backfillViaRest(t);
        }
        final nowVisible = _visibleEvents().length;
        final nowEventsLen = t.events.length;
        if (nowEventsLen == prevEventsLen) {
          // no new events; increment consecutive counter and only stop after two hits
          _noGrowthTries += 1;
          if (_noGrowthTries >= 2) {
            _hasMore = false; // likely reached start of history
            break;
          }
        } else {
          _noGrowthTries = 0; // reset on growth
        }
        if (nowVisible - prevVisible >= minNewVisible) {
          break;
        }
        prevEventsLen = nowEventsLen;
      }
    } finally {
      _loadingMore = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _backfillViaRest(Timeline t) async {
    try {
      final repo = ref.read(matrixMessagesRepositoryProvider);
      final res = await repo.fetchRoomMessages(
        roomId: widget.roomId,
        from: _restFromToken,
        dir: 'b',
        limit: 1000,
      );
      final chunk =
          (res['chunk'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      _restFromToken = res['end'] as String?; // next page token
      if (chunk.isEmpty || _restFromToken == null) {
        _restExhausted = true;
        return;
      }
      // Inject minimal synthetic events into timeline as text placeholders if SDK missed them.
      // We only add message-like events so UI can display them.
      for (final m in chunk) {
        final type = (m['type'] ?? '').toString();
        if (type != 'm.room.message' && type != 'm.sticker') continue;
        final content = (m['content'] as Map?)?.cast<String, dynamic>() ?? {};
        final body = (content['body'] ?? '').toString();
        final eventId = (m['event_id'] ?? '').toString();
        final tsMs = (m['origin_server_ts'] as num?)?.toInt() ?? 0;
        if (eventId.isEmpty || body.isEmpty || tsMs == 0) continue;
        // Create a lightweight local event if the SDK didn't provide it.
        final exists = t.events.any((e) => e.eventId == eventId);
        if (exists) continue;
        // Use Room.addLocalEcho to insert a local echo-like event (as fallback)
        // then immediately mark it as synced by cloning an Event via display body.
        // We cannot inject arbitrary remote history into SDK cleanly.
        // For now, we skip injection and rely on REST backfill recognition in future rendering.
      }
    } catch (_) {
      // ignore REST errors silently; SDK will continue
    }
  }

  Future<bool> _checkImageAvailable(String url, String? token) async {
    try {
      final uri = Uri.parse(url);
      final client = HttpClient();
      final req = await client.headUrl(uri);
      if (token != null) {
        req.headers.set('Authorization', 'Bearer $token');
      }
      final res = await req.close();
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  void _scheduleRebuild(Room room) {
    if (_rebuildScheduled) return;
    _rebuildScheduled = true;
    Future.delayed(const Duration(milliseconds: 60), () {
      if (!mounted) return;
      _rebuildScheduled = false;
      setState(() {});
      unawaited(_markReadLatest(room));
      // Auto-top-up visible messages in background if still below target
      _ensureVisibleTarget();
    });
  }

  void _ensureVisibleTarget() {
    final t = _timeline;
    if (t == null) return;
    final visible = _visibleEvents().length;
    if (visible < _minVisibleTarget && !_loadingMore && _hasMore) {
      final need = (_minVisibleTarget - visible).clamp(5, _minVisibleTarget);
      unawaited(_loadMoreVisible(minNewVisible: need));
    }
  }

  @override
  void initState() {
    super.initState();
    _init();
    // Mark this room active for notification suppression
    MatrixNotificationsBridge.setRoomActive(widget.roomId, true);
  }

  Widget _buildReactionsRow(Event ev) {
    final t = _timeline;
    if (t == null) return const SizedBox.shrink();
    // Collect reactions targeting this event id
    final targetId = ev.eventId;
    final Map<String, int> counter = {};
    for (final e in t.events) {
      if (e.type != EventTypes.Reaction) continue;
      final relates = e.content.tryGetMap<String, Object?>("m.relates_to");
      if (relates == null) continue;
      final relType = relates.tryGet<String>('rel_type');
      final eventId = relates.tryGet<String>('event_id');
      final key = relates.tryGet<String>('key');
      if (relType == 'm.annotation' && eventId == targetId && key != null) {
        counter[key] = (counter[key] ?? 0) + 1;
      }
    }
    if (counter.isEmpty) return _reactionActions(ev);
    final chips = counter.entries.map((e) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
        margin: EdgeInsetsDirectional.only(end: 6.w),
        decoration: BoxDecoration(
          color: const Color(0xFFEFEFEF),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(e.key, style: TextStyle(fontSize: 12.sp)),
            SizedBox(width: 4.w),
            Text('${e.value}',
                style: TextStyle(fontSize: 10.sp, color: Colors.grey[700])),
          ],
        ),
      );
    }).toList();
    return Row(children: [
      ...chips,
      _reactionActions(ev),
    ]);
  }

  Widget _reactionActions(Event ev) {
    return PopupMenuButton<String>(
      itemBuilder: (context) => [
        const PopupMenuItem(value: '👍', child: Text('👍')),
        const PopupMenuItem(value: '❤️', child: Text('❤️')),
        const PopupMenuItem(value: '😂', child: Text('😂')),
        const PopupMenuItem(value: '🎉', child: Text('🎉')),
        const PopupMenuItem(value: '👎', child: Text('👎')),
      ],
      onSelected: (key) async {
        final room = ev.room;
        final id = ev.eventId;
        try {
          await room.sendReaction(id, key);
          if (mounted) setState(() {});
        } catch (_) {}
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Icon(Icons.add_reaction_outlined,
            size: 18.sp, color: Colors.grey[700]),
      ),
    );
  }

  Future<void> _init() async {
    final matrix = ref.read(ApiProviders.matrixChatProvider);
    final room = matrix.client.getRoomById(widget.roomId);
    if (room == null) return;
    final timeline = await room.getTimeline(
      limit: 20000,
      // fetch larger window to reduce incremental loads
      // Throttle rebuilds to avoid jank
      onInsert: (i) => _scheduleRebuild(room),
      onRemove: (i) => _scheduleRebuild(room),
      onChange: (i) => _scheduleRebuild(room),
      onUpdate: () => _scheduleRebuild(room),
    );
    setState(() => _timeline = timeline);
    // mark read on open
    unawaited(_markReadLatest(room));
    // Ensure initial set contains enough displayable events
    _hasMore = true;
    if (_visibleEvents().length < _minVisibleTarget) {
      await _loadMoreVisible(minNewVisible: _minVisibleTarget);
    }
  }

  // _onTimelineUpdated retained for clarity in callbacks; consolidated via _scheduleRebuild

  Future<void> _markReadLatest(Room room) async {
    final t = _timeline;
    if (t == null || t.events.isEmpty) return;
    // pick the newest event by timestamp
    Event? latest;
    for (final e in t.events) {
      if (latest == null || e.originServerTs.isAfter(latest.originServerTs)) {
        latest = e;
      }
    }
    final id = latest?.eventId;
    if (id == null) return;
    try {
      await room.setReadMarker(id, mRead: id);
    } catch (_) {
      try {
        await room.postReceipt(id);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    MatrixNotificationsBridge.setRoomActive(widget.roomId, false);
    _sub?.cancel();
    _incSub?.cancel();
    _messageCtrl.dispose();
    _searchCtrl.dispose();
    if (_isRecording) {
      unawaited(_audioRecorder.stop());
    }
    _recordTimer?.cancel();
    unawaited(_previewPlayer.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matrix = ref.watch(ApiProviders.matrixChatProvider);
    final room = matrix.clientNullable?.getRoomById(widget.roomId);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: Text(
            room?.getLocalizedDisplayname() ?? 'الدردشة',
            style: TextStyle(fontSize: 15.sp, color: Colors.white),
          ),
          actions: [
            IconButton(
              tooltip: 'بحث',
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchCtrl.clear();
                    _matchIds = const [];
                  }
                });
              },
            ),
            if (room != null && room.membership == Membership.join)
              IconButton(
                tooltip: 'مكالمة صوتية',
                icon: const Icon(Icons.call),
                onPressed: () => _startMatrixVoiceCall(room),
              ),
            IconButton(
              tooltip: 'معلومات',
              icon: const Icon(Icons.info_outline),
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
          ],
        ),
        body: Column(
          children: [
            if (_isSearching) _buildSearchBar(),
            Expanded(child: _buildTimeline()),
            _buildComposer(room),
          ],
        ),
        endDrawer: _buildEndDrawer(room),
      ),
    );
  }

  Widget _buildSearchBar() {
    final total = _matchIds.length;
    final current = total == 0 ? 0 : (_matchIndex + 1);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: const BoxDecoration(color: Color(0xFFF7F7F7)),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'ابحث في الرسائل...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (q) => _updateSearchMatches(q),
            ),
          ),
          SizedBox(width: 8.w),
          Text('$current/$total'),
          IconButton(
            tooltip: 'السابق',
            icon: const Icon(Icons.keyboard_arrow_up),
            onPressed: total == 0
                ? null
                : () {
                    setState(() {
                      _matchIndex = (_matchIndex - 1) % total;
                      if (_matchIndex < 0) _matchIndex += total;
                    });
                    _scrollToMatch();
                  },
          ),
          IconButton(
            tooltip: 'التالي',
            icon: const Icon(Icons.keyboard_arrow_down),
            onPressed: total == 0
                ? null
                : () {
                    setState(() {
                      _matchIndex = (_matchIndex + 1) % total;
                    });
                    _scrollToMatch();
                  },
          ),
        ],
      ),
    );
  }

  void _updateSearchMatches(String query) {
    final t = _timeline;
    if (t == null || query.trim().isEmpty) {
      setState(() {
        _matchIds = const [];
        _matchIndex = 0;
      });
      return;
    }
    final q = query.trim().toLowerCase();
    final ids = <String>[];
    for (final e in t.events) {
      if (e.type != EventTypes.Message && e.type != EventTypes.Sticker)
        continue;
      String text = '';
      try {
        final body = e.getDisplayEvent(t).body;
        text = body.toString().toLowerCase();
      } catch (_) {
        text = '';
      }
      if (text.contains(q)) ids.add(e.eventId);
    }
    setState(() {
      _matchIds = ids;
      _matchIndex = 0;
    });
    if (ids.isNotEmpty) _scrollToMatch();
  }

  Future<void> _scrollToMatch() async {
    if (_matchIds.isEmpty) return;
    final id = _matchIds[_matchIndex];
    final key = _eventKeys[id];
    if (key?.currentContext != null) {
      await Scrollable.ensureVisible(
        key!.currentContext!,
        alignment: 0.3,
        duration: const Duration(milliseconds: 250),
      );
    } else {
      // If the target isn't built yet, try loading more history and retry once
      if (_hasMore && !_loadingMore) {
        _loadingMore = true;
        final prev = _timeline?.events.length ?? 0;
        await _timeline?.requestHistory();
        _loadingMore = false;
        if ((_timeline?.events.length ?? 0) > prev) {
          await Future.delayed(const Duration(milliseconds: 50));
          _scrollToMatch();
        }
      }
    }
  }

  Widget _buildTimeline() {
    final t = _timeline;
    if (t == null) {
      return const Center(child: CircularProgressIndicator());
    }
    // If no visible events after attempts, show friendly empty state instead of spinner
    final visibleCount = t.events.where((e) => _isDisplayable(e, t)).length;
    return Column(
      children: [
        if (!_hasMore && visibleCount == 0)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Text(
              'لا توجد رسائل لعرضها',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
          )
        else if (!_hasMore)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 6.h),
            child: Text(
              'تم تحميل كل الرسائل',
              style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
            ),
          ),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is! ScrollUpdateNotification) return false;
              final metrics = n.metrics;
              final nearTop = metrics.pixels <= metrics.minScrollExtent + 24.h;
              final scrollingUp = (n.scrollDelta ?? 0) <
                  0; // negative delta means up for reversed list
              if (nearTop && scrollingUp && !_loadingMore && _hasMore) {
                // Aggressively fetch more until at least 20 new visible or no more history
                _loadMoreVisible(minNewVisible: 20);
              }
              return false;
            },
            child: Stack(
              children: [
                Builder(builder: (context) {
                  // Pre-filter visible events to avoid building empty items
                  final visible = t.events.where((ev) {
                    final display = ev.getDisplayEvent(t);
                    // Render only message-like events; hide system/call/reaction/etc
                    return display.type == EventTypes.Message ||
                        display.type == EventTypes.Sticker;
                  }).toList();
                  return ListView.builder(
                    key: _listKey,
                    reverse: true,
                    itemCount: visible.length,
                    itemBuilder: (context, i) {
                      final ev = visible[i];
                      final isMine = ev.senderId == t.room.client.userID;
                      final bubbleKey =
                          _eventKeys.putIfAbsent(ev.eventId, () => GlobalKey());
                      return KeyedSubtree(
                        key: bubbleKey,
                        child: Align(
                          alignment: isMine
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                          child: GestureDetector(
                            onLongPress: () => _openActions(ev),
                            child: Container(
                              margin: EdgeInsets.symmetric(
                                  horizontal: 8.w, vertical: 4.h),
                              padding: EdgeInsets.all(10.w),
                              decoration: BoxDecoration(
                                color: isMine
                                    ? const Color(0xFFE8F5E9)
                                    : const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: _buildMessageBubble(ev),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
                if (_loadingMore)
                  Positioned(
                    top: 6.h,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: SizedBox(
                        height: 16.h,
                        width: 16.w,
                        child: CircularProgressIndicator(strokeWidth: 2.w),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventBubble(Event ev) {
    final children = <Widget>[];
    // Only render message-like content (suppress system/state texts)
    // Read indicator and sender header
    final isMine = ev.senderId == ev.room.client.userID;
    final status = ev.status; // EventStatus
    if (!isMine) {
      children.add(_buildSenderHeader(ev));
      children.add(SizedBox(height: 4.h));
    }
    if (ev.relationshipType == RelationshipTypes.reply) {
      children.add(
        FutureBuilder<Event?>(
          future: _timeline == null ? null : ev.getReplyEvent(_timeline!),
          builder: (context, snap) {
            final preview = snap.data;
            if (preview == null) return const SizedBox.shrink();
            final text = preview.getDisplayEvent(_timeline!).body;
            return Container(
              padding: EdgeInsets.all(6.w),
              margin: EdgeInsets.only(bottom: 6.h),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.black,
                ),
              ),
            );
          },
        ),
      );
    }
    if (ev.messageType == MessageTypes.Image && ev.content['url'] is String) {
      final mxc = Uri.parse(ev.content['url'] as String);
      final url = mxc.getDownloadUri(ev.room.client);
      final info = ev.content.tryGetMap<String, Object?>('info');
      final imgW = (info?.tryGet<num>('w')?.toDouble()) ?? 0;
      final imgH = (info?.tryGet<num>('h')?.toDouble()) ?? 0;
      final screenW = MediaQuery.of(context).size.width;
      final maxW = screenW * 0.72;
      final maxH = 260.h;
      final aspect = (imgW > 0 && imgH > 0) ? (imgW / imgH) : null;
      children.addAll([
        FutureBuilder<Uri>(
          future: url,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return SizedBox(height: 140.h, width: maxW);
            final uri = snapshot.data!;
            final token = ev.room.client.accessToken;
            final image = FutureBuilder<bool>(
              future: _checkImageAvailable(uri.toString(), token ?? ''),
              builder: (context, s) {
                final ok = s.data == true;
                if (!ok) {
                  return Container(
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  );
                }
                return Image.network(
                  uri.toString(),
                  fit: BoxFit.cover,
                  headers: token == null
                      ? null
                      : {
                          'Authorization': 'Bearer $token',
                        },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    );
                  },
                );
              },
            );
            Widget sized;
            if (aspect != null) {
              sized = ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
                child: AspectRatio(
                  aspectRatio: aspect,
                  child: image,
                ),
              );
            } else {
              sized = ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
                child: image,
              );
            }
            return ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: sized,
            );
          },
        ),
        if (ev.body.isNotEmpty) SizedBox(height: 6.h),
        if (ev.body.isNotEmpty)
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: Text(
              ev.body,
              style: const TextStyle(
                color: Colors.black,
              ),
            ),
          ),
      ]);
      return Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children);
    }
    // Stickers
    if (ev.type == EventTypes.Sticker && ev.content['url'] is String) {
      final mxc = Uri.parse(ev.content['url'] as String);
      final url = mxc.getDownloadUri(ev.room.client);
      final screenW = MediaQuery.of(context).size.width;
      final maxW = screenW * 0.6;
      final maxH = 180.h;
      children.add(
        FutureBuilder<Uri>(
          future: url,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return SizedBox(height: 120.h, width: maxW);
            final u = snapshot.data.toString();
            final token = ev.room.client.accessToken;
            return ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
              child: FutureBuilder<bool>(
                future: _checkImageAvailable(u, token ?? ''),
                builder: (context, s) {
                  final ok = s.data == true;
                  if (!ok) {
                    return Container(
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    );
                  }
                  return Image.network(
                    u,
                    fit: BoxFit.contain,
                    headers: token == null
                        ? null
                        : {
                            'Authorization': 'Bearer $token',
                          },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      );
      return Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children);
    }
    // Audio / Video / File quick preview with open action
    if (ev.messageType == MessageTypes.Video ||
        ev.messageType == MessageTypes.File) {
      final fileName = ev.content.tryGet<String>('body') ?? 'ملف';
      final icon = ev.messageType == MessageTypes.Video
          ? Icons.videocam
          : Icons.insert_drive_file;
      children.add(Row(children: [
        Icon(icon, size: 18.sp),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black,
            ),
          ),
        ),
        TextButton(onPressed: () => _openMedia(ev), child: const Text('فتح'))
      ]));
      return Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children);
    }
    if (ev.messageType == MessageTypes.Audio) {
      children.add(_InlineAudioPlayer(event: ev));
      return Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children);
    }
    if (ev.messageType == MessageTypes.Video) {
      final fileName = ev.content.tryGet<String>('body') ?? 'فيديو';
      children.add(Row(children: [
        Icon(Icons.videocam, size: 18.sp),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black,
            ),
          ),
        ),
      ]));
      return Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children);
    }
    if (ev.messageType == MessageTypes.File) {
      final fileName = ev.content.tryGet<String>('body') ?? 'ملف';
      children.add(Row(children: [
        Icon(Icons.insert_drive_file, size: 18.sp),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black,
            ),
          ),
        ),
      ]));
      // footer: sending/sent indicator for own messages
      if (isMine) {
        children.add(SizedBox(height: 4.h));
        children.add(_buildStatusRow(status));
      }
      return Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children);
    }
    String bodyText;
    try {
      final body = ev.getDisplayEvent(_timeline!).body;
      bodyText = body.toString();
    } catch (_) {
      bodyText = '';
    }
    final maybeCallUrl = _extractCallUrl(bodyText);
    if (maybeCallUrl != null) {
      children.add(_buildCallCard(maybeCallUrl));
    } else {
      // Not Mine Text Message Body
      children.add(_buildLinkifiedText(
        bodyText,
        textColor: Colors.black,
      ));
    }
    // Reactions bar (aggregate m.reaction for this event)
    children.add(SizedBox(height: 6.h));
    children.add(_buildReactionsRow(ev));
    if (isMine) {
      children.add(SizedBox(height: 4.h));
      children.add(_buildStatusRow(status));
    }
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  // Build text with clickable links
  Widget _buildLinkifiedText(String text, {Color? textColor}) {
    // Regex pattern to match URLs
    final urlPattern = RegExp(
      r'(?:(?:https?|ftp):\/\/)?(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)',
      caseSensitive: false,
    );

    final matches = urlPattern.allMatches(text);
    if (matches.isEmpty) {
      return Text(
        text,
        style: TextStyle(color: textColor ?? Colors.black),
      );
    }

    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      // Add text before the link
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: TextStyle(color: textColor ?? Colors.black),
        ));
      }

      // Add the link
      final url = match.group(0)!;
      spans.add(TextSpan(
        text: url,
        style: TextStyle(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () async {
            String urlToLaunch = url;
            if (!url.startsWith('http://') && !url.startsWith('https://')) {
              urlToLaunch = 'https://$url';
            }
            final uri = Uri.parse(urlToLaunch);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
      ));

      lastEnd = match.end;
    }

    // Add remaining text after the last link
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: TextStyle(color: textColor ?? Colors.black),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  // Build message bubble
  Widget _buildMessageBubble(Event ev) {
    final t = _timeline;
    if (t == null) return const SizedBox.shrink();

    final isMine = ev.senderId == ev.room.client.userID;
    final children = <Widget>[];

    // Sender header for others' messages
    if (!isMine) {
      children.add(_buildSenderHeader(ev));
      children.add(SizedBox(height: 4.h));
    }

    // Reply preview
    if (ev.relationshipType == RelationshipTypes.reply) {
      children.add(
        FutureBuilder<Event?>(
          future: t == null ? null : ev.getReplyEvent(t),
          builder: (context, snap) {
            final preview = snap.data;
            if (preview == null) return const SizedBox.shrink();
            final text = preview.getDisplayEvent(t).body;
            return Container(
              padding: EdgeInsets.all(6.w),
              margin: EdgeInsets.only(bottom: 6.h),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.sp, color: Colors.black),
              ),
            );
          },
        ),
      );
    }

    // Image messages
    if (ev.messageType == MessageTypes.Image && ev.content['url'] is String) {
      children.add(_buildImageMessage(ev));
    }
    // Sticker messages
    else if (ev.type == EventTypes.Sticker && ev.content['url'] is String) {
      children.add(_buildStickerMessage(ev));
    }
    // Audio messages
    else if (ev.messageType == MessageTypes.Audio) {
      children.add(_buildAudioMessage(ev));
    }
    // Video messages
    else if (ev.messageType == MessageTypes.Video) {
      children.add(_buildVideoMessage(ev));
    }
    // File messages
    else if (ev.messageType == MessageTypes.File) {
      children.add(_buildFileMessage(ev));
    }
    // Location messages
    else if (ev.messageType == MessageTypes.Location) {
      children.add(_buildLocationMessage(ev));
    }
    // Text messages
    else {
      String bodyText;
      try {
        final body = ev.getDisplayEvent(t).body;
        bodyText = body.toString();
      } catch (_) {
        bodyText = '';
      }
      children.add(_buildLinkifiedText(
        bodyText,
        textColor: Colors.black,
      ));
    }

    // Reactions
    children.add(SizedBox(height: 6.h));
    children.add(_buildReactionsRow(ev));

    // Status for own messages
    if (isMine) {
      children.add(SizedBox(height: 4.h));
      children.add(_buildStatusRow(ev.status));
    }

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  Widget _buildImageMessage(Event ev) {
    final mxc = Uri.parse(ev.content['url'] as String);
    final url = mxc.getDownloadUri(ev.room.client);
    final info = ev.content.tryGetMap<String, Object?>('info');
    final imgW = (info?.tryGet<num>('w')?.toDouble()) ?? 0;
    final imgH = (info?.tryGet<num>('h')?.toDouble()) ?? 0;
    final screenW = MediaQuery.of(context).size.width;
    final maxW = screenW * 0.72;
    final maxH = 260.h;
    final aspect = (imgW > 0 && imgH > 0) ? (imgW / imgH) : null;

    return FutureBuilder<Uri>(
      future: url,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox(height: 140.h, width: maxW);
        final uri = snapshot.data!;
        final token = ev.room.client.accessToken;

        final image = Image.network(
          uri.toString(),
          fit: BoxFit.cover,
          headers: token == null ? null : {'Authorization': 'Bearer $token'},
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade200,
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image, color: Colors.grey),
            );
          },
        );

        Widget sized;
        if (aspect != null) {
          sized = ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
            child: AspectRatio(aspectRatio: aspect, child: image),
          );
        } else {
          sized = ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
            child: image,
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(10.r),
          child: sized,
        );
      },
    );
  }

  Widget _buildStickerMessage(Event ev) {
    final mxc = Uri.parse(ev.content['url'] as String);
    final url = mxc.getDownloadUri(ev.room.client);
    final screenW = MediaQuery.of(context).size.width;
    final maxW = screenW * 0.6;
    final maxH = 180.h;

    return FutureBuilder<Uri>(
      future: url,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox(height: 120.h, width: maxW);
        final u = snapshot.data.toString();
        final token = ev.room.client.accessToken;

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
          child: Image.network(
            u,
            fit: BoxFit.contain,
            headers: token == null ? null : {'Authorization': 'Bearer $token'},
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child:
                    const Icon(Icons.image_not_supported, color: Colors.grey),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAudioMessage(Event ev) {
    return _InlineAudioPlayer(event: ev);
  }

  Widget _buildVideoMessage(Event ev) {
    return _InlineVideoPlayer(event: ev);
  }

  Widget _buildFileMessage(Event ev) {
    final fileName = ev.content.tryGet<String>('body') ?? 'ملف';
    final info = ev.content.tryGetMap<String, Object?>('info');
    final size = info?.tryGet<num>('size')?.toDouble() ?? 0;

    String sizeStr = '';
    if (size > 0) {
      if (size < 1024) {
        sizeStr = '${size.toStringAsFixed(0)} B';
      } else if (size < 1024 * 1024) {
        sizeStr = '${(size / 1024).toStringAsFixed(1)} KB';
      } else {
        sizeStr = '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    }

    IconData fileIcon = _getFileIcon(fileName);

    return InkWell(
      onTap: () => _downloadAndOpenFile(ev),
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(fileIcon, size: 24.sp, color: Colors.blue.shade700),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (sizeStr.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      sizeStr,
                      style:
                          TextStyle(fontSize: 10.sp, color: Colors.grey[700]),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Column(
              children: [
                Icon(Icons.download, color: Colors.blue, size: 20.sp),
                SizedBox(height: 2.h),
                Text(
                  'فتح',
                  style: TextStyle(fontSize: 9.sp, color: Colors.blue),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
        return Icons.archive;
      case 'mp3':
      case 'wav':
      case 'm4a':
        return Icons.audiotrack;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Widget _buildLocationMessage(Event ev) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(Icons.place, color: Colors.blue, size: 20.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'الموقع',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => _openLocation(ev),
            child: const Text('عرض'),
          )
        ],
      ),
    );
  }

  Future<void> _openMedia(Event ev) async {
    final urlStr = ev.content.tryGet<String>('url');
    if (urlStr == null) return;

    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20.w,
                height: 20.h,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16.w),
              const Text('جاري الفتح...'),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    try {
      await _downloadAndOpenFile(ev);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل فتح الملف: $e')),
        );
      }
    }
  }

  Future<void> _downloadAndOpenFile(Event ev) async {
    final urlStr = ev.content.tryGet<String>('url');
    if (urlStr == null) return;

    final mxc = Uri.parse(urlStr);
    final uri = await mxc.getDownloadUri(ev.room.client);
    final fileName = ev.content.tryGet<String>('body') ?? 'ملف';

    try {
      // Download the file
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${ev.room.client.accessToken}',
        },
      );

      if (response.statusCode == 200) {
        // Save to temporary directory
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Open with open_filex
        final result = await OpenFilex.open(filePath);

        if (mounted) {
          if (result.type != ResultType.done) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تعذر فتح الملف: ${result.message}'),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          }
        }
      } else {
        throw Exception('خطأ في تحميل الملف');
      }
    } catch (e) {
      // Fallback: try to open URL directly
      if (mounted && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        rethrow;
      }
    }
  }

  Future<void> _openLocation(Event ev) async {
    String? geo = ev.content.tryGet<String>('geo_uri');
    debugPrint("geo => $geo");
    if (geo == null) return;
    geo = geo.replaceAll('geo:', '').trim();
    final goLocation = geo.split(',');
    if (goLocation.length != 2) return;
    final latitude = goLocation[0].trim();
    final longitude = goLocation[1].trim();

    final uri =
        Uri.parse('https://maps.google.com?q=$latitude,$longitude&z=16');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildSenderHeader(Event ev) {
    final name = ev.sender.calcDisplayname();
    final avatar = ev.sender.avatarUrl;

    if (avatar == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12.r,
            backgroundColor: Colors.blueGrey.shade100,
            child: Text(
              name.isNotEmpty ? name[0] : '?',
              style: TextStyle(fontSize: 12.sp, color: Colors.black87),
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            name,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      );
    }

    return FutureBuilder<Uri>(
      future: (() async {
        try {
          return await avatar.getThumbnailUri(ev.room.client,
              width: 32, height: 32);
        } catch (_) {
          return Uri();
        }
      })(),
      builder: (context, snap) {
        final url = snap.data?.toString();
        final double diameter = 24.r;
        Widget avatarWidget;

        if (url == null || url.isEmpty) {
          avatarWidget = CircleAvatar(
            radius: 12.r,
            backgroundColor: Colors.blueGrey.shade100,
            child: Text(
              name.isNotEmpty ? name[0] : '?',
              style: TextStyle(fontSize: 12.sp, color: Colors.black87),
            ),
          );
        } else {
          final token = ev.room.client.accessToken;
          avatarWidget = ClipOval(
            child: Image.network(
              url,
              width: diameter,
              height: diameter,
              fit: BoxFit.cover,
              headers:
                  token == null ? null : {'Authorization': 'Bearer $token'},
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: diameter,
                  height: diameter,
                  color: Colors.blueGrey.shade100,
                  alignment: Alignment.center,
                  child: Text(
                    name.isNotEmpty ? name[0] : '?',
                    style: TextStyle(fontSize: 12.sp, color: Colors.black87),
                  ),
                );
              },
            ),
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            avatarWidget,
            SizedBox(width: 6.w),
            Text(
              name,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEndDrawer(Room? room) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          children: [
            if (room != null)
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('الأعضاء'),
                onTap: () {
                  Navigator.pop(context);
                  _showMembers(room);
                },
              ),
            if (room != null)
              ListTile(
                leading: const Icon(Icons.person_add_alt),
                title: const Text('دعوة مستخدم'),
                onTap: () {
                  Navigator.pop(context);
                  _promptInvite(room);
                },
              ),
            if (room != null)
              ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: const Text('الملفات'),
                onTap: () {
                  Navigator.pop(context);
                  _showFiles(room);
                },
              ),
            const Divider(),
            if (room != null)
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('نسخ رابط الغرفة'),
                onTap: () {
                  Navigator.pop(context);
                  _copyRoomLink(room);
                },
              ),
            ListTile(
              leading: const Icon(Icons.poll),
              title: const Text('إنشاء استطلاع'),
              onTap: () {
                Navigator.pop(context);
                if (room != null) _showPollComposer(room);
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_emotions_outlined),
              title: const Text('إرسال إيموجي'),
              onTap: () {
                Navigator.pop(context);
                if (room != null) _showEmojiPicker(room);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('تصدير المحادثة (قريبًا)'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startMatrixVoiceCall(Room room) async {
    NavigationService.navigateToCall(context, room.id);
    await ref
        .read(ApiProviders.matrixChatProvider)
        .calls
        ?.startCall(room, CallType.kVoice);
  }

  // removed didChangeDependencies listener; subscription happens once in initState

  Uri? _extractCallUrl(String body) {
    final exp = RegExp(r'https?:\/\/meet\.private-4t\.com\/[\w\-]+');
    final match = exp.firstMatch(body);
    if (match == null) return null;
    return Uri.tryParse(match.group(0)!);
  }

  Widget _buildCallCard(Uri url) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(Icons.call, color: Colors.blue, size: 20.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text('مكالمة صوتية',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () async {
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text('انضمام'),
          )
        ],
      ),
    );
  }

  Future<void> _promptInvite(Room room) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('دعوة مستخدم'),
        content: TextField(
          controller: controller,
          decoration:
              const InputDecoration(hintText: '@user:matrix.private-4t.com'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () async {
              final userId = controller.text.trim();
              if (userId.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await room.invite(userId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تمت الدعوة')),
                  );
                }
              } catch (_) {}
            },
            child: const Text('دعوة'),
          ),
        ],
      ),
    );
  }

  void _showMembers(Room room) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final members = room.getParticipants();
        return SafeArea(
          child: ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
              final m = members[index];
              final name = m.calcDisplayname();
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(name.isEmpty ? m.id : name),
                subtitle: Text(m.id),
              );
            },
          ),
        );
      },
    );
  }

  void _showFiles(Room room) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final files = _timeline?.events
            .where((e) =>
                e.messageType == MessageTypes.File ||
                e.messageType == MessageTypes.Audio ||
                e.messageType == MessageTypes.Video ||
                e.messageType == MessageTypes.Image)
            .toList()
            .reversed
            .toList();
        final list = files ?? const <Event>[];
        return SafeArea(
          child: ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final e = list[index];
              final name = e.content.tryGet<String>('body') ?? e.body;
              return ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: Text(name),
                onTap: () => _openMedia(e),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _copyRoomLink(Room room) async {
    final alias = room.canonicalAlias;
    final link = (alias.isNotEmpty) ? '#$alias' : room.id;
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ رابط الغرفة')),
    );
  }

  Widget _buildStatusRow(EventStatus status) {
    if (status.isSending) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.schedule, size: 12.sp, color: Colors.grey),
        SizedBox(width: 4.w),
        Text('جاري الإرسال',
            style: TextStyle(fontSize: 10.sp, color: Colors.grey))
      ]);
    }
    if (!status.isSynced) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check, size: 12.sp, color: Colors.grey),
        SizedBox(width: 4.w),
        Text('تم الإرسال',
            style: TextStyle(fontSize: 10.sp, color: Colors.grey))
      ]);
    }
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.done_all, size: 12.sp, color: Colors.blue),
      SizedBox(width: 4.w),
      Text('تمت المزامنة',
          style: TextStyle(fontSize: 10.sp, color: Colors.blue))
    ]);
  }

  Widget _buildComposer(Room? room) {
    if (room == null) return const SizedBox.shrink();
    return SafeArea(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isRecording) _buildRecordingBar(),
            if (!_isRecording && _hasPendingVoice) _buildRecordingPreview(room),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo),
                  onPressed: () => _pickAndSendImage(room),
                ),
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: () => _showAttachMenu(room),
                ),
                IconButton(
                  tooltip: _isRecording ? 'إيقاف' : 'تسجيل صوتي',
                  icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                  onPressed: () async {
                    if (_isRecording) {
                      await _stopVoiceRecording();
                    } else {
                      await _startVoiceRecording();
                    }
                    setState(() {});
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageCtrl,
                    onChanged: (v) {
                      final nowTyping = v.isNotEmpty;
                      if (nowTyping != _isTyping) {
                        _isTyping = nowTyping;
                        room.setTyping(_isTyping, timeout: 5000);
                      }
                    },
                    decoration: const InputDecoration(
                      hintText: 'اكتب رسالة...',
                      border: InputBorder.none,
                    ),
                    minLines: 1,
                    maxLines: 5,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendText(room),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingBar() {
    String two(int n) => n.toString().padLeft(2, '0');
    final mm = two(_recordElapsed.inMinutes);
    final ss = two(_recordElapsed.inSeconds % 60);
    final pulse = ((_recordElapsed.inMilliseconds ~/ 200) % 6) / 6.0;
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(Icons.mic, color: Colors.deepOrange, size: 20.sp),
          SizedBox(width: 8.w),
          Text('$mm:$ss', style: TextStyle(fontSize: 12.sp)),
          SizedBox(width: 12.w),
          Expanded(
            child: LinearProgressIndicator(
              value: pulse,
              minHeight: 4.h,
              backgroundColor: Colors.orange.shade100,
              color: Colors.deepOrange,
            ),
          ),
          SizedBox(width: 12.w),
          IconButton(
            tooltip: 'إيقاف',
            icon: const Icon(Icons.stop, color: Colors.red),
            onPressed: () async => _stopVoiceRecording(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingPreview(Room room) {
    String two(int n) => n.toString().padLeft(2, '0');
    final cur = _previewPos;
    final dur = _previewDur.inMilliseconds == 0
        ? (_recordElapsed == Duration.zero
            ? const Duration(seconds: 1)
            : _recordElapsed)
        : _previewDur;
    final posText = '${two(cur.inMinutes)}:${two(cur.inSeconds % 60)}';
    final durText = '${two(dur.inMinutes)}:${two(dur.inSeconds % 60)}';
    final ratio = dur.inMilliseconds == 0
        ? 0.0
        : (cur.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0);
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_isPreviewPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: () async {
              if (_isPreviewPlaying) {
                await _previewPlayer.pause();
                setState(() => _isPreviewPlaying = false);
              } else {
                await _previewPlayer.resume();
                setState(() => _isPreviewPlaying = true);
              }
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(value: ratio),
                SizedBox(height: 4.h),
                Text('$posText / $durText', style: TextStyle(fontSize: 10.sp)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'إرسال',
            icon: const Icon(Icons.send, color: Colors.green),
            onPressed: () async {
              await _sendPendingVoice(room);
            },
          ),
          IconButton(
            tooltip: 'إلغاء',
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () async {
              await _previewPlayer.stop();
              setState(() {
                _hasPendingVoice = false;
                _recordingPath = null;
                _isPreviewPlaying = false;
                _previewPos = Duration.zero;
                _previewDur = Duration.zero;
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _sendPendingVoice(Room room) async {
    if (!_hasPendingVoice || _recordingPath == null) return;
    final file = File(_recordingPath!);
    if (!await file.exists()) return;
    final bytes = await file.readAsBytes();
    final matrixFile = MatrixFile(
      bytes: bytes,
      name: 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
      mimeType: 'audio/m4a',
    );
    await room.sendFileEvent(matrixFile);
    await _previewPlayer.stop();
    setState(() {
      _hasPendingVoice = false;
      _recordingPath = null;
      _isPreviewPlaying = false;
      _previewPos = Duration.zero;
      _previewDur = Duration.zero;
    });
  }

  Future<void> _sendText(Room room) async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;
    await room.sendTextEvent(text, inReplyTo: _replyTo);
    _messageCtrl.clear();
    setState(() => _replyTo = null);
    if (_isTyping) {
      _isTyping = false;
      unawaited(room.setTyping(false));
    }
  }

  Future<void> _pickAndSendImage(Room room) async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    // Build Matrix image file (fills metadata/blurhash) and send via Room API (handles upload)
    final img = await MatrixImageFile.create(
      bytes: bytes,
      name: picked.name,
      mimeType: 'image/jpeg',
    );
    await room.sendFileEvent(img);
  }

  Future<void> _pickAndSendVideo(Room room) async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final matrixFile = MatrixFile(
      bytes: bytes,
      name: picked.name,
      mimeType: 'video/mp4',
    );
    await room.sendFileEvent(matrixFile);
  }

  Future<void> _pickAndSendFile(Room room) async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;

      // Handle file path if bytes are null (for large files)
      Uint8List? bytes;
      if (file.bytes != null) {
        bytes = file.bytes;
      } else if (file.path != null) {
        final fileObj = File(file.path!);
        if (await fileObj.exists()) {
          bytes = await fileObj.readAsBytes();
        }
      }

      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذر قراءة الملف')),
          );
        }
        return;
      }

      // Determine MIME type from extension
      String? mimeType;
      if (file.extension != null) {
        // Try to get MIME type from extension
        final ext = file.extension!.toLowerCase();
        mimeType = _getMimeTypeFromExtension(ext);
      }
      mimeType ??= 'application/octet-stream';

      final matrixFile = MatrixFile(
        bytes: bytes,
        name: file.name,
        mimeType: mimeType,
      );

      debugPrint(
          "Sending file: ${file.name}, size: ${bytes.lengthInBytes} bytes, mime: $mimeType");

      final res = await room.sendFileEvent(matrixFile);
      debugPrint("File sent successfully, result: $res");

      if (mounted && res == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال الملف بنجاح')),
        );
      }
    } catch (e, stack) {
      debugPrint("Error sending file: $e");
      debugPrintStack(stackTrace: stack);

      if (mounted) {
        String errorMessage = 'فشل إرسال الملف';
        if (e.toString().contains('FileTooBig')) {
          errorMessage = 'الملف كبير جداً';
        } else if (e.toString().contains('timeout') ||
            e.toString().contains('Timeout')) {
          errorMessage = 'انتهت مهلة الاتصال، حاول مرة أخرى';
        } else if (e.toString().contains('network') ||
            e.toString().contains('Network')) {
          errorMessage = 'خطأ في الاتصال بالشبكة';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Helper function to get MIME type from file extension
  String? _getMimeTypeFromExtension(String extension) {
    final mimeTypes = {
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx':
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'zip': 'application/zip',
      'rar': 'application/x-rar-compressed',
      'txt': 'text/plain',
      'rtf': 'application/rtf',
      'html': 'text/html',
      'css': 'text/css',
      'js': 'application/javascript',
      'json': 'application/json',
      'xml': 'application/xml',
      'mp3': 'audio/mpeg',
      'wav': 'audio/wav',
      'ogg': 'audio/ogg',
      'mp4': 'video/mp4',
      'avi': 'video/x-msvideo',
      'mov': 'video/quicktime',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
    };
    return mimeTypes[extension];
  }

  Future<void> _sendLocation(Room room) async {
    final perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.deniedForever ||
        perm == LocationPermission.denied) return;
    final pos = await Geolocator.getCurrentPosition();
    final geo = 'geo:${pos.latitude},${pos.longitude}';
    await room.sendLocation('موقعي', geo);
  }

  Future<void> _startVoiceRecording() async {
    if (_isRecording) return;
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) return;
    final tempDir = await getTemporaryDirectory();
    final filePath =
        '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _audioRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: filePath,
    );
    setState(() {
      _isRecording = true;
      _recordingPath = filePath;
      _hasPendingVoice = false;
      _recordStartedAt = DateTime.now();
      _recordElapsed = Duration.zero;
    });
    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted || !_isRecording || _recordStartedAt == null) return;
      setState(() {
        _recordElapsed = DateTime.now().difference(_recordStartedAt!);
      });
    });
  }

  Future<void> _stopVoiceRecording() async {
    if (!_isRecording) return;
    final path = await _audioRecorder.stop();
    _recordTimer?.cancel();
    setState(() {
      _isRecording = false;
      _hasPendingVoice = true;
      if (path != null) _recordingPath = path;
    });
    if (_recordingPath != null) {
      await _previewPlayer.setSource(DeviceFileSource(_recordingPath!));
      _previewPlayer.onDurationChanged.listen((d) {
        if (!mounted) return;
        setState(() => _previewDur = d);
      });
      _previewPlayer.onPositionChanged.listen((p) {
        if (!mounted) return;
        setState(() => _previewPos = p);
      });
      _previewPlayer.onPlayerComplete.listen((event) {
        if (!mounted) return;
        setState(() => _isPreviewPlaying = false);
      });
    }
  }

  void _showEmojiPicker(Room room) {
    const emojis = [
      '😀',
      '😁',
      '😂',
      '🤣',
      '😊',
      '😍',
      '😘',
      '😎',
      '😇',
      '🙂',
      '🤗',
      '🤩',
      '🤔',
      '😴',
      '😢',
      '😭',
      '😡',
      '👍',
      '👎',
      '🙏',
      '👏',
      '🔥',
      '✨',
      '❤️',
      '💯',
      '🎉',
      '🎈',
      '✅',
      '❌',
      '⚽',
      '🏀'
    ];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: GridView.builder(
          padding: EdgeInsets.all(12.w),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            mainAxisSpacing: 8.w,
            crossAxisSpacing: 8.w,
          ),
          itemCount: emojis.length,
          itemBuilder: (context, index) {
            final e = emojis[index];
            return InkWell(
              onTap: () {
                Navigator.pop(ctx);
                _messageCtrl.text += e;
                _messageCtrl.selection = TextSelection.fromPosition(
                  TextPosition(offset: _messageCtrl.text.length),
                );
              },
              child: Center(child: Text(e, style: TextStyle(fontSize: 24.sp))),
            );
          },
        ),
      ),
    );
  }

  void _showPollComposer(Room room) {
    final qCtrl = TextEditingController();
    final o1 = TextEditingController();
    final o2 = TextEditingController();
    final o3 = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إنشاء استطلاع'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: qCtrl,
                  decoration: const InputDecoration(hintText: 'السؤال')),
              SizedBox(height: 8.h),
              TextField(
                  controller: o1,
                  decoration: const InputDecoration(hintText: 'الخيار 1')),
              SizedBox(height: 8.h),
              TextField(
                  controller: o2,
                  decoration: const InputDecoration(hintText: 'الخيار 2')),
              SizedBox(height: 8.h),
              TextField(
                  controller: o3,
                  decoration:
                      const InputDecoration(hintText: 'الخيار 3 (اختياري)')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () async {
              final q = qCtrl.text.trim();
              final a = o1.text.trim();
              final b = o2.text.trim();
              final c = o3.text.trim();
              if (q.isEmpty || a.isEmpty || b.isEmpty) return;
              final pollText = StringBuffer()
                ..writeln('استطلاع: $q')
                ..writeln('1) $a')
                ..writeln('2) $b');
              if (c.isNotEmpty) pollText.writeln('3) $c');
              pollText.writeln('⟵ صوّت بإرسال رقم الخيار');
              await room.sendTextEvent(pollText.toString());
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
  }

  void _showAttachMenu(Room room) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('صورة'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndSendImage(room);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('فيديو'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndSendVideo(room);
              },
            ),
            ListTile(
              leading: const Icon(Icons.mic),
              title: Text(_isRecording ? 'إيقاف التسجيل' : 'بدء تسجيل صوتي'),
              onTap: () async {
                if (_isRecording) {
                  Navigator.pop(ctx);
                  await _stopVoiceRecording();
                } else {
                  await _startVoiceRecording();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.poll),
              title: const Text('استطلاع'),
              onTap: () {
                Navigator.pop(ctx);
                _showPollComposer(room);
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_emotions_outlined),
              title: const Text('إيموجي'),
              onTap: () {
                Navigator.pop(ctx);
                _showEmojiPicker(room);
              },
            ),
            ListTile(
              leading: const Icon(Icons.place),
              title: const Text('الموقع'),
              onTap: () {
                Navigator.pop(ctx);
                _sendLocation(room);
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('ملف'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndSendFile(room);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openActions(Event ev) {
    final isMine = ev.senderId == ev.room.client.userID;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('رد'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _replyTo = ev);
              },
            ),
            if (isMine)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('حذف'),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    await ev.redactEvent();
                    setState(() {});
                  } catch (_) {}
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _InlineAudioPlayer extends StatefulWidget {
  final Event event;

  const _InlineAudioPlayer({required this.event});

  @override
  State<_InlineAudioPlayer> createState() => _InlineAudioPlayerState();
}

class _InlineAudioPlayerState extends State<_InlineAudioPlayer> {
  final AudioPlayer _player = AudioPlayer();
  Duration _pos = Duration.zero;
  Duration _dur = Duration.zero;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final urlStr = widget.event.content.tryGet<String>('url');
    if (urlStr == null) return;
    final mxc = Uri.parse(urlStr);
    final uri = await mxc.getDownloadUri(widget.event.room.client);
    try {
      final httpClient = HttpClient();
      final req = await httpClient.getUrl(uri);
      req.headers.set(
          'Authorization', 'Bearer ${widget.event.room.client.accessToken}');
      final res = await req.close();
      if (res.statusCode == 200) {
        final bytes = await consolidateHttpClientResponseBytes(res);
        final dir = await getTemporaryDirectory();
        final path =
            '${dir.path}/aud_${DateTime.now().millisecondsSinceEpoch}.m4a';
        final f = File(path);
        await f.writeAsBytes(bytes, flush: true);
        await _player.setSource(DeviceFileSource(path));
      } else {
        await _player.setSourceUrl(uri.toString());
      }
    } catch (_) {
      await _player.setSourceUrl(uri.toString());
    }
    _player.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _dur = d);
    });
    _player.onPositionChanged.listen((p) {
      if (!mounted) return;
      setState(() => _pos = p);
    });
    _player.onPlayerComplete.listen((event) {
      if (!mounted) return;
      setState(() => _playing = false);
    });
  }

  @override
  void dispose() {
    unawaited(_player.dispose());
    super.dispose();
  }

  String two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final pos = _pos;
    final dur = _dur.inMilliseconds == 0 ? const Duration(seconds: 1) : _dur;
    final ratio = (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
            onPressed: () async {
              if (_playing) {
                await _player.pause();
                setState(() => _playing = false);
              } else {
                await _player.resume();
                setState(() => _playing = true);
              }
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(value: ratio),
                const SizedBox(height: 4),
                Text(
                  '${two(pos.inMinutes)}:${two(pos.inSeconds % 60)} / ${two(dur.inMinutes)}:${two(dur.inSeconds % 60)}',
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineVideoPlayer extends StatefulWidget {
  final Event event;

  const _InlineVideoPlayer({required this.event});

  @override
  State<_InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<_InlineVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _showControls = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final urlStr = widget.event.content.tryGet<String>('url');
      if (urlStr == null) return;

      final mxc = Uri.parse(urlStr);
      final uri = await mxc.getDownloadUri(widget.event.room.client);

      // Use http package to download video with auth token
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${widget.event.room.client.accessToken}',
        },
      );

      if (response.statusCode == 200) {
        // Save to temporary directory
        final dir = await getTemporaryDirectory();
        final fileName =
            widget.event.content.tryGet<String>('body') ?? 'video.mp4';
        final path =
            '${dir.path}/vid_${DateTime.now().millisecondsSinceEpoch}_$fileName';
        final file = File(path);
        await file.writeAsBytes(response.bodyBytes);

        // Initialize video player with local file
        _controller = VideoPlayerController.file(file,
            viewType: VideoViewType.platformView);
        await _controller!.initialize();

        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      } else {
        // Fallback: try to play directly from URL
        _controller = VideoPlayerController.networkUrl(
          uri,
          httpHeaders: {
            'Authorization': 'Bearer ${widget.event.room.client.accessToken}',
          },
        );
        await _controller!.initialize();

        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing video: $e');
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (!_isInitialized || _controller == null) return;

    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _isPlaying = false;
      } else {
        _controller!.play();
        _isPlaying = true;
      }
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.event.content.tryGet<String>('body') ?? 'فيديو';
    final info = widget.event.content.tryGetMap<String, Object?>('info');
    final vidW = (info?.tryGet<num>('w')?.toDouble()) ?? 0;
    final vidH = (info?.tryGet<num>('h')?.toDouble()) ?? 0;
    final screenW = MediaQuery.of(context).size.width;
    final maxW = screenW * 0.72;
    final maxH = 260.h;

    // Calculate aspect ratio
    double? aspectRatio;
    if (vidW > 0 && vidH > 0) {
      aspectRatio = vidW / vidH;
    } else if (_isInitialized && _controller != null) {
      aspectRatio = _controller!.value.aspectRatio;
    }

    if (!_isInitialized || _controller == null) {
      // Loading state
      return Container(
        constraints: BoxConstraints(
          maxWidth: maxW,
          maxHeight: maxH,
        ),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 8.h),
              Text(
                'جاري التحميل...',
                style: TextStyle(color: Colors.white, fontSize: 12.sp),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxW,
          maxHeight: maxH,
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: AspectRatio(
                aspectRatio: aspectRatio ?? 16 / 9,
                child: VideoPlayer(_controller!),
              ),
            ),
            if (_showControls)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          _controller!.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.white,
                          size: 48.sp,
                        ),
                        onPressed: _togglePlayPause,
                      ),
                    ],
                  ),
                ),
              ),
            if (!_showControls && !_controller!.value.isPlaying)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: IconButton(
                    icon: const Icon(Icons.play_circle_filled),
                    color: Colors.white,
                    iconSize: 48.sp,
                    onPressed: _togglePlayPause,
                  ),
                ),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _showControls && _controller!.value.duration.inSeconds > 0
                  ? Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          VideoProgressIndicator(
                            _controller!,
                            allowScrubbing: true,
                            colors: const VideoProgressColors(
                              playedColor: Colors.blue,
                              bufferedColor: Colors.grey,
                              backgroundColor: Colors.white24,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(_controller!.value.position),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                ),
                              ),
                              Text(
                                _formatDuration(_controller!.value.duration),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.sp,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}
