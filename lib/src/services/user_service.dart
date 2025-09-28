import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final userServiceProvider = Provider<UserService>((ref) => UserService._());
final currentUserRoleProvider = StreamProvider<String?>((ref) {
  return UserService._().roleStream();
});

class UserService {
  UserService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Future<void> upsertCurrentUser() async {
    final u = _auth.currentUser!;
    final doc = _db.collection('users').doc(u.uid);
    await doc.set({
      'phoneNumber': u.phoneNumber,
      'name': u.displayName ?? '',
      'role': FieldValue.delete(), // Owner will set proper role later
      'lastLoginAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> touchLastLogin() async {
    final u = _auth.currentUser!;
    await _db.collection('users').doc(u.uid).update({
      'lastLoginAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<String?> roleStream() {
    final u = _auth.currentUser!;
    return _db.collection('users').doc(u.uid).snapshots().map((s) {
      return s.data()?['role'] as String?;
    });
  }
}
