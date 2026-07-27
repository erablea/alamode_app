import 'package:flutter_test/flutter_test.dart';
import 'package:alamode_app/main.dart';

// Homeやリストの間に3件ごとに広告枠を挟むためのインデックス計算ロジック。
// 表示件数とループ処理をまたぐため、ロジックだけを切り出して検証する。
void main() {
  group('AdUtils list/ad index math', () {
    test('calculateListItemCount adds one slot per 3 items beyond the first 3', () {
      expect(AdUtils.calculateListItemCount(0), 0);
      expect(AdUtils.calculateListItemCount(3), 3);
      expect(AdUtils.calculateListItemCount(4), 5);
      expect(AdUtils.calculateListItemCount(7), 9);
      expect(AdUtils.calculateListItemCount(10), 13);
    });

    test('shouldShowAdAt marks every 4th slot (index 3, 7, 11, ...)', () {
      final adSlots = List.generate(13, AdUtils.shouldShowAdAt)
          .asMap()
          .entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();
      expect(adSlots, [3, 7, 11]);
    });

    test('getActualItemIndex maps list index back to the underlying item index', () {
      // list: [item0, item1, item2, AD, item3, item4, item5, AD, item6, ...]
      expect(AdUtils.getActualItemIndex(0), 0);
      expect(AdUtils.getActualItemIndex(2), 2);
      expect(AdUtils.getActualItemIndex(4), 3);
      expect(AdUtils.getActualItemIndex(6), 5);
      expect(AdUtils.getActualItemIndex(8), 6);
    });

    test('calculateListItemCount and shouldShowAdAt agree on where ads land', () {
      const itemCount = 10;
      final totalSlots = AdUtils.calculateListItemCount(itemCount);
      var actualItemsSeen = 0;
      for (var i = 0; i < totalSlots; i++) {
        if (AdUtils.shouldShowAdAt(i)) continue;
        expect(AdUtils.getActualItemIndex(i), actualItemsSeen);
        actualItemsSeen++;
      }
      expect(actualItemsSeen, itemCount);
    });
  });
}
