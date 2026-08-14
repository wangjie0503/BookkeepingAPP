import 'package:flutter_test/flutter_test.dart';
import 'package:personal_bookkeeping/shared/money.dart';

void main() {
  group('Money', () {
    test('stores yuan with at most one decimal as jiao', () {
      expect(Money.parseJiao('18'), 180);
      expect(Money.parseJiao('18.5'), 185);
      expect(Money.formatJiao(180), '¥18');
      expect(Money.formatJiao(185), '¥18.5');
    });

    test('rejects invalid expense amounts', () {
      for (final input in ['0', '-1', '18.25', 'abc', '']) {
        expect(() => Money.parseJiao(input), throwsFormatException);
      }
    });

    test('allows zero for a budget but keeps one-decimal precision', () {
      expect(Money.parseNonNegativeJiao('0'), 0);
      expect(Money.parseNonNegativeJiao('25.6'), 256);
      expect(() => Money.parseNonNegativeJiao('1.23'), throwsFormatException);
    });
  });
}
