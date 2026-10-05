import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Keeps the signed-in admin's profile document in sync.
///
/// Security rules grant access to business data only to a user that has a
/// `/users/{uid}` document with `role == "admin"`, so the document has to
/// exist before the first Firestore read succeeds.
class UserService {
  UserService(this._db);
  final FirebaseFirestore _db;

  Future<void> ensureAdminProfile(User user) async {
    final ref = _db.collection('users').doc(user.uid);
    final snapshot = await ref.get();

    if (!snapshot.exists) {
      await ref.set({
        'uid': user.uid,
        'email': user.email,
        'role': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    await ref.update({'lastLoginAt': FieldValue.serverTimestamp()});
  }
}
