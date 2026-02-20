import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:private_4t_app/core/services/navigation_service.dart';

class DeepLinkProvider extends StateNotifier<DeepLinkState> {
  DeepLinkProvider() : super(DeepLinkState());

  Future<void> handleDeepLink(Map<String, dynamic> payload) async {
    try {
      final url = payload['url'];
      final type = payload['link_type'] ?? 'internal';
      final data = payload['data'];

      if (url == null) {
        state = state.copyWith(error: 'No URL provided in deep link');
        return;
      }

      if (type == 'internal') {
        await _handleInternalLink(url, data);
      } else if (type == 'external') {
        await _handleExternalLink(url);
      } else if (type == 'matrix_message') {
        await _handleMatrixMessageLink(payload);
      } else if (type == 'matrix_call') {
        await _handleMatrixCallLink(payload);
      } else {
        // Default to internal link
        await _handleInternalLink(url, data);
      }

      state = state.copyWith(
        lastHandledLink: url,
        lastLinkType: type,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> _handleInternalLink(String url, dynamic data) async {
    try {
      final context = NavigationService.rootNavigatorKey.currentContext;
      if (context != null) {
        // Handle different internal routes
        if (url.startsWith('/room/')) {
          final roomId = url.split('/').last;
          NavigationService.navigateToRoomTimeline(context, roomId);
        } else if (url.startsWith('/call/')) {
          final roomId = url.split('/').last;
          NavigationService.navigateToCall(context, roomId);
        } else if (url.startsWith('/profile/')) {
          NavigationService.navigateToProfile(context);
        } else if (url.startsWith('/menu/')) {
          NavigationService.navigateToMenu(context);
        } else if (url.startsWith('/notifications/')) {
          NavigationService.navigateToNotifications(context);
        } else {
          // Default navigation using GoRouter
          NavigationService.router?.push(url);
        }
      }
    } catch (e) {
      debugPrint('Error handling internal link: $e');
      state = state.copyWith(error: 'Failed to navigate to internal link: $e');
    }
  }

  Future<void> _handleExternalLink(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        state = state.copyWith(error: 'Could not launch external URL: $url');
      }
    } catch (e) {
      debugPrint('Error handling external link: $e');
      state = state.copyWith(error: 'Failed to launch external link: $e');
    }
  }

  Future<void> _handleMatrixMessageLink(Map<String, dynamic> payload) async {
    try {
      final roomId = payload['room_id'];

      if (roomId != null) {
        final context = NavigationService.rootNavigatorKey.currentContext;
        if (context != null) {
          NavigationService.navigateToRoomTimeline(context, roomId);
        }
      }
    } catch (e) {
      debugPrint('Error handling Matrix message link: $e');
      state = state.copyWith(error: 'Failed to handle Matrix message link: $e');
    }
  }

  Future<void> _handleMatrixCallLink(Map<String, dynamic> payload) async {
    try {
      final roomId = payload['room_id'];

      if (roomId != null) {
        final context = NavigationService.rootNavigatorKey.currentContext;
        if (context != null) {
          NavigationService.navigateToCall(context, roomId);
        }
      }
    } catch (e) {
      debugPrint('Error handling Matrix call link: $e');
      state = state.copyWith(error: 'Failed to handle Matrix call link: $e');
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

class DeepLinkState {
  final String? lastHandledLink;
  final String? lastLinkType;
  final String? error;

  DeepLinkState({
    this.lastHandledLink,
    this.lastLinkType,
    this.error,
  });

  DeepLinkState copyWith({
    String? lastHandledLink,
    String? lastLinkType,
    String? error,
  }) {
    return DeepLinkState(
      lastHandledLink: lastHandledLink ?? this.lastHandledLink,
      lastLinkType: lastLinkType ?? this.lastLinkType,
      error: error ?? this.error,
    );
  }
}

final deepLinkProvider = StateNotifierProvider<DeepLinkProvider, DeepLinkState>(
  (ref) => DeepLinkProvider(),
);
