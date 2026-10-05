import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handles a message that arrives while the app is terminated or in the
/// background. Must be a top-level function for the platform to invoke it.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Nothing to do beyond letting the system tray show the notification; the
  // tap is handled by [NotificationService] once the app is running.
  debugPrint('Background FCM message: ${message.messageId}');
}

/// Push notifications for new approval requests.
///
/// Flow: an expense is raised -> a notification is delivered to the admin
/// device -> tapping it opens that expense's approval detail screen.
class NotificationService {
  NotificationService(this._messaging, this._local, this._db, this._auth);

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _local;
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  static const _channel = AndroidNotificationChannel(
    'approvals',
    'Approval alerts',
    description: 'Notifies the admin when an expense needs a decision.',
    importance: Importance.high,
  );

  /// Called with the expense id when a notification is tapped.
  void Function(String expenseId)? onApprovalTapped;

  Future<void> initialise() async {
    await _messaging.requestPermission();

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) _handlePayload(jsonDecode(payload));
      },
    );

    // Foreground: FCM does not show a tray notification itself, so mirror it
    // through the local plugin.
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      _local.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    });

    // Background -> tapped while the app was alive.
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _handlePayload(m.data));

    // Terminated -> tapped to launch the app.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _handlePayload(initial.data);

    await _saveToken();
    _messaging.onTokenRefresh.listen((token) => _saveToken(token));
  }

  void _handlePayload(Map<String, dynamic> data) {
    final expenseId = data['expenseId'];
    if (expenseId is String && expenseId.isNotEmpty) {
      onApprovalTapped?.call(expenseId);
    }
  }

  /// Stores the device token against the signed-in admin so a server or the
  /// Firebase console can target this device.
  ///
  /// Uses `update` rather than `set(merge:)` deliberately: the security rules
  /// require a `role` field on create, so a merge that happened to land before
  /// the profile document existed would be rejected. Updating a missing
  /// document fails harmlessly instead, and the token is picked up on the next
  /// refresh once the profile exists.
  Future<void> _saveToken([String? existing]) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final token = existing ?? await _messaging.getToken();
    if (token == null) return;

    try {
      await _db.collection('users').doc(user.uid).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
      debugPrint('FCM token registered: $token');
    } on FirebaseException catch (e) {
      debugPrint('Could not store FCM token (${e.code}); will retry later.');
    }
  }

  /// Shows a local approval notification. Used when an expense is raised from
  /// this device, so the end-to-end tap-to-detail flow can be demonstrated
  /// without a server component.
  Future<void> showApprovalAlert({
    required String expenseId,
    required String employeeName,
    required String amount,
  }) async {
    await _local.show(
      id: expenseId.hashCode,
      title: 'New expense approval',
      body: '$employeeName raised an expense of $amount awaiting your decision.',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: jsonEncode({'expenseId': expenseId}),
    );
  }
}
