import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import 'api_keys.dart';
import 'common_components.dart';

class PusherController {
  static const _appKey = 'ecb1c6f40378272f4c93';
  static const _cluster = 'mt1';
  static const _authEndPoint = 'https://private-4t.com/broadcasting/auth';
  
  static late final PusherChannelsFlutter pusher;
  static final Map<String, dynamic> _subscribedChannels = {};
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    
    try {
      pusher = PusherChannelsFlutter.getInstance();
      
      await pusher.init(
        apiKey: _appKey,
        cluster: _cluster,
        onConnectionStateChange: _onConnectionStateChange,
        onError: _onError,
        onSubscriptionSucceeded: _onSubscriptionSucceeded,
        onEvent: _onEvent,
        onSubscriptionError: _onSubscriptionError,
        onDecryptionFailure: _onDecryptionFailure,
        onMemberAdded: _onMemberAdded,
        onMemberRemoved: _onMemberRemoved,
        onAuthorizer: _onAuthorizer,
      );

      await pusher.connect();
      _initialized = true;
      
      debugPrint('✅ Pusher initialized successfully');
    } catch (e) {
      debugPrint('❌ Pusher initialization error: $e');
    }
  }

  static dynamic _onAuthorizer(
    String channelName,
    String socketId,
    dynamic options,
  ) async {
    try {
      final token = await CommonComponents.getSavedData(ApiKeys.userToken);
      
      return {
        'authEndpoint': _authEndPoint,
        'headers': {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      };
    } catch (e) {
      debugPrint('❌ Pusher authorizer error: $e');
      return {};
    }
  }

  static void _onConnectionStateChange(String currentState, String? previousState) {
    debugPrint('📡 Pusher connection: $previousState => $currentState');
  }

  static void _onError(
    String message,
    int? code,
    dynamic error,
  ) {
    debugPrint('❌ Pusher error: $message (code: $code)');
  }

  static void _onEvent(PusherEvent event) {
    debugPrint('📨 Pusher event: ${event.eventName} on ${event.channelName}');
    log('Event data: ${event.data}');
  }

  static void _onSubscriptionSucceeded(String channelName, dynamic data) {
    debugPrint('✅ Subscribed to: $channelName');
  }

  static void _onSubscriptionError(String message, dynamic error) {
    debugPrint('❌ Subscription error: $message');
  }

  static void _onDecryptionFailure(String event, String reason) {
    debugPrint('❌ Decryption failure: $event - $reason');
  }

  static void _onMemberAdded(String channelName, PusherMember member) {
    debugPrint('➕ Member added to $channelName: ${member.userId}');
  }

  static void _onMemberRemoved(String channelName, PusherMember member) {
    debugPrint('➖ Member removed from $channelName: ${member.userId}');
  }

  static Future<void> subscribe(String channelName) async {
    try {
      if (_subscribedChannels.containsKey(channelName)) {
        debugPrint('⚠️ Already subscribed to $channelName');
        return;
      }

      await pusher.subscribe(channelName: channelName);
      _subscribedChannels[channelName] = true;
      debugPrint('✅ Subscribing to $channelName');
    } catch (e) {
      debugPrint('❌ Error subscribing to $channelName: $e');
    }
  }

  static Future<void> unsubscribe(String channelName) async {
    try {
      await pusher.unsubscribe(channelName: channelName);
      _subscribedChannels.remove(channelName);
      debugPrint('✅ Unsubscribed from $channelName');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from $channelName: $e');
    }
  }

  static Future<void> disconnect() async {
    try {
      await pusher.disconnect();
      _subscribedChannels.clear();
      _initialized = false;
      debugPrint('✅ Pusher disconnected');
    } catch (e) {
      debugPrint('❌ Error disconnecting Pusher: $e');
    }
  }
  
  static Future<void> trigger(String channelName, String eventName, dynamic data) async {
    try {
      // Check if channel is subscribed
      if (!_subscribedChannels.containsKey(channelName)) {
        debugPrint('⚠️ Cannot trigger event on unsubscribed channel: $channelName');
        return;
      }
      
      // Convert data to JSON string if it's a Map
      final String jsonData = data is String ? data : jsonEncode(data);
      
      await pusher.trigger(
        PusherEvent(
          channelName: channelName,
          eventName: eventName,
          data: jsonData,
        ),
      );
      debugPrint('✅ Triggered event $eventName on $channelName');
    } catch (e) {
      debugPrint('❌ Error triggering event: $e');
      // Don't rethrow - just log the error
    }
  }
}
