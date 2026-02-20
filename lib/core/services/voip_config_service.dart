import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:matrix/matrix.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/providers/app_container.dart';

@pragma('vm:entry-point')
class VoipConfigService {
  @pragma('vm:entry-point')
  static VoipConfigService? _instance;

  @pragma('vm:entry-point')
  static VoipConfigService get instance => _instance ??= VoipConfigService._();

  @pragma('vm:entry-point')
  VoipConfigService._();

  List<Map<String, dynamic>>? _iceServers;
  DateTime? _lastConfigUpdate;
  final String _sharedKeyIceServers = "voip_ice_servers";
  static const Duration _configCacheDuration = Duration(hours: 1);
  bool _forceRelayOnly = false;
  bool _sanitizeSdpEnabled = false; // can be toggled for troubleshooting

  /// Get ICE servers configuration from Matrix homeserver
  @pragma('vm:entry-point')
  Future<List<Map<String, dynamic>>> getIceServers() async {
    // Return cached config if still valid
    final iceServersString =
        await CommonComponents.getSavedData(_sharedKeyIceServers);
    final iceServers =
        jsonDecode(iceServersString) as List<Map<String, dynamic>>?;
    if (_iceServers != null &&
        _lastConfigUpdate != null &&
        DateTime.now().difference(_lastConfigUpdate!) < _configCacheDuration) {
      return _iceServers ?? iceServers ?? [{}];
    }

    try {
      var matrix = providerAppContainer.read(ApiProviders.matrixChatProvider);
      final client = matrix.client;

      // Get TURN server config from Matrix homeserver
      final turnConfig = await _getTurnServerConfig(client);

      if (turnConfig != null) {
        _iceServers = _buildIceServersFromTurnConfig(turnConfig);

        await CommonComponents.saveData(
            key: _sharedKeyIceServers, value: jsonEncode(_iceServers));
        _lastConfigUpdate = DateTime.now();

        debugPrint(
            '✅ VoIP config retrieved from Matrix server: ${_iceServers!.length} servers');
        return _iceServers!;
      }
    } catch (e) {
      debugPrint('⚠️ Failed to get VoIP config from Matrix server: $e');
    }

    // Fallback to default public STUN servers
    _iceServers = _getDefaultIceServers();
    _lastConfigUpdate = DateTime.now();

    debugPrint(
        '📡 Using fallback STUN servers: ${_iceServers!.length} servers');
    return _iceServers!;
  }

  /// Get TURN server configuration from Matrix homeserver
  @pragma('vm:entry-point')
  Future<Map<String, dynamic>?> _getTurnServerConfig(Client client) async {
    try {
      final dio = Dio();

      // Set authorization header
      final accessToken = client.accessToken;
      if (accessToken == null) {
        throw Exception('No access token available');
      }

      dio.options.headers['Authorization'] = 'Bearer $accessToken';
      dio.options.headers['Content-Type'] = 'application/json';

      // Make request to Matrix VoIP endpoint (spec requires POST)
      final homeserverUrl =
          client.homeserver?.toString().replaceAll(RegExp(r"/+$"), '') ??
              'https://matrix.private-4t.com';
      final v3Url = '$homeserverUrl/_matrix/client/v3/voip/turnServer';
      final r0Url = '$homeserverUrl/_matrix/client/r0/voip/turnServer';

      debugPrint('🔍 Requesting VoIP config from (v3, POST): $v3Url');

      Response response;
      try {
        response = await dio.get(v3Url);
        if (response.statusCode == 200 && response.data != null) {
          debugPrint('✅ VoIP config (v3) response: ${response.data}');
          return response.data as Map<String, dynamic>;
        }
        debugPrint(
            '❌ VoIP config (v3) unexpected status: ${response.statusCode}');
      } catch (e) {
        debugPrint('⚠️ VoIP config (v3) request failed: $e');
      }

      // Fallback to r0 path (still POST per older specs)
      debugPrint('🔄 Falling back to VoIP config (r0, POST): $r0Url');
      try {
        response = await dio.get(r0Url);
        if (response.statusCode == 200 && response.data != null) {
          debugPrint('✅ VoIP config (r0) response: ${response.data}');
          return response.data as Map<String, dynamic>;
        }
        debugPrint(
            '❌ VoIP config (r0) unexpected status: ${response.statusCode}');
      } catch (e) {
        debugPrint('❌ VoIP config (r0) request failed: $e');
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error getting TURN server config: $e');
      return null;
    }
  }

  /// Build ICE servers list from Matrix TURN server config
  @pragma('vm:entry-point')
  List<Map<String, dynamic>> _buildIceServersFromTurnConfig(
      Map<String, dynamic> turnConfig) {
    final List<Map<String, dynamic>> iceServers = [];

    try {
      // Add STUN servers (always available)
      final uris = turnConfig['uris'] as List<dynamic>?;
      final username = turnConfig['username'] as String?;
      final password = turnConfig['password'] as String?;
      final ttl = turnConfig['ttl'] as int?;

      if (uris != null && uris.isNotEmpty) {
        // Process each URI
        final stunUris = <String>[];
        final turnUris = <String>[];

        for (final uri in uris) {
          final uriStr = uri.toString();
          if (uriStr.startsWith('stun:')) {
            stunUris.add(uriStr);
          } else if (uriStr.startsWith('turn:') ||
              uriStr.startsWith('turns:')) {
            turnUris.add(uriStr);
          }
        }

        // Add STUN servers (no authentication needed)
        if (stunUris.isNotEmpty) {
          iceServers.add({
            'urls': stunUris,
          });
        }

        // Add TURN servers (with authentication)
        if (turnUris.isNotEmpty && username != null && password != null) {
          iceServers.add({
            'urls': turnUris,
            'username': username,
            'credential': password,
          });
        }

        debugPrint(
            '📡 Configured ${stunUris.length} STUN and ${turnUris.length} TURN servers');
        debugPrint('🔑 TURN credentials: ${username != null ? "✅" : "❌"}');
        if (ttl != null) {
          debugPrint('⏰ Config TTL: ${ttl}s');
        }
      }
    } catch (e) {
      debugPrint('❌ Error parsing TURN config: $e');
    }

    // Always add Google's public STUN servers as fallback
    if (iceServers.isEmpty) {
      iceServers.addAll(_getDefaultIceServers());
    }

    return iceServers;
  }

  /// Get default ICE servers (public STUN servers)
  @pragma('vm:entry-point')
  List<Map<String, dynamic>> _getDefaultIceServers() {
    return [
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
          'stun:stun3.l.google.com:19302',
          'stun:stun4.l.google.com:19302',
        ]
      },
      {
        'urls': [
          'stun:stun.cloudflare.com:3478',
        ]
      },
    ];
  }

  /// Create RTCConfiguration with the retrieved ICE servers
  @pragma('vm:entry-point')
  Future<Map<String, dynamic>> getRTCConfiguration() async {
    final iceServers = await getIceServers();

    return {
      'iceServers': iceServers,
      'iceTransportPolicy': 'all',
      // Enable unified-plan semantics explicitly (better interop)
      'sdpSemantics': 'unified-plan',
      // Favor single transport bundle
      'bundlePolicy': 'max-bundle',
      // Require RTCP multiplexing
      'rtcpMuxPolicy': 'require',
    };
  }

  /// Force using TURN relay only (debug/testing) to bypass NAT traversal issues
  @pragma('vm:entry-point')
  void setForceRelayOnly(bool enable) {
    _forceRelayOnly = enable;
    debugPrint('⚙️ VoIP config: forceRelayOnly=${enable ? 'ON' : 'OFF'}');
  }

  /// Toggle SDP sanitization (keep Opus only, drop video for audio calls)
  @pragma('vm:entry-point')
  void setSanitizeSdpEnabled(bool enable) {
    _sanitizeSdpEnabled = enable;
    debugPrint('⚙️ VoIP config: sanitizeSDP=${enable ? 'ON' : 'OFF'}');
  }

  bool get isSanitizeSdpEnabled => _sanitizeSdpEnabled;

  /// Clear cached configuration (force refresh on next request)
  @pragma('vm:entry-point')
  void clearCache() {
    _iceServers = null;
    _lastConfigUpdate = null;
    debugPrint('🗑️ VoIP config cache cleared');
  }

  /// Get detailed configuration info for debugging
  @pragma('vm:entry-point')
  Map<String, dynamic> getConfigInfo() {
    return {
      'hasConfig': _iceServers != null,
      'serverCount': _iceServers?.length ?? 0,
      'lastUpdate': _lastConfigUpdate?.toIso8601String(),
      'cacheValid': _lastConfigUpdate != null &&
          DateTime.now().difference(_lastConfigUpdate!) < _configCacheDuration,
      'servers': _iceServers,
    };
  }
}
