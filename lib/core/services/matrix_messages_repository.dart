import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_4t_app/core/api/api_service.dart';

/// Repository to load Matrix messages via HTTP API (/_matrix/client/v3/rooms/...)
final matrixMessagesRepositoryProvider = Provider<MatrixMessagesRepository>(
  (ref) => MatrixMessagesRepository(ref.read(apiServiceProvider)),
);

class MatrixMessagesRepository {
  final ApiService _api;
  MatrixMessagesRepository(this._api);

  /// Fetch room messages using /rooms/{roomId}/messages
  /// dir: 'b' for backward from token, 'f' for forward
  Future<Map<String, dynamic>> fetchRoomMessages({
    required String roomId,
    String? from,
    String dir = 'b',
    int limit = 50,
    String? filter,
  }) async {
    final query = <String, dynamic>{
      'dir': dir,
      'limit': limit,
    };
    if (from != null) query['from'] = from;
    if (filter != null) query['filter'] = filter;
    final res = await _api.get('https://matrix.private-4t.com/_matrix/client/v3/rooms/$roomId/messages',
        queryParameters: query);
    return res.data is Map<String, dynamic>
        ? (res.data as Map<String, dynamic>)
        : jsonDecode(res.data as String) as Map<String, dynamic>;
  }
}
