import 'package:alamode_app/main.dart';

/// itemの表示画像を解決する。
/// 優先順位: 1) itemに登録された画像(公式許諾済み想定) 2) 紐づいて承認済みの
/// useritemの画像 3) どちらも無ければ空(呼び出し側でデフォルト画像を表示する)。
class ItemImageService {
  static List<String> ownImageUrls(Map<String, dynamic> item) {
    final urls = <String>[];
    for (final key in ['item_imageurl1', 'item_imageurl2', 'item_imageurl3']) {
      final url = item[key] as String?;
      if (url != null && url.isNotEmpty) urls.add(url);
    }
    return urls;
  }

  static Future<List<String>> resolveImageUrls(Map<String, dynamic> item) async {
    final own = ownImageUrls(item);
    if (own.isNotEmpty) return own;

    final itemId = item['item_id']?.toString();
    if (itemId == null) return [];

    try {
      final rows = await supabase
          .from('useritem')
          .select('useritem_image')
          .eq('item_id', itemId)
          .eq('useritem_approved', true)
          .not('useritem_image', 'is', null)
          .order('useritem_update', ascending: false)
          .limit(1);
      if (rows.isNotEmpty) {
        final fallback = rows.first['useritem_image'] as String?;
        if (fallback != null && fallback.isNotEmpty) return [fallback];
      }
    } catch (_) {
      // フォールバック取得に失敗してもデフォルト画像表示に委ねる
    }
    return [];
  }
}
