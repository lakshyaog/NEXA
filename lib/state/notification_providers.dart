import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/notification_service.dart';
import 'auth_providers.dart';
import 'dashboard_providers.dart';

final firebaseMessagingProvider =
    Provider<FirebaseMessaging>((_) => FirebaseMessaging.instance);

final localNotificationsProvider =
    Provider<FlutterLocalNotificationsPlugin>((_) =>
        FlutterLocalNotificationsPlugin());

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    ref.watch(firebaseMessagingProvider),
    ref.watch(localNotificationsProvider),
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});
