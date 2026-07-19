import 'package:cloud_firestore/cloud_firestore.dart';

import '../models.dart';

/// Thin typed layer over Firestore. Sorting is done client-side to avoid
/// composite-index sprawl (list sizes here are small per user).
class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  // ---------- Users ----------
  static Stream<AppUser?> userStream(String uid) =>
      _db.collection('users').doc(uid).snapshots().map((d) =>
          d.exists ? AppUser.fromMap(d.id, d.data()!) : null);

  static Future<void> updateUser(String uid, Map<String, dynamic> patch) =>
      _db.collection('users').doc(uid).update(patch);

  static Stream<List<AppUser>> approvedLawyers(
      {String? specialization, String? governorate}) {
    Query<Map<String, dynamic>> q = _db
        .collection('users')
        .where('role', isEqualTo: 'lawyer')
        .where('status', isEqualTo: 'approved');
    if (specialization != null && specialization.isNotEmpty) {
      q = q.where('specialization', isEqualTo: specialization);
    }
    if (governorate != null && governorate.isNotEmpty) {
      q = q.where('governorate', isEqualTo: governorate);
    }
    return q.snapshots().map((s) =>
        s.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList());
  }

  static Stream<List<AppUser>> lawyersByStatus(String status) => _db
      .collection('users')
      .where('role', isEqualTo: 'lawyer')
      .where('status', isEqualTo: status)
      .snapshots()
      .map((s) => s.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList());

  static Future<AppUser?> findClientByEmail(String email) async {
    final s = await _db
        .collection('users')
        .where('email', isEqualTo: email.trim())
        .limit(1)
        .get();
    if (s.docs.isEmpty) return null;
    return AppUser.fromMap(s.docs.first.id, s.docs.first.data());
  }

  // ---------- Cases ----------
  static Stream<List<LegalCase>> casesFor(String uid, {required bool asLawyer}) =>
      _db
          .collection('cases')
          .where(asLawyer ? 'lawyerId' : 'clientId', isEqualTo: uid)
          .snapshots()
          .map((s) {
        final list =
            s.docs.map((d) => LegalCase.fromMap(d.id, d.data())).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });

  static Future<void> createCase(LegalCase c) =>
      _db.collection('cases').add(c.toMap());

  static Future<void> updateCase(String id, Map<String, dynamic> patch) =>
      _db.collection('cases').doc(id).update(patch);

  // ---------- Appointments ----------
  static Stream<List<Appointment>> appointmentsFor(String uid,
          {required bool asLawyer}) =>
      _db
          .collection('appointments')
          .where(asLawyer ? 'lawyerId' : 'clientId', isEqualTo: uid)
          .snapshots()
          .map((s) {
        final list =
            s.docs.map((d) => Appointment.fromMap(d.id, d.data())).toList();
        list.sort((a, b) => a.whenMs.compareTo(b.whenMs));
        return list;
      });

  static Future<void> createAppointment(Appointment a) =>
      _db.collection('appointments').add(a.toMap());

  static Future<void> updateAppointment(String id, Map<String, dynamic> patch) =>
      _db.collection('appointments').doc(id).update(patch);

  // ---------- Invoices ----------
  static Stream<List<InvoiceModel>> invoicesFor(String uid,
          {required bool asLawyer}) =>
      _db
          .collection('invoices')
          .where(asLawyer ? 'lawyerId' : 'clientId', isEqualTo: uid)
          .snapshots()
          .map((s) {
        final list =
            s.docs.map((d) => InvoiceModel.fromMap(d.id, d.data())).toList();
        list.sort((a, b) => b.issuedMs.compareTo(a.issuedMs));
        return list;
      });

  static Future<void> createInvoice(InvoiceModel i) =>
      _db.collection('invoices').add(i.toMap());

  static Future<void> updateInvoice(String id, Map<String, dynamic> patch) =>
      _db.collection('invoices').doc(id).update(patch);

  // ---------- Vault documents ----------
  static Stream<List<VaultDoc>> docsOwned(String uid) => _db
      .collection('documents')
      .where('ownerId', isEqualTo: uid)
      .snapshots()
      .map((s) => s.docs.map((d) => VaultDoc.fromMap(d.id, d.data())).toList());

  static Stream<List<VaultDoc>> docsSharedWith(String uid) => _db
      .collection('documents')
      .where('sharedWith', arrayContains: uid)
      .snapshots()
      .map((s) => s.docs.map((d) => VaultDoc.fromMap(d.id, d.data())).toList());

  static Future<void> createDoc(VaultDoc d) =>
      _db.collection('documents').add(d.toMap());

  static Future<void> shareDoc(String docId, String lawyerUid) =>
      _db.collection('documents').doc(docId).update({
        'sharedWith': FieldValue.arrayUnion([lawyerUid])
      });

  static Future<void> deleteDoc(String docId) =>
      _db.collection('documents').doc(docId).delete();
}
