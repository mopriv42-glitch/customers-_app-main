import 'package:flutter/material.dart';
import 'package:private_4t_app/app_config/api_keys.dart';
import 'package:private_4t_app/app_config/api_requests.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/models/clip_comment_model.dart';
import 'package:private_4t_app/core/models/clip_like_model.dart';
import 'package:private_4t_app/core/models/clip_model.dart';
import 'package:private_4t_app/core/models/clip_share_model.dart';

class ClipProvider extends ChangeNotifier {
  final List<ClipModel> _clips = [];
  int _currentPage = 0;
  int _lastPage = 1;
  bool _loading = false;
  bool _loadingMore = false;
  bool _isScreenActive = true;

  final Map<int, List<ClipCommentModel>> _clipIdToComments = {};
  final Map<int, int> _clipIdToCommentsPage = {};
  final Map<int, int> _clipIdToCommentsLastPage = {};

  List<ClipModel> get clips => _clips;
  bool get isLoading => _loading;
  bool get isLoadingMore => _loadingMore;
  bool get hasMore => _currentPage < _lastPage;
  bool get isScreenActive => _isScreenActive;

  List<ClipCommentModel> commentsOf(int clipId) =>
      _clipIdToComments[clipId] ?? const [];

  bool hasMoreComments(int clipId) {
    final current = _clipIdToCommentsPage[clipId] ?? 0;
    final last = _clipIdToCommentsLastPage[clipId] ?? 1;
    return current < last;
  }

  Future<void> fetchClips(BuildContext context, {bool refresh = false}) async {
    if (_loading || _loadingMore) return;
    final isLoadMore = !refresh && _currentPage > 0;
    if (isLoadMore && !hasMore) return;

    if (refresh) {
      _clips.clear();
      _currentPage = 0;
      _lastPage = 1;
      // Clear comments cache on refresh
      _clipIdToComments.clear();
      _clipIdToCommentsPage.clear();
      _clipIdToCommentsLastPage.clear();
    }

    if (_currentPage == 0) {
      _loading = true;
    } else {
      _loadingMore = true;
    }
    notifyListeners();

    final page = _currentPage + 1;
    final data = await ApiRequests.getApiRequests(
      context: context,
      baseUrl: ApiKeys.baseUrl,
      apiUrl: 'clips?page=$page',
      headers: {
        'Authorization':
            'Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}',
      },
    ) as Map?;

    if (data != null && data.containsKey('data')) {
      var dataMap = data['data'];
      final List items = (dataMap['clips'] as List?) ?? const [];
      final meta = (dataMap['meta'] as Map?)?.cast<String, dynamic>() ?? {};
      final newClips = items
          .map((e) => ClipModel.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
      _clips.addAll(newClips);
      _currentPage = meta['current_page'] ?? page;
      _lastPage = meta['last_page'] ?? _lastPage;
    }

    _loading = false;
    _loadingMore = false;
    notifyListeners();
  }

  Future<void> incrementView(BuildContext context, int clipId) async {
    await ApiRequests.postApiRequest(
      context: context,
      baseUrl: ApiKeys.baseUrl,
      apiUrl: 'clips/$clipId/view',
      headers: {
        'Authorization':
            'Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}',
      },
      body: {},
      showLoadingWidget: false,
    );
  }

  Future<void> likeClip(BuildContext context, ClipModel clip) async {
    final res = await ApiRequests.postApiRequest(
      context: context,
      baseUrl: ApiKeys.baseUrl,
      apiUrl: 'clips/${clip.id}/like',
      headers: {
        'Authorization':
            'Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}',
      },
      body: {},
      showLoadingWidget: false,
    ) as Map?;
    if (res != null) {
      clip.isLiked = true;
      clip.likesCount = res['likes_count'] ?? (clip.likesCount + 1);
      notifyListeners();
    }
  }

  Future<void> unlikeClip(BuildContext context, ClipModel clip) async {
    final res = await ApiRequests.deleteRequest(
      context: context,
      baseUrl: ApiKeys.baseUrl,
      apiUrl: 'clips/${clip.id}/unlike',
      headers: {
        'Authorization':
            'Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}',
      },
      showLoadingWidget: false,
    ) as Map?;
    if (res != null) {
      clip.isLiked = false;
      clip.likesCount = res['likes_count'] ?? (clip.likesCount - 1);
      if (clip.likesCount < 0) clip.likesCount = 0;
      notifyListeners();
    }
  }

  Future<List<ClipLikeModel>> fetchLikes(
      BuildContext context, int clipId, int page) async {
    final data = await ApiRequests.getApiRequests(
      context: context,
      baseUrl: ApiKeys.baseUrl,
      apiUrl: 'clips/$clipId/likes?page=$page',
      headers: {
        'Authorization':
            'Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}',
      },
    ) as Map?;
    final List items = (data?['data'] as List?) ?? const [];
    return items
        .map((e) => ClipLikeModel.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<void> fetchComments(BuildContext context, int clipId,
      {bool refresh = false}) async {
    final currentPage = refresh ? 0 : (_clipIdToCommentsPage[clipId] ?? 0);
    final lastPage = _clipIdToCommentsLastPage[clipId] ?? 1;
    if (currentPage >= lastPage && !refresh) return;
    final page = currentPage + 1;

    final data = await ApiRequests.getApiRequests(
      context: context,
      baseUrl: ApiKeys.baseUrl,
      apiUrl: 'clips/$clipId/comments?page=$page',
      headers: {
        'Authorization':
            'Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}',
      },
    ) as Map?;

    final List items = (data?['data'] as List?) ?? const [];
    final meta = (data?['meta'] as Map?)?.cast<String, dynamic>() ?? {};
    final newComments = items
        .map((e) =>
            ClipCommentModel.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    if (refresh) {
      _clipIdToComments[clipId] = newComments;
    } else {
      _clipIdToComments.putIfAbsent(clipId, () => []);
      _clipIdToComments[clipId]!.addAll(newComments);
    }
    _clipIdToCommentsPage[clipId] = meta['current_page'] ?? page;
    _clipIdToCommentsLastPage[clipId] = meta['last_page'] ?? lastPage;
    notifyListeners();
  }

  Future<void> addComment(
      BuildContext context, int clipId, String content) async {
    final res = await ApiRequests.postApiRequest(
      context: context,
      baseUrl: ApiKeys.baseUrl,
      apiUrl: 'clips/$clipId/comments',
      headers: {
        'Authorization':
            'Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}',
      },
      body: {'content': content},
      showLoadingWidget: false,
    ) as Map?;
    if (res != null) {
      final comment = ClipCommentModel.fromJson(res.cast<String, dynamic>());
      _clipIdToComments.putIfAbsent(clipId, () => []);
      _clipIdToComments[clipId]!.insert(0, comment);
      final idx = _clips.indexWhere((c) => c.id == clipId);
      if (idx != -1) {
        _clips[idx].commentsCount += 1;
      }
      notifyListeners();
    }
  }

  Future<void> replyToComment(
      BuildContext context, int parentCommentId, String content) async {
    await ApiRequests.postApiRequest(
      context: context,
      baseUrl: ApiKeys.baseUrl,
      apiUrl: 'clips/comments/$parentCommentId/reply',
      headers: {
        'Authorization':
            'Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}',
      },
      body: {'content': content},
      showLoadingWidget: false,
    );
  }

  Future<void> updateComment(
      BuildContext context, int commentId, String content) async {
    await ApiRequests.postApiRequest(
      context: context,
      baseUrl: ApiKeys.baseUrl,
      apiUrl: 'clips/comments/$commentId',
      headers: {
        'Authorization':
            'Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}',
      },
      body: {'content': content},
      showLoadingWidget: false,
    );
  }

  Future<void> deleteComment(BuildContext context, int commentId) async {
    await ApiRequests.deleteRequest(
      context: context,
      baseUrl: ApiKeys.baseUrl,
      apiUrl: 'clips/comments/$commentId',
      headers: {
        'Authorization':
            'Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}',
      },
    );
  }

  Future<void> shareClip(BuildContext context, int clipId,
      {String? platform, String? message}) async {
    await ApiRequests.postApiRequest(
      context: context,
      baseUrl: ApiKeys.baseUrl,
      apiUrl: 'clips/$clipId/share',
      headers: {
        'Authorization':
            'Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}',
      },
      body: {
        if (platform != null) 'share_platform': platform,
        if (message != null) 'share_message': message,
      },
      showLoadingWidget: false,
    );
  }

  Future<List<ClipShareModel>> fetchShares(
      BuildContext context, int clipId, int page) async {
    final data = await ApiRequests.getApiRequests(
      context: context,
      baseUrl: ApiKeys.baseUrl,
      apiUrl: 'clips/$clipId/shares?page=$page',
      headers: {
        'Authorization':
            'Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}',
      },
    ) as Map?;
    final List items = (data?['data'] as List?) ?? const [];
    return items
        .map((e) => ClipShareModel.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<void> toggleLike(BuildContext context, ClipModel clip) async {
    if (clip.isLiked) {
      await unlikeClip(context, clip);
    } else {
      await likeClip(context, clip);
    }
  }

  void setScreenActive(bool isActive) {
    _isScreenActive = isActive;
    notifyListeners();
  }
}
