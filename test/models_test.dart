import 'package:flutter_test/flutter_test.dart';
import 'package:meezan/core/constants.dart';
import 'package:meezan/core/models.dart';

/// Pure-Dart tests (no Firebase, no widgets) so `flutter test` runs green in
/// CI without emulators.
void main() {
  group('AppUser', () {
    test('round-trips through toMap/fromMap', () {
      const u = AppUser(
        uid: 'u1',
        role: 'lawyer',
        name: 'Ali',
        email: 'ali@example.com',
        governorate: 'erbil',
        specialization: 'criminal',
        status: 'pending',
        createdAt: 1234,
      );
      final copy = AppUser.fromMap('u1', u.toMap());
      expect(copy.role, 'lawyer');
      expect(copy.isLawyer, isTrue);
      expect(copy.isApprovedLawyer, isFalse);
      expect(copy.governorate, 'erbil');
      expect(copy.createdAt, 1234);
    });

    test('approved lawyer flag', () {
      const u = AppUser(uid: 'u2', role: 'lawyer', status: 'approved');
      expect(u.isApprovedLawyer, isTrue);
    });
  });

  group('LegalCase', () {
    test('round-trips with milestones', () {
      const c = LegalCase(
        id: 'c1',
        clientId: 'cl',
        lawyerId: 'lw',
        title: 'قضية إيجار',
        milestones: [
          Milestone(title: 'تقديم الدعوى', dateMs: 10, done: true),
          Milestone(title: 'الجلسة الأولى', dateMs: 20),
        ],
      );
      final copy = LegalCase.fromMap('c1', c.toMap());
      expect(copy.milestones.length, 2);
      expect(copy.milestones.first.done, isTrue);
      expect(copy.milestones.last.done, isFalse);
    });
  });

  group('InvoiceModel', () {
    test('paidIqd sums installments', () {
      const inv = InvoiceModel(
        id: 'i1',
        lawyerId: 'lw',
        clientId: 'cl',
        amountIqd: 1000000,
        installments: [
          Installment(amountIqd: 250000, dateMs: 1),
          Installment(amountIqd: 250000, dateMs: 2),
        ],
      );
      expect(inv.paidIqd, 500000);
      final copy = InvoiceModel.fromMap('i1', inv.toMap());
      expect(copy.paidIqd, 500000);
      expect(copy.amountIqd, 1000000);
    });
  });

  group('constants', () {
    test('IQD formatting groups thousands', () {
      expect(formatIqd(1250000), '1,250,000 د.ع');
      expect(formatIqd(0), '0 د.ع');
      expect(formatIqd(999), '999 د.ع');
    });

    test('all 19 governorates have labels in 3 languages', () {
      expect(Governorates.codes.length, 19);
      for (final c in Governorates.codes) {
        for (final lang in ['ar', 'ckb', 'en']) {
          expect(Governorates.label(c, lang), isNotEmpty);
        }
      }
    });

    test('specializations have labels', () {
      for (final c in Specializations.codes) {
        expect(Specializations.label(c, 'ar'), isNotEmpty);
      }
    });
  });
}
