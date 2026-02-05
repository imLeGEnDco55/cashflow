import 'package:flutter_test/flutter_test.dart';
import 'package:cashflow_flutter/models/finance.dart';

void main() {
  group('Transaction Model', () {
    test('should create a valid transaction', () {
      final t = Transaction(
        amount: 100.0,
        type: TransactionType.expense,
        categoryId: 'food',
        paymentMethod: 'cash',
        date: DateTime(2023, 10, 1),
      );

      expect(t.amount, 100.0);
      expect(t.type, TransactionType.expense);
      expect(t.isRecurring, false); // Default
    });

    test('should serialize and deserialize correctly (toMap/fromMap)', () {
      final t = Transaction(
        id: 'test-id',
        amount: 50.5,
        type: TransactionType.income,
        categoryId: 'salary',
        paymentMethod: 'bank',
        date: DateTime(2023, 10, 1),
        isRecurring: true,
      );

      final map = t.toMap();
      final t2 = Transaction.fromMap(map);

      expect(t2.id, t.id);
      expect(t2.amount, t.amount);
      expect(t2.type, t.type);
      expect(t2.isRecurring, true);
      expect(t2.date, t.date);
    });

    test('should handle sub-emoji breakdown serialization', () {
      final t = Transaction(
        amount: 20.0,
        type: TransactionType.expense,
        categoryId: 'super-cat',
        paymentMethod: 'cash',
        breakdown: [
          SubEmojiItem(categoryId: 'sub1', amount: 10.0),
          SubEmojiItem(categoryId: 'sub2', amount: 10.0),
        ],
      );

      final map = t.toMap();
      final t2 = Transaction.fromMap(map);

      expect(t2.breakdown, isNotNull);
      expect(t2.breakdown!.length, 2);
      expect(t2.breakdown![0].categoryId, 'sub1');
    });

    test('copyWith should return updated instance', () {
      final t = Transaction(
        amount: 10.0,
        type: TransactionType.expense,
        categoryId: 'food',
        paymentMethod: 'cash',
      );

      final t2 = t.copyWith(amount: 20.0, categoryId: 'travel');

      expect(t2.amount, 20.0);
      expect(t2.categoryId, 'travel');
      expect(t2.paymentMethod, 'cash'); // Unchanged
    });
  });
}
