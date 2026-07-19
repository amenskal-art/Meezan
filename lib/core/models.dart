/// Pure-Dart data models (no Firestore SDK types) so they stay unit-testable.
/// All dates are stored as millisecondsSinceEpoch ints.
library;

class AppUser {
  final String uid, role, name, email, phone, governorate, language;
  final String specialization, status, rejectionReason, syndicateDocPath, bio;
  final int createdAt;

  const AppUser({
    required this.uid,
    required this.role,
    this.name = '',
    this.email = '',
    this.phone = '',
    this.governorate = 'baghdad',
    this.language = 'ar',
    this.specialization = '',
    this.status = '',
    this.rejectionReason = '',
    this.syndicateDocPath = '',
    this.bio = '',
    this.createdAt = 0,
  });

  bool get isLawyer => role == 'lawyer';
  bool get isApprovedLawyer => isLawyer && status == 'approved';

  factory AppUser.fromMap(String uid, Map<String, dynamic> m) => AppUser(
        uid: uid,
        role: (m['role'] ?? 'client') as String,
        name: (m['name'] ?? '') as String,
        email: (m['email'] ?? '') as String,
        phone: (m['phone'] ?? '') as String,
        governorate: (m['governorate'] ?? 'baghdad') as String,
        language: (m['language'] ?? 'ar') as String,
        specialization: (m['specialization'] ?? '') as String,
        status: (m['status'] ?? '') as String,
        rejectionReason: (m['rejectionReason'] ?? '') as String,
        syndicateDocPath: (m['syndicateDocPath'] ?? '') as String,
        bio: (m['bio'] ?? '') as String,
        createdAt: (m['createdAt'] ?? 0) as int,
      );

  Map<String, dynamic> toMap() => {
        'role': role, 'name': name, 'email': email, 'phone': phone,
        'governorate': governorate, 'language': language,
        'specialization': specialization, 'status': status,
        'rejectionReason': rejectionReason,
        'syndicateDocPath': syndicateDocPath, 'bio': bio,
        'createdAt': createdAt,
      };
}

class Milestone {
  final String title;
  final int dateMs;
  final bool done;
  const Milestone({required this.title, required this.dateMs, this.done = false});
  factory Milestone.fromMap(Map<String, dynamic> m) => Milestone(
        title: (m['title'] ?? '') as String,
        dateMs: (m['dateMs'] ?? 0) as int,
        done: (m['done'] ?? false) as bool,
      );
  Map<String, dynamic> toMap() => {'title': title, 'dateMs': dateMs, 'done': done};
}

class LegalCase {
  final String id, clientId, lawyerId, clientName, title, caseNumber, court, status;
  final int nextHearingMs, createdAt;
  final List<Milestone> milestones;
  const LegalCase({
    required this.id, required this.clientId, required this.lawyerId,
    this.clientName = '', this.title = '', this.caseNumber = '', this.court = '',
    this.status = 'active', this.nextHearingMs = 0, this.createdAt = 0,
    this.milestones = const [],
  });
  factory LegalCase.fromMap(String id, Map<String, dynamic> m) => LegalCase(
        id: id,
        clientId: (m['clientId'] ?? '') as String,
        lawyerId: (m['lawyerId'] ?? '') as String,
        clientName: (m['clientName'] ?? '') as String,
        title: (m['title'] ?? '') as String,
        caseNumber: (m['caseNumber'] ?? '') as String,
        court: (m['court'] ?? '') as String,
        status: (m['status'] ?? 'active') as String,
        nextHearingMs: (m['nextHearingMs'] ?? 0) as int,
        createdAt: (m['createdAt'] ?? 0) as int,
        milestones: ((m['milestones'] ?? []) as List)
            .map((e) => Milestone.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
  Map<String, dynamic> toMap() => {
        'clientId': clientId, 'lawyerId': lawyerId, 'clientName': clientName,
        'title': title, 'caseNumber': caseNumber, 'court': court,
        'status': status, 'nextHearingMs': nextHearingMs, 'createdAt': createdAt,
        'milestones': milestones.map((e) => e.toMap()).toList(),
      };
}

class Appointment {
  final String id, clientId, lawyerId, clientName, lawyerName, type, status, notes;
  final int whenMs;
  const Appointment({
    required this.id, required this.clientId, required this.lawyerId,
    this.clientName = '', this.lawyerName = '',
    this.type = 'video', this.status = 'scheduled', this.notes = '',
    this.whenMs = 0,
  });
  factory Appointment.fromMap(String id, Map<String, dynamic> m) => Appointment(
        id: id,
        clientId: (m['clientId'] ?? '') as String,
        lawyerId: (m['lawyerId'] ?? '') as String,
        clientName: (m['clientName'] ?? '') as String,
        lawyerName: (m['lawyerName'] ?? '') as String,
        type: (m['type'] ?? 'video') as String,
        status: (m['status'] ?? 'scheduled') as String,
        notes: (m['notes'] ?? '') as String,
        whenMs: (m['whenMs'] ?? 0) as int,
      );
  Map<String, dynamic> toMap() => {
        'clientId': clientId, 'lawyerId': lawyerId,
        'clientName': clientName, 'lawyerName': lawyerName,
        'type': type, 'status': status, 'notes': notes, 'whenMs': whenMs,
      };
}

class Installment {
  final int amountIqd, dateMs;
  const Installment({required this.amountIqd, required this.dateMs});
  factory Installment.fromMap(Map<String, dynamic> m) => Installment(
      amountIqd: (m['amountIqd'] ?? 0) as int, dateMs: (m['dateMs'] ?? 0) as int);
  Map<String, dynamic> toMap() => {'amountIqd': amountIqd, 'dateMs': dateMs};
}

class InvoiceModel {
  final String id, lawyerId, clientId, clientName, caseId, status;
  final int amountIqd, dueMs, issuedMs;
  final List<Installment> installments;
  const InvoiceModel({
    required this.id, required this.lawyerId, required this.clientId,
    this.clientName = '', this.caseId = '', this.status = 'unpaid',
    this.amountIqd = 0, this.dueMs = 0, this.issuedMs = 0,
    this.installments = const [],
  });
  int get paidIqd => installments.fold(0, (s, i) => s + i.amountIqd);
  factory InvoiceModel.fromMap(String id, Map<String, dynamic> m) => InvoiceModel(
        id: id,
        lawyerId: (m['lawyerId'] ?? '') as String,
        clientId: (m['clientId'] ?? '') as String,
        clientName: (m['clientName'] ?? '') as String,
        caseId: (m['caseId'] ?? '') as String,
        status: (m['status'] ?? 'unpaid') as String,
        amountIqd: (m['amountIqd'] ?? 0) as int,
        dueMs: (m['dueMs'] ?? 0) as int,
        issuedMs: (m['issuedMs'] ?? 0) as int,
        installments: ((m['installments'] ?? []) as List)
            .map((e) => Installment.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
  Map<String, dynamic> toMap() => {
        'lawyerId': lawyerId, 'clientId': clientId, 'clientName': clientName,
        'caseId': caseId, 'status': status, 'amountIqd': amountIqd,
        'dueMs': dueMs, 'issuedMs': issuedMs,
        'installments': installments.map((e) => e.toMap()).toList(),
      };
}

class VaultDoc {
  final String id, ownerId, caseId, name, storagePath, url;
  final List<String> sharedWith;
  final int uploadedAt;
  const VaultDoc({
    required this.id, required this.ownerId,
    this.caseId = '', this.name = '', this.storagePath = '', this.url = '',
    this.sharedWith = const [], this.uploadedAt = 0,
  });
  factory VaultDoc.fromMap(String id, Map<String, dynamic> m) => VaultDoc(
        id: id,
        ownerId: (m['ownerId'] ?? '') as String,
        caseId: (m['caseId'] ?? '') as String,
        name: (m['name'] ?? '') as String,
        storagePath: (m['storagePath'] ?? '') as String,
        url: (m['url'] ?? '') as String,
        sharedWith: ((m['sharedWith'] ?? []) as List).cast<String>(),
        uploadedAt: (m['uploadedAt'] ?? 0) as int,
      );
  Map<String, dynamic> toMap() => {
        'ownerId': ownerId, 'caseId': caseId, 'name': name,
        'storagePath': storagePath, 'url': url,
        'sharedWith': sharedWith, 'uploadedAt': uploadedAt,
      };
}
