import 'package:shared_preferences/shared_preferences.dart';
import 'package:alamode_app/main.dart';
import 'package:alamode_app/services/auth_service.dart';

/// お気に入りの読み書きを一元化するサービス。
/// ログイン中はSupabaseの`favorite`テーブル、未ログイン時は端末ローカル(SharedPreferences)を使う。
class FavoriteService {
  static final FavoriteService instance = FavoriteService._();
  FavoriteService._();

  Future<List<String>> getFavoriteIds() async {
    if (AuthService.instance.isLoggedIn) {
      final uid = AuthService.instance.userId!;
      final rows = await supabase.from('favorite').select('item_id').eq('user_id', uid);
      return rows.map((r) => r['item_id'].toString()).toList();
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('favorite') ?? [];
  }

  Future<bool> isFavorite(String itemId) async {
    final ids = await getFavoriteIds();
    return ids.contains(itemId);
  }

  Future<void> toggle(String itemId) async {
    if (AuthService.instance.isLoggedIn) {
      final uid = AuthService.instance.userId!;
      final existing = await supabase
          .from('favorite')
          .select('favorite_id')
          .eq('user_id', uid)
          .eq('item_id', itemId)
          .maybeSingle();
      if (existing != null) {
        await supabase
            .from('favorite')
            .delete()
            .eq('favorite_id', existing['favorite_id'])
            .eq('user_id', uid);
      } else {
        await supabase.from('favorite').insert({'user_id': uid, 'item_id': itemId});
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final favorite = prefs.getStringList('favorite') ?? [];
    if (favorite.contains(itemId)) {
      favorite.remove(itemId);
    } else {
      favorite.add(itemId);
    }
    await prefs.setStringList('favorite', favorite);
  }

  /// 参照先のitemが削除済みなど、無効になったお気に入りを取り除く
  Future<void> removeFavorites(List<String> itemIds) async {
    if (itemIds.isEmpty) return;
    if (AuthService.instance.isLoggedIn) {
      final uid = AuthService.instance.userId!;
      await supabase
          .from('favorite')
          .delete()
          .eq('user_id', uid)
          .inFilter('item_id', itemIds);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final favorite = prefs.getStringList('favorite') ?? [];
    favorite.removeWhere((id) => itemIds.contains(id));
    await prefs.setStringList('favorite', favorite);
  }
}
