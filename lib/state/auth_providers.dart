import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'dashboard_providers.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((_) => FirebaseAuth.instance);

final authServiceProvider =
    Provider<AuthService>((ref) => AuthService(ref.watch(firebaseAuthProvider)));

final userServiceProvider =
    Provider<UserService>((ref) => UserService(ref.watch(firestoreProvider)));

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authServiceProvider).authStateChanges(),
);

/// Creates or refreshes the admin profile document that the security rules
/// check. Screens that read business data wait on this first.
final adminProfileProvider = FutureProvider<void>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return;
  await ref.watch(userServiceProvider).ensureAdminProfile(user);
});
