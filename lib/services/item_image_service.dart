import 'package:alamode_app/main.dart';

/// itemの表示画像を解決する。
/// 優先順位: 1) itemに登録された画像(公式許諾済み想定) 2) 他ユーザーが
/// 投稿しSupabase Storageに公開されているuseritemの画像 3) どちらも無ければ
/// 空(呼び出し側でデフォルト画像を表示する)。
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
    final community = await resolveCommunityImage(item);
    return community == null ? [] : [community['url'] as String];
  }

  /// itemに公式画像が無い場合、他ユーザーが投稿した写真をコミュニティ画像として
  /// 返す（useritem_id込み。通報ボタンから対象を特定するために必要）。
  static Future<Map<String, dynamic>?> resolveCommunityImage(
      Map<String, dynamic> item) async {
    if (ownImageUrls(item).isNotEmpty) return null;

    final itemId = item['item_id']?.toString();
    if (itemId == null) return null;

    try {
      // useritemテーブル自体ではなく、公開してよい列だけに絞ったビュー
      // (useritem_public_image、Storageアップロード済み＝投稿時点で自動公開)
      // 経由で取得する。他ユーザーのメモ・価格・ブランド名などが
      // 混ざって見えることがないようにするため。
      final rows = await supabase
          .from('useritem_public_image')
          .select('useritem_id, useritem_image')
          .eq('item_id', itemId)
          .order('useritem_update', ascending: false)
          .limit(1);
      if (rows.isNotEmpty) {
        final url = rows.first['useritem_image'] as String?;
        if (url != null && url.isNotEmpty) {
          return {'useritem_id': rows.first['useritem_id'], 'url': url};
        }
      }
    } catch (_) {
      // フォールバック取得に失敗してもデフォルト画像表示に委ねる
    }
    return null;
  }
}
