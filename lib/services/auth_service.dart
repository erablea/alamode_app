import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alamode_app/main.dart';
import 'package:alamode_app/view/memo.dart'
    show CommonWidgets, PresentManagementService;

class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  User? get currentUser => supabase.auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  String? get userId => currentUser?.id;

  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  Future<void> signIn(String email, String password) async {
    await supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    await handleSignedIn();
  }

  Future<void> signUp(String email, String password, String userName) async {
    await supabase.auth.signUp(
      email: email.trim(),
      password: password,
    );
    // メール確認が必須の場合、signUp直後はセッションが無く(session == null)、
    // auth.uid()がnullになるためuserテーブルへの書き込みはRLSで弾かれる。
    // その場合はここでは何もせず、メール内リンクをクリックした際に
    // main.dartのauthStateChangesリスナー経由でhandleSignedIn()が呼ばれる。
    await handleSignedIn();
  }

  /// ログイン済み状態を検知した際に必ず呼ぶ処理。
  /// signIn()/signUp()からの呼び出しに加え、メール確認リンクや
  /// マジックリンクのクリックでセッションが確立した場合(main.dartの
  /// authStateChangesリスナー)にも呼ばれる。すべて冪等。
  Future<void> handleSignedIn() async {
    final user = currentUser;
    if (user == null) return;
    await _ensureUserRecord(user.id, user.email ?? '');
    await migrateLocalData();
    await migrateFavorites();
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await supabase.auth.resetPasswordForEmail(email.trim());
  }

  Future<void> _ensureUserRecord(String uid, String email) async {
    final existing = await supabase
        .from('user')
        .select('user_id')
        .eq('user_id', uid)
        .maybeSingle();
    if (existing == null) {
      await supabase.from('user').insert({
        'user_id': uid,
        'user_name': email,
        'user_createdate': DateTime.now().toIso8601String(),
        'user_update': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final uid = userId;
    if (uid == null) return null;
    return await supabase
        .from('user')
        .select('user_name, user_birthday, user_gender')
        .eq('user_id', uid)
        .maybeSingle();
  }

  Future<String?> getUserName() async {
    final profile = await getUserProfile();
    return profile?['user_name'] as String?;
  }

  Future<String> getOrCreateWho(String uid, String name) async {
    final existing = await supabase
        .from('who')
        .select('who_id')
        .eq('user_id', uid)
        .eq('who_name', name)
        .maybeSingle();
    if (existing != null) return existing['who_id'] as String;

    final result = await supabase.from('who').insert({
      'user_id': uid,
      'who_name': name,
      'who_createdate': DateTime.now().toIso8601String(),
      'who_update': DateTime.now().toIso8601String(),
    }).select('who_id').single();
    return result['who_id'] as String;
  }

  Future<void> migrateLocalData() async {
    final uid = userId;
    if (uid == null) return;

    final prefs = await SharedPreferences.getInstance();
    final migrated = prefs.getBool('data_migrated_$uid') ?? false;
    if (migrated) return;

    // どのpresent_idまで移行済みかを記録し、失敗した分だけ次回再試行できる
    // ようにする（_migratePresentItemは毎回insertするだけで重複チェックを
    // しないため、成功済みの項目まで再送すると重複登録になってしまう）。
    final migratedIdsKey = 'migrated_present_ids_$uid';
    final migratedIds = (prefs.getStringList(migratedIdsKey) ?? []).toSet();
    final presentList = prefs.getStringList('present_list') ?? [];
    var hadError = false;
    for (final item in presentList) {
      try {
        final data = Map<String, dynamic>.from(jsonDecode(item));
        final presentId = data['present_id'] as String?;
        if (presentId != null && migratedIds.contains(presentId)) continue;
        await _migratePresentItem(uid, data);
        if (presentId != null) migratedIds.add(presentId);
      } catch (_) {
        hadError = true;
      }
    }
    await prefs.setStringList(migratedIdsKey, migratedIds.toList());

    // 1件でも移行に失敗していたら「移行済み」フラグを立てず、次回ログイン時に
    // 再試行できるようにする（失敗分がサーバーに一切残らないまま消えるのを防ぐ）。
    if (!hadError) {
      await prefs.setBool('data_migrated_$uid', true);
    }
  }

  Future<void> _migratePresentItem(String uid, Map<String, dynamic> data) async {
    final whoName = data['present_who'] as String? ?? '';
    String? whoId;
    if (whoName.isNotEmpty) {
      whoId = await getOrCreateWho(uid, whoName);
    }

    final otherConditions = data['present_other_conditions'] as String? ?? '';
    final condStates = CommonWidgets.parseConditionString(otherConditions);
    String? condValue(String key) =>
        condStates[key] == 'unknown' ? null : condStates[key];

    // ゲスト時代は端末ローカル保存のキー文字列なので、ログインを機に
    // Supabase Storageへアップロードし直し、他ユーザーにも見える実URLにする。
    final presentService = PresentManagementService();
    Future<String?> migrateImage(String? key) =>
        key == null ? Future.value(null) : presentService.migrateLocalImageToStorage(key, uid);
    final imageUrl = await migrateImage(data['present_imageurl'] as String?);
    final imageUrl2 = await migrateImage(data['present_imageurl2'] as String?);
    final imageUrl3 = await migrateImage(data['present_imageurl3'] as String?);

    final useritemResult = await supabase.from('useritem').insert({
      'user_id': uid,
      'useritem_name': data['present_name'] ?? '',
      'useritem_brand': data['present_brand'] ?? '',
      'useritem_category': data['present_genre'] ?? '',
      'useritem_price': data['present_price'] ?? 0,
      'useritem_roomtemperature': condValue('常温'),
      'useritem_individualwrapping': condValue('個包装'),
      'useritem_online': condValue('オンライン購入'),
      'useritem_alcohol': condValue('洋酒'),
      'useritem_memo': data['present_memo'] ?? '',
      'useritem_URL': '',
      'useritem_image': imageUrl,
      'useritem_image2': imageUrl2,
      'useritem_image3': imageUrl3,
      'useritem_public': data['present_public'] ?? true,
      'useritem_createdate': data['present_createdate'] ?? DateTime.now().toIso8601String(),
      'useritem_update': DateTime.now().toIso8601String(),
    }).select('useritem_id').single();

    final useritemId = useritemResult['useritem_id'] as String;

    await supabase.from('event').insert({
      'user_id': uid,
      'useritem_id': useritemId,
      'event_how': data['present_type'] == 'received' ? 'treat' : 'present',
      'event_reaction_rating': data['present_reaction'] ?? 0,
      'event_taste_rating': 0,
      'event_memo': data['present_memo'] ?? '',
      'who_id': whoId,
      'event_date': data['present_date'] ?? DateTime.now().toIso8601String().substring(0, 10),
      'event_createdate': data['present_createdate'] ?? DateTime.now().toIso8601String(),
      'event_update': DateTime.now().toIso8601String(),
    });
  }

  Future<void> migrateFavorites() async {
    final uid = userId;
    if (uid == null) return;

    final prefs = await SharedPreferences.getInstance();
    final migrated = prefs.getBool('favorites_migrated_$uid') ?? false;
    if (migrated) return;

    final localFavorites = prefs.getStringList('favorite') ?? [];
    var hadError = false;
    for (final itemId in localFavorites) {
      try {
        await supabase.from('favorite').upsert(
          {'user_id': uid, 'item_id': itemId},
          onConflict: 'user_id,item_id',
        );
      } catch (_) {
        hadError = true;
      }
    }

    // upsertなので次回再試行しても重複しない。1件でも失敗していたら
    // フラグを立てず次回ログイン時に再試行する。
    if (!hadError) {
      await prefs.setBool('favorites_migrated_$uid', true);
    }
  }
}
