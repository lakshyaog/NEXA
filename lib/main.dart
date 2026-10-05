import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_theme.dart';
import 'core/router.dart';
import 'services/notification_service.dart';
import 'state/notification_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Cached reads keep the app usable without a connection, and queued writes
  // are flushed by the SDK once it reconnects.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(const ProviderScope(child: NexaAdminApp()));
}

class NexaAdminApp extends ConsumerStatefulWidget {
  const NexaAdminApp({super.key});

  @override
  ConsumerState<NexaAdminApp> createState() => _NexaAdminAppState();
}

class _NexaAdminAppState extends ConsumerState<NexaAdminApp> {
  @override
  void initState() {
    super.initState();
    // Deferred so the router provider is available when a tap arrives.
    WidgetsBinding.instance.addPostFrameCallback((_) => _setUpNotifications());
  }

  Future<void> _setUpNotifications() async {
    final notifications = ref.read(notificationServiceProvider);
    notifications.onApprovalTapped = (expenseId) {
      ref.read(routerProvider).go('${Routes.approvals}/$expenseId');
    };
    await notifications.initialise();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'NEXA Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
