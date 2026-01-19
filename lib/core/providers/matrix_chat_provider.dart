import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:matrix/matrix.dart';
import 'package:path_provider/path_provider.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/models/user_model.dart';
import 'package:private_4t_app/core/services/matrix_admin_auth_service.dart';
import 'package:private_4t_app/core/services/matrix_auto_provisioning_service.dart';
import 'package:private_4t_app/core/services/matrix_call_service.dart';
import 'package:private_4t_app/core/services/matrix_notifications_bridge.dart';
import 'package:private_4t_app/core/services/navigation_queue.dart';
import 'package:private_4t_app/core/services/voip_service.dart';
import 'package:sqflite/sqflite.dart' as sqlite;

@pragma('vm:entry-point')
class MatrixChatProvider extends ChangeNotifier {
  static final Uri _homeserver = Uri.parse('https://matrix.private-4t.com');

  @pragma('vm:entry-point')
  Client? _client;
  bool _isInitialized = false;
  bool _isLoggedIn = false;
  bool _isSyncing = false;
  @pragma('vm:entry-point')
  VoIP? _voIP;
  MatrixNotificationsBridge? _notifications;
  MatrixCallService? _calls;

  // Resync handling properties
  Timer? _resyncTimer;
  int _resyncAttempts = 0;
  static const int _maxResyncAttempts = 5;
  static const Duration _resyncBaseDelay = Duration(seconds: 2);
  bool _isResyncInProgress = false;
  StreamSubscription? _syncSubscription;

  @pragma('vm:entry-point')
  VoIP? get voIPNullable => _voIP;

  @pragma('vm:entry-point')
  Client? get clientNullable => _client;

  @pragma('vm:entry-point')
  Client get client => _client!;

  @pragma('vm:entry-point')
  VoIP get voIp => _voIP!;

  bool get isInitialized => _isInitialized;

  bool get isLoggedIn => _isLoggedIn;

  bool get isSyncing => _isSyncing;

  @pragma('vm:entry-point')
  MatrixCallService? get calls => _calls;

  @pragma('vm:entry-point')
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Prepare persistent database for the Matrix SDK
      final appDir = await getApplicationSupportDirectory();
      final dbPath = '${appDir.path}/matrix_client.sqlite';
      final sqliteDb = await sqlite.openDatabase(dbPath);

      final c = Client(
        'Private4TChat',
        database: await MatrixSdkDatabase.init(
          'Private4TChat',
          database: sqliteDb,
        ),
      );

      _client = c;

      try {
        // Initialize with shorter timeout to prevent hanging
        await c.init().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint('Matrix client init timed out after 10s');
            throw TimeoutException(
                'Matrix init timeout', const Duration(seconds: 10));
          },
        );

        _isLoggedIn = c.isLogged();
        debugPrint(
            'Matrix client initialized successfully, logged in: $_isLoggedIn');

        // Try to connect to homeserver with timeout (also validates URL)
        if (_isLoggedIn) {
          try {
            await c.checkHomeserver(_homeserver).timeout(
              const Duration(seconds: 8),
              onTimeout: () {
                debugPrint('Homeserver check timed out, will retry later');
                throw TimeoutException(
                    'Homeserver check timeout', const Duration(seconds: 8));
              },
            );
          } catch (e) {
            debugPrint('Homeserver check failed: $e');
          }
        }
      } catch (e) {
        debugPrint('Matrix client initialization error: $e');

        // For timeout errors, create a fallback client that can work offline
        if (e is TimeoutException || e.toString().contains('timeout')) {
          debugPrint('Creating fallback Matrix client due to timeout');
          _isLoggedIn = c.isLogged(); // Check if we have stored credentials
        } else {
          // For other errors, still try to determine login state
          try {
            _isLoggedIn = c.isLogged();
          } catch (e2) {
            debugPrint('Cannot determine login state: $e2');
            _isLoggedIn = false;
          }
        }
      }

      // Start services if logged in (even with timeout issues)
      if (_isLoggedIn) {
        _notifications ??= MatrixNotificationsBridge(c);
        _voIP ??= VoIP(c, VoipService());
        unawaited(_notifications!.start());
        _calls ??= MatrixCallService(c, _voIP!);
        unawaited(_calls!.start());

        // Delay sync start to avoid immediate timeout
        unawaited(Future.delayed(const Duration(seconds: 2), () {
          startSync();
        }));

        // Check for pending call acceptances from CallKit when app was terminated
        unawaited(_checkPendingCallAcceptances());
      }
    } catch (e) {
      debugPrint('Critical error during Matrix provider init: $e');
      // Continue with app initialization even if Matrix completely fails
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> loginWithPassword({
    required String usernameOrUserId,
    required String password,
  }) async {
    final c = _client ?? (throw StateError('Matrix client not initialized'));

    // Accept either full mxid (@user:domain) or localpart
    final identifier = AuthenticationUserIdentifier(user: usernameOrUserId);

    try {
      // Check homeserver with timeout
      await c.checkHomeserver(_homeserver).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('فشل الاتصال بالخادم: انتهت مهلة الاتصال');
        },
      );

      // Login with timeout
      await c
          .login(
        LoginType.mLoginPassword,
        identifier: identifier,
        password: password,
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('فشل تسجيل الدخول: انتهت مهلة الاتصال');
        },
      );
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('M_FORBIDDEN')) {
        throw Exception('خطأ: اسم المستخدم أو كلمة المرور غير صحيحة');
      }
      if (msg.contains('M_LIMIT_EXCEEDED')) {
        throw Exception('عدد محاولات كبير، حاول لاحقًا');
      }
      if (msg.contains('timeout') || msg.contains('انتهت مهلة الاتصال')) {
        throw Exception('فشل الاتصال: تأكد من اتصال الإنترنت وحاول مرة أخرى');
      }
      throw Exception('فشل تسجيل الدخول: $msg');
    }

    _isLoggedIn = c.isLogged();
    notifyListeners();
    unawaited(startSync());
    _notifications ??= MatrixNotificationsBridge(c);
    unawaited(_notifications!.start());
    _voIP ??= VoIP(c, VoipService());
    _calls ??= MatrixCallService(c, _voIP!);
    unawaited(_calls!.start());

    // Check for pending call acceptances from CallKit
    unawaited(_checkPendingCallAcceptances());
  }

  Future<void> startSync() async {
    if (_isSyncing || _client == null) return;
    _isSyncing = true;
    notifyListeners();

    // Listen to sync stream for error handling
    _syncSubscription?.cancel();
    _syncSubscription = _client!.onSync.stream.listen(
      (syncUpdate) {
        // Sync successful, reset retry attempts
        _resyncAttempts = 0;
        _resyncTimer?.cancel();
        _isResyncInProgress = false;
        _isSyncing = false; // Reset syncing flag on success
        notifyListeners();
      },
      onError: (error) {
        debugPrint("Sync stream error: $error");
        _isSyncing = false;
        notifyListeners();
        _handleSyncError(error);
      },
    );

    try {
      // Use shorter timeout and better error handling
      await _client!
          .sync(
        timeout: 15000, // Reduced from 30s to 15s
      )
          .timeout(
        const Duration(seconds: 20), // Overall timeout including network delays
        onTimeout: () {
          debugPrint('Sync operation timed out');
          _isSyncing = false;
          notifyListeners();
          _handleSyncError('Sync timeout');
          throw TimeoutException('Sync timeout', const Duration(seconds: 20));
        },
      );
    } catch (e) {
      debugPrint("Sync error: $e");
      _isSyncing = false;
      notifyListeners();
      _handleSyncError(e);
    }
  }

  Future<void> logout() async {
    if (_client == null) return;
    try {
      await _client!.logout();
    } catch (_) {}
    _isLoggedIn = false;
    _isSyncing = false;
    await _notifications?.stop();
    await _calls?.stop();
    _syncSubscription?.cancel();
    _resyncTimer?.cancel();
    notifyListeners();
  }

  List<Room> get joinedRooms => _client == null
      ? const []
      : _client!.rooms
          .where((r) => r.membership == Membership.join)
          .toList(growable: false);

  List<Room> get invitedRooms => _client == null
      ? const []
      : _client!.rooms
          .where((r) => r.membership == Membership.invite)
          .toList(growable: false);

  Future<void> sendText({required String roomId, required String text}) async {
    if (_client == null) return;
    final room = _client!.getRoomById(roomId);
    if (room == null) return;
    await room.sendTextEvent(text);
  }

  /// Accept a room invitation
  Future<bool> acceptInvitation(String roomId) async {
    try {
      if (_client == null) {
        debugPrint('Matrix client not initialized');
        return false;
      }

      final room = _client!.getRoomById(roomId);
      if (room == null) {
        debugPrint('Room not found: $roomId');
        return false;
      }

      if (room.membership != Membership.invite) {
        debugPrint('Room is not an invitation: ${room.membership}');
        return false;
      }

      await room.join();
      notifyListeners();
      debugPrint('Successfully accepted invitation for room: $roomId');
      return true;
    } catch (e) {
      debugPrint('Error accepting invitation for room $roomId: $e');
      return false;
    }
  }

  /// Reject a room invitation
  Future<bool> rejectInvitation(String roomId) async {
    try {
      if (_client == null) {
        debugPrint('Matrix client not initialized');
        return false;
      }

      final room = _client!.getRoomById(roomId);
      if (room == null) {
        debugPrint('Room not found: $roomId');
        return false;
      }

      if (room.membership != Membership.invite) {
        debugPrint('Room is not an invitation: ${room.membership}');
        return false;
      }

      await room.leave();
      notifyListeners();
      debugPrint('Successfully rejected invitation for room: $roomId');
      return true;
    } catch (e) {
      debugPrint('Error rejecting invitation for room $roomId: $e');
      return false;
    }
  }

  /// Get invitation details including inviter information
  Future<Map<String, dynamic>?> getInvitationDetails(String roomId) async {
    try {
      if (_client == null) return null;

      final room = _client!.getRoomById(roomId);
      if (room == null || room.membership != Membership.invite) return null;

      // Get the invite event to find who invited the user
      final inviteEvent =
          room.getState(EventTypes.RoomMember, _client!.userID!);

      return {
        'roomId': roomId,
        'roomName': room.getLocalizedDisplayname(),
        'inviter': inviteEvent?.senderId ?? 'Unknown',
        'inviterDisplayName': await _getDisplayName(inviteEvent?.senderId),
        'roomTopic': room.topic,
        'memberCount': room.summary.mJoinedMemberCount ?? 0,
        'isDirectChat': room.isDirectChat,
        'timestamp': DateTime.now(), // Use current time as fallback
        'roomAvatarUrl': room.avatar?.toString(),
      };
    } catch (e) {
      debugPrint('Error getting invitation details for room $roomId: $e');
      return null;
    }
  }

  /// Helper method to get user display name
  Future<String> _getDisplayName(String? userId) async {
    if (userId == null || _client == null) return 'Unknown User';

    try {
      final profile = await _client!.getProfileFromUserId(userId);
      return profile.displayName ?? userId;
    } catch (e) {
      return userId;
    }
  }

  /// Get all pending invitations with details
  Future<List<Map<String, dynamic>>> getAllInvitationDetails() async {
    final invitations = <Map<String, dynamic>>[];

    for (final room in invitedRooms) {
      final details = await getInvitationDetails(room.id);
      if (details != null) {
        invitations.add(details);
      }
    }

    // Sort by timestamp (newest first)
    invitations.sort((a, b) =>
        (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

    return invitations;
  }

  /// Authenticate user with Matrix Admin API and auto-login
  Future<MatrixAuthResult> authenticateWithAdminAPI({
    required UserModel appUser,
  }) async {
    if (_client == null) {
      throw StateError('Matrix client not initialized');
    }

    // Step 1: Use Admin API to create/update user and get credentials
    final authResult =
        await MatrixAdminAuthService.authenticateUser(appUser: appUser);

    if (!authResult.success) {
      return authResult;
    }

    // Step 2: If Admin API authentication succeeded, login to Matrix client
    try {
      // Logout current session if logged in
      if (_isLoggedIn) {
        await logout();
      }

      // Check homeserver
      await _client!.checkHomeserver(_homeserver);

      // Login with the credentials from Admin API
      final identifier =
          AuthenticationUserIdentifier(user: authResult.matrixUserId!);

      await _client!.login(
        LoginType.mLoginPassword,
        identifier: identifier,
        password: 'Private4T@2024', // Using the default password from Admin API
      );

      _isLoggedIn = _client!.isLogged();
      notifyListeners();

      // Start sync and services
      unawaited(startSync());
      _notifications ??= MatrixNotificationsBridge(_client!);
      unawaited(_notifications!.start());
      _voIP ??= VoIP(_client!, VoipService());
      _calls ??= MatrixCallService(_client!, _voIP!);

      unawaited(_calls!.start());

      return MatrixAuthResult(
        success: true,
        message: 'Successfully authenticated and logged in to Matrix',
        matrixUserId: authResult.matrixUserId,
        accessToken: _client!.accessToken,
        userData: authResult.userData,
      );
    } catch (e) {
      debugPrint('Error during Matrix client login: $e');
      return MatrixAuthResult(
        success: false,
        message: 'Failed to login to Matrix client: $e',
      );
    }
  }

  /// Quick authentication method using phone number
  Future<MatrixAuthResult> authenticateWithPhone({
    required String phoneNumber,
    required String userName,
    String? avatarUrl,
  }) async {
    final tempUser = UserModel(
      id: null,
      name: userName,
      phone: phoneNumber,
      imageUrl: avatarUrl,
      email: null,
      profile: null,
    );

    return await authenticateWithAdminAPI(appUser: tempUser);
  }

  /// Automatic user provisioning using admin credentials
  /// This method handles the complete flow from admin auth to user login
  Future<MatrixProvisioningResult> autoProvisionUser({
    required UserModel appUser,
  }) async {
    if (_client == null) {
      throw StateError('Matrix client not initialized');
    }

    // Use auto-provisioning service with this provider instance
    // The service will handle admin auth, user creation/update, and login via this provider
    final provisioningResult =
        await MatrixAutoProvisioningService.provisionUser(
      appUser: appUser,
      matrixChatProvider: this,
    );

    if (provisioningResult.success) {
      // Login was handled by the auto-provisioning service via loginWithPassword
      // Just need to start additional services that aren't started by loginWithPassword
      _voIP ??= VoIP(_client!, VoipService());
      _calls ??= MatrixCallService(_client!, _voIP!);
      unawaited(_calls!.start());
    }

    return provisioningResult;
  }

  /// Check if user can be auto-provisioned
  bool canAutoProvision(UserModel user) {
    return MatrixAutoProvisioningService.canProvisionUser(user);
  }

  /// Get Matrix user ID for a phone number
  String getMatrixUserIdFromPhone(String phoneNumber) {
    return MatrixAutoProvisioningService.getMatrixUserIdFromPhone(phoneNumber);
  }

  // Matrix Resync handling methods

  void _handleSyncError(dynamic error) {
    if (_isResyncInProgress) {
      debugPrint('Resync already in progress, ignoring error');
      return;
    }

    debugPrint('Handling sync error: $error');

    // Check if this is a network-related error that warrants a resync
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('timeout') ||
        errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeoutexception') ||
        errorString.contains('socketexception')) {
      debugPrint('Network-related sync error detected, scheduling resync');
      _scheduleResync();
    }
  }

  void _scheduleResync() {
    if (_resyncAttempts >= _maxResyncAttempts) {
      debugPrint('Max resync attempts reached, giving up');
      _resyncAttempts = 0;
      return;
    }

    _resyncTimer?.cancel();

    // Exponential backoff: 2^attempt * base delay
    final delay = Duration(
        milliseconds: _resyncBaseDelay.inMilliseconds * (1 << _resyncAttempts));

    debugPrint(
        'Scheduling resync attempt ${_resyncAttempts + 1} in ${delay.inSeconds}s');

    _resyncTimer = Timer(delay, () {
      _performResync();
    });
  }

  Future<void> _performResync() async {
    if (_isResyncInProgress || _client == null) return;

    _isResyncInProgress = true;
    _resyncAttempts++;

    try {
      debugPrint('Performing matrix client resync attempt $_resyncAttempts');

      // Check client connection state
      if (_client!.isLogged()) {
        // Force a sync to get latest state with timeout
        await _client!.oneShotSync().timeout(
          const Duration(seconds: 25), // Reasonable timeout for resync
          onTimeout: () {
            debugPrint('Resync oneShotSync timed out');
            throw TimeoutException(
                'Resync timeout', const Duration(seconds: 25));
          },
        );

        // Reset counters on successful sync
        _resyncAttempts = 0;
        _resyncTimer?.cancel();
        _isResyncInProgress = false;
        debugPrint('Matrix client resync successful');

        // Validate call states after resync if call service exists
      } else {
        debugPrint('Client not logged in, cannot resync');
        _isResyncInProgress = false;
        _scheduleResync(); // Try again later
      }
    } catch (e) {
      debugPrint('Matrix client resync failed: $e');

      // Check if this is a timeout exception
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('timeout') ||
          errorString.contains('timeoutexception')) {
        debugPrint('Timeout during resync, will retry');
        _scheduleResync();
      } else if (_resyncAttempts < _maxResyncAttempts) {
        debugPrint('Network error during resync, will retry');
        _scheduleResync();
      } else {
        debugPrint('Max resync attempts reached after error: $e');
        _resyncAttempts = 0;
      }
      _isResyncInProgress = false;
    }
  }

  /// Call this method when internet connection is restored
  /// This will trigger immediate resync and call recovery
  void onInternetConnectionRestored() {
    debugPrint('Internet connection restored, triggering matrix client resync');

    // Reset resync attempts to allow fresh attempts
    _resyncAttempts = 0;
    _resyncTimer?.cancel();
    _isResyncInProgress = false;

    // Trigger immediate resync
    _performResync();
  }

  /// Force a manual resync - useful for testing or when you detect connection issues
  Future<void> forceResync() async {
    debugPrint('Force resync requested');
    _resyncAttempts = 0;
    _resyncTimer?.cancel();
    await _performResync();
  }

  /// Check if currently attempting to resync
  bool get isResyncInProgress => _isResyncInProgress;

  /// Get current resync attempt count
  int get resyncAttempts => _resyncAttempts;

  /// Check for pending call acceptances from CallKit when app was terminated
  Future<void> _checkPendingCallAcceptances() async {
    try {
      if (_calls == null) {
        debugPrint(
            'Calls service not available, cannot check pending acceptances');
        return;
      }

      // Check for the most recent accepted call
      final lastAcceptedCall =
          await CommonComponents.getSavedData('last_accepted_call') != null
              ? jsonDecode(
                  await CommonComponents.getSavedData('last_accepted_call'))
              : {};
      final callId = lastAcceptedCall['call_id'] as String?;
      final roomId = lastAcceptedCall['room_id'] as String?;
      final eventId = lastAcceptedCall['event_id'] as String?;
      final acceptedViaCallKit =
          lastAcceptedCall['accepted_via_callkit'] as bool? ?? false;
      final acceptedAt = lastAcceptedCall['accepted_at'] as int?;

      if (callId != null && roomId != null && acceptedViaCallKit) {
        // Check if this acceptance is recent (within last 2 minutes)
        final now = DateTime.now().millisecondsSinceEpoch;
        final acceptedTime = acceptedAt ?? 0;
        final timeDifference = now - acceptedTime;
        const maxAcceptanceAge = 2 * 60 * 1000; // 2 minutes

        if (timeDifference <= maxAcceptanceAge) {
          debugPrint('Found recent call acceptance via CallKit: $callId');

          // Clear the acceptance data to prevent duplicate processing
          await CommonComponents.deleteSavedData('last_accepted_call');
          await CommonComponents.deleteSavedData('accepted_call_$callId');

          // Process the call acceptance
          await _processCallAcceptance(callId, roomId, eventId);
        } else {
          debugPrint(
              'Found old call acceptance, ignoring (age: ${timeDifference}ms)');
          await CommonComponents.deleteSavedData('last_accepted_call');
          await CommonComponents.deleteSavedData('accepted_call_$callId');
        }
      }
    } catch (e, s) {
      debugPrintStack(
          label: 'Error checking pending call acceptances: $e', stackTrace: s);
    }
  }

  /// Process a call acceptance that was stored when app was terminated
  Future<void> _processCallAcceptance(
      String callId, String roomId, String? eventId) async {
    try {
      if (_calls == null || _voIP == null) {
        debugPrint('Calls service not available');
        return;
      }

      debugPrint('Processing call acceptance: $callId in room: $roomId');

      // First check if we have the room
      final room = _client?.getRoomById(roomId);
      if (room == null) {
        debugPrint('Room $roomId not found, cannot accept call');
        return;
      }

      // Fallback: try accepting with just callId and roomId
      try {
        final eventId =
            await CommonComponents.getSavedData('pending_matrix_event_id')
                as String?;
        NavigationQueue.setPendingCallNavigation(PendingNavigation(path: '/call/$roomId'));
        await _calls?.acceptIncomingCall(roomId, callId, eventId);
        debugPrint('Successfully accepted call $callId via fallback method');
      } catch (e, s) {
        debugPrintStack(
            label: 'Failed to accept call $callId: $e', stackTrace: s);
      }
    } catch (e) {
      debugPrint('Error processing call acceptance: $e');
    }
  }
}
