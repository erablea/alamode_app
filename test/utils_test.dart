import 'package:flutter_test/flutter_test.dart';
import 'package:alamode_app/view/memo.dart';

void main() {
  group('Utils.formatCurrency', () {
    test('adds thousands separators', () {
      expect(Utils.formatCurrency(1000), '1,000');
      expect(Utils.formatCurrency(1234567), '1,234,567');
    });

    test('handles small numbers without separators', () {
      expect(Utils.formatCurrency(0), '0');
      expect(Utils.formatCurrency(999), '999');
    });

    test('returns empty string for null', () {
      expect(Utils.formatCurrency(null), '');
    });
  });

  group('Utils.normalizeString', () {
    test('converts hiragana to katakana', () {
      expect(Utils.normalizeString('ぷりん'), 'プリン');
    });

    test('lowercases and strips punctuation/whitespace', () {
      // ・とー(長音記号)も除去対象のため「ゴー」は「ゴ」になる
      expect(Utils.normalizeString('ABC　DEF・ゴー！'), 'abcdefゴ');
    });
  });

  group('Utils.generateUniqueId', () {
    test('generates non-empty, distinct ids', () {
      final id1 = Utils.generateUniqueId();
      final id2 = Utils.generateUniqueId();
      expect(id1, isNotEmpty);
      expect(id2, isNotEmpty);
      expect(id1, isNot(equals(id2)));
    });
  });
}
