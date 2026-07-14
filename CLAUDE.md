# alamode_app — Claude向けプロジェクト情報

## 技術スタック
- Flutter (Web, Chrome) — 起動は常に `flutter clean && flutter pub get && flutter run -d chrome`
- Supabase (バックエンド・DB)
- SharedPreferences (ローカルストレージ)
- フォント: PinyonScript, PlayfairDisplay, ZenMaruGothic, Corinthia

## Gitブランチ
- `main`に直接pushしてよい（公開中のアプリではないため、一時的にビルドが壊れても問題ない）
- `main`へのpushで`.github/workflows/deploy.yml`が自動実行されGitHub Pagesにデプロイされる点は認識しておくこと

## Supabaseテーブル構造

### `user` テーブル
| カラム名 | 内容 |
|---|---|
| `user_id` | ユーザーID (PK) |
| `user_name` | ユーザー名 |
| `user_birthday` | 生年月日 |
| `user_gender` | 性別 |
| `user_createdate` | データ作成日時 |
| `user_update` | データ更新日時 |

### `item` テーブル（確度の高い商品情報）
| カラム名 | 内容 |
|---|---|
| `item_id` | 商品ID (PK) ※`id`ではない |
| `brand_id` | ブランドID (FK→brand) ※`item_brandid`ではない |
| `item_name` | 商品名 |
| `item_category` | カテゴリー ※`brand_genre`ではない |
| `item_price` | 価格（税込） |
| `item_roomtemperature` | 常温可 (yes/no) |
| `item_individualwrapping` | 個包装可 (yes/no) |
| `item_expirydate` | 賞味期限（日数）|
| `item_online` | オンライン購入可 (yes/no) |
| `item_URL` | 商品URL ※DBでは`item_url`(小文字)で返ってくる |
| `item_imageurl1` | 画像URL1 |
| `item_imageurl2` | 画像URL2 |
| `item_imageurl3` | 画像URL3 |
| `item_description` | 商品説明 |
| `item_createdate` | データ作成日時 |
| `item_update` | データ更新日時 |

### `brand` テーブル
| カラム名 | 内容 |
|---|---|
| `brand_id` | ブランドID (PK) ※`id`ではない |
| `brand_name` | ブランド名 |
| `brand_company` | 会社名 |
| `brand_createdate` | データ作成日時 |
| `brand_update` | データ更新日時 |

**注意**: brandテーブルに`brand_genre`は存在しない。ジャンルはitemテーブルの`item_category`を使う。

### `useritem` テーブル（ユーザーが入力した商品情報）
| カラム名 | 内容 |
|---|---|
| `useritem_id` | ユーザー商品ID (PK) |
| `user_id` | ユーザーID (FK→user) |
| `useritem_name` | ユーザー商品名 |
| `useritem_brand` | ユーザーブランド |
| `useritem_company` | ユーザー会社名 |
| `useritem_category` | ユーザーカテゴリー |
| `useritem_price` | 価格（税込） |
| `useritem_roomtemperature` | 常温可 (yes/no) |
| `useritem_individualwrapping` | 個包装可 (yes/no) |
| `useritem_expirydate` | 賞味期限（日数）|
| `useritem_online` | オンライン購入可 (yes/no) |
| `useritem_memo` | 商品メモ |
| `useritem_URL` | 商品URL |
| `useritem_image` | ユーザー写真 |
| `item_id` | 商品ID (FK→item, nullable) |
| `useritem_createdate` | データ作成日時 |
| `useritem_update` | データ更新日時 |

### `event` テーブル（贈った/もらった記録）
| カラム名 | 内容 |
|---|---|
| `event_id` | イベントID (PK) |
| `user_id` | ユーザーID (FK→user) |
| `useritem_id` | ユーザー商品ID (FK→useritem) |
| `event_how` | present=贈った / treat=もらった |
| `event_reaction_rating` | 相手の反応（★1〜5）|
| `event_taste_rating` | 自己評価（★1〜5）|
| `event_memo` | メモ |
| `who_id` | 相手 (FK→who) |
| `event_date` | イベント日付 |
| `event_createdate` | データ作成日時 |
| `event_update` | データ更新日時 |

### `who` テーブル（人物）
| カラム名 | 内容 |
|---|---|
| `who_id` | 人物ID (PK) |
| `user_id` | ユーザーID (FK→who) |
| `who_name` | 人物名 |
| `who_birthday` | 生年月日 |
| `who_gender` | 性別 |
| `who_createdate` | データ作成日時 |
| `who_update` | データ更新日時 |

### `favorite` テーブル（お気に入り）
| カラム名 | 内容 |
|---|---|
| `favorite_id` | お気に入りID (PK) |
| `user_id` | ユーザーID (FK→user) |
| `item_id` | 商品ID (FK→item) |
| `favorite_createdate` | データ作成日時 |
| `favorite_update` | データ更新日時 |

## ローカルストレージ (SharedPreferences) のキー
※現在の実装はSupabaseのfavoriteテーブルを使わずSharedPreferencesで管理している（暫定）

| キー | 型 | 内容 |
|---|---|---|
| `favorite` | StringList | お気に入りitem_idの一覧 |
| `present_list` | StringList | Memoタブの記録（JSONエンコード）|
| `memo_show_sent` | bool | Memoタブの最後のタブ状態（贈った/貰った）|

## ファイル構成
```
lib/
  main.dart         # AppColors, テーマ, MainApp(フッター), buildStarRating, AdUtils
  view/
    home.dart       # Searchタブ, ItemCard, ItemDetailScreen, HomeFilterDialog
    favorite.dart   # Favタブ
    memo.dart       # Memoタブ（旧present.dart）
    user.dart       # Settingタブ
  widgets/
    header.dart     # ヘッダー（PinyonScriptで "a la mode"）
```

## よくあるミス・注意事項
- itemテーブルのPKは `item_id`（`id`ではない）
- brandテーブルのPKは `brand_id`（`id`ではない）
- brandの外部キーは `brand_id`（`item_brandid`ではない）
- ジャンルはitemテーブルの `item_category`（`brand_genre`ではない）
- brandテーブルに`brand_genre`は存在しない
- Supabase Realtimeの`.stream()`は使わず`.select()`+FutureBuilderを使う
- Flutter webでhot reload（r）ではフォントが反映されないことがある → フルリスタート（R）
- `flutter clean && flutter pub get && flutter run -d chrome` でクリーンビルド
