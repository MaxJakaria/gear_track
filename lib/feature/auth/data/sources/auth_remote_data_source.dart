import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract interface class AuthRemoteDataSource {
  Future<String> sendSignInLink();
  Stream<bool> watchSessionApproval(String sessionId);
  Future<void> completeSessionLogin(String sessionId);
  Future<bool> checkAuthStatus();
  Future<void> signOut();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  static const String authorizedAdminEmail = 'maxjakaria824@gmail.com';

  AuthRemoteDataSourceImpl({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<String> sendSignInLink() async {
    final sessionId =
        '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond % 1000}';

    // 1. Create a pending cross-device session document in Firestore
    await _firestore.collection('auth_sessions').doc(sessionId).set({
      'sessionId': sessionId,
      'email': authorizedAdminEmail,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Dispatch email link via Firebase Auth
    final actionCodeSettings = ActionCodeSettings(
      url: 'https://geartrack-9ccdb.firebaseapp.com/?session_id=$sessionId',
      handleCodeInApp: true,
      androidPackageName: 'com.example.gear_track',
      androidMinimumVersion: '1',
    );

    await _firebaseAuth.sendSignInLinkToEmail(
      email: authorizedAdminEmail,
      actionCodeSettings: actionCodeSettings,
    );

    return sessionId;
  }

  @override
  Stream<bool> watchSessionApproval(String sessionId) {
    return _firestore
        .collection('auth_sessions')
        .doc(sessionId)
        .snapshots()
        .map((doc) => doc.exists && doc.data()?['status'] == 'approved');
  }

  @override
  Future<void> completeSessionLogin(String sessionId) async {
    await _firestore.collection('auth_sessions').doc(sessionId).delete();
    if (_firebaseAuth.currentUser == null) {
      try {
        await _firebaseAuth.signInAnonymously();
      } catch (_) {}
    }
  }

  @override
  Future<bool> checkAuthStatus() async {
    return _firebaseAuth.currentUser != null;
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
