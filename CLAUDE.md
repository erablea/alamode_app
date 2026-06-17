# alamode_app — Claude向けプロジェクト情報

## 技術スタック
- Flutter (Web, Chrome) — `flutter run -d chrome`
- Supabase (バックエンド・DB)
- SharedPreferences (ローカルストレージ)
- フォント: PinyonScript, PlayfairDisplay, ZenMaruGothic, Corinthia

## Gitブランチ
- 作業ブランチ: `claude/stoic-newton-hds27h`
- mainブランチには直接pushしない

## Supabaseテーブル構造

### `item` テーブル（お菓子）
| カラム名 | 型 | 説明 |
|---|---|---|
| `item_id` | PK | 主キー ※`id`ではない |
| `brand_id` | FK | brandテーブルへの外部キー ※`item_brandid`ではない |
| `item_name` | text | 商品名 |
| `item_category` | text | ジャンル（カンマ区切り）※`brand_genre`ではない |
| `item_price` | int | 価格 |
| `item_roomtemperature` | bool/int | 常温可 |
| `item_individualwrapping` | bool/int | 個包装可 |
| `item_online` | bool/int | オンライン購入可 |
| `item_expirydate` | int | 賞味期限（日数）|
| `item_url` | text | 外部URL ※`item_URL`ではない |
| `item_imageurl1` | text | 画像URL1 |
| `item_imageurl2` | text | 画像URL2 |
| `item_imageurl3` | text | 画像URL3 |
| `item_description` | text | 商品説明 |
| `item_createdate` | timestamp | 作成日 |
| `item_update` | timestamp | 更新日 |

**注意**: `id`、`item_brandid`、`brand_genre`、`item_URL`、`item_rating` はitemテーブルに存在しない。

### `brand` テーブル（ブランド）
| カラム名 | 型 | 説明 |
|---|---|---|
| `id` | PK | 主キー（brandはidを使う）|
| `brand_name` | text | ブランド名 |
| `brand_genre` | text | ブランドのジャンル |
| `brand_description` | text | ブランド説明 |

brandテーブルのデータはitem.brand_idで結合。itemテーブルのqueryでは返ってこないので、別途 `.from('brand').select().eq('id', brandId)` で取得する。

## ローカルストレージ (SharedPreferences) のキー
| キー | 型 | 内容 |
|---|---|---|
| `favorite` | StringList | お気に入りitem_idの一覧 |
| `present_list` | StringList | Memoタブの記録（JSONエンコード）|
| `memo_show_sent` | bool | Memoタブの最後に選択していたタブ（贈った/貰った）|

## Memoタブのデータ構造（SharedPreferences内）
Memoタブの記録はSupabaseではなくSharedPreferencesに保存される（ローカルのみ）。
各レコードのキー: `present_id`, `present_createdate`, `item_name`, `brand_name`（ブランド・会社名）, `who`（贈った相手/貰ってくれた人）, `present_date`, `present_reaction`, `present_memo`, `is_sent`（贈った=true/貰った=false）

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
- brandの外部キーは `brand_id`（`item_brandid`ではない）
- ジャンルはitemテーブルの `item_category`（`brand_genre`ではない）
- brandの名前・ジャンルはbrandテーブルを別途クエリして取得
- Supabase Realtimeの`.stream()`は使わず`.select()`+FutureBuilderを使う
- Flutter webでhot reload（r）ではフォントが反映されないことがある → フルリスタート（R）が必要
- `flutter clean && flutter pub get && flutter run -d chrome` でクリーンビルド
