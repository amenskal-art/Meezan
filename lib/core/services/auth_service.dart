import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static Stream<User?> get authState => _auth.authStateChanges();
  static User? get current => _auth.currentUser;

  static Future<UserCredential> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  /// Registers the account then writes the role profile document.
  /// Lawyers are ALWAYS created as status = 'pending' (enforced again by rules).
  static Future<void> register({
    required String email,
    required String password,
    required String role, // 'client' | 'lawyer'
    required String name,
    required String phone,
    required String governorate,
    String specialization = '',
    String language = 'ar',
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
    final user = AppUser(
      uid: cred.user!.uid,
      role: role,
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      governorate: governorate,
      language: language,
      specialization: role == 'lawyer' ? specialization : '',
      status: role == 'lawyer' ? 'pending' : '',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  static Future<void> signOut() => _auth.signOut();

  /// Reads the `admin` custom claim (set via the grant-admin workflow).
  static Future<bool> isAdmin() async {
    final u = _auth.currentUser;
    if (u == null) return false;
    final token = await u.getIdTokenResult(true);
    return token.claims?['admin'] == true;
  }
}
