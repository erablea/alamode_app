import 'package:flutter_test/flutter_test.dart';
import 'package:alamode_app/view/memo.dart';

// メモの「その他条件」(個包装/常温/オンライン購入/洋酒)は、DBには
// "個包装:yes,常温:no" のような1本の文字列として保存されるため、
// パース・組み立てが壊れると保存済みデータの条件表示が全部崩れる。
void main() {
  group('CommonWidgets.parseConditionString / serializeConditionStates', () {
    test('round-trips through serialize -> parse', () {
      final states = {
        '個包装': 'yes',
        '常温': 'no',
        'オンライン購入': 'unknown',
        '洋酒': 'yes',
      };
      final serialized = CommonWidgets.serializeConditionStates(states);
      final parsed = CommonWidgets.parseConditionString(serialized);

      expect(parsed['個包装'], 'yes');
      expect(parsed['常温'], 'no');
      expect(parsed['オンライン購入'], 'unknown');
      expect(parsed['洋酒'], 'yes');
    });

    test('serialize omits unknown-state keys', () {
      final serialized = CommonWidgets.serializeConditionStates({
        '個包装': 'unknown',
        '常温': 'yes',
      });
      expect(serialized, '常温:yes');
    });

    test('parse defaults every known key to unknown for null/empty input', () {
      for (final raw in [null, '']) {
        final parsed = CommonWidgets.parseConditionString(raw);
        for (final key in CommonWidgets.conditionKeys) {
          expect(parsed[key], 'unknown', reason: 'key=$key raw=$raw');
        }
      }
    });

    test('parse supports legacy (pre key:value) format', () {
      final parsed = CommonWidgets.parseConditionString('個包装,常温,オンライン購入,洋酒不使用');
      expect(parsed['個包装'], 'yes');
      expect(parsed['常温'], 'yes');
      expect(parsed['オンライン購入'], 'yes');
      expect(parsed['洋酒'], 'yes');
    });

    test('parse supports legacy 洋酒使用 (alcohol used) marker', () {
      final parsed = CommonWidgets.parseConditionString('洋酒使用');
      expect(parsed['洋酒'], 'no');
    });

    test('parse ignores unknown keys embedded in key:value format', () {
      final parsed = CommonWidgets.parseConditionString('個包装:yes,存在しない項目:yes');
      expect(parsed['個包装'], 'yes');
      expect(parsed.containsKey('存在しない項目'), isFalse);
    });
  });
}
