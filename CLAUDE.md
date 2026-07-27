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

### `inquiry` テーブル（お問い合わせ、`0007_inquiry_table.sql`）
| カラム名 | 内容 |
|---|---|
| `inquiry_id` | お問い合わせID (PK) |
| `user_id` | ユーザーID (FK→auth.users, nullable。未ログインでも送信可) |
| `inquiry_type` | `error_report` / `bug_report` / `other` / `business` / `account_deletion` |
| `inquiry_name` | お名前（error_report/bug_reportはnull）|
| `inquiry_email` | メールアドレス（error_report/bug_reportはnull）|
| `inquiry_company` | 会社名（businessのみ）|
| `inquiry_content` | お問い合わせ内容 |
| `inquiry_createdate` | データ作成日時 |

**重要**: insertのみ許可（`with check (true)`）、selectポリシーは一切無い。送信者自身を含めクライアントからは読み返せない設計にしている（お問い合わせ内容が他ユーザーへ漏れる経路自体を無くすため）。管理者はSupabaseダッシュボード（サービスロール）から直接確認する。

## ローカルストレージ (SharedPreferences) のキー
※現在の実装はSupabaseのfavoriteテーブルを使わずSharedPreferencesで管理している（暫定）

| キー | 型 | 内容 |
|---|---|---|
| `favorite` | StringList | お気に入りitem_idの一覧 |
| `present_list` | StringList | Memoタブの記録（JSONエンコード）|
| `memo_show_sent` | bool | Memoタブの最後のタブ状態（贈った/貰った）|
| `pending_sync_presents` | StringList | ログイン中ユーザーがオフライン等でSupabase保存・更新・削除に失敗した際の再送信待ちキュー（JSONエンコード、`_op`が`create`/`update`/`delete`）。保存・更新・削除・一覧取得のたびに自動フラッシュされる |
| `presents_cache_$uid` | String(JSON) | ログイン中ユーザーの最後に取得成功したMemo一覧のキャッシュ（オフライン時のフォールバック表示用）|
| `home_items_cache` / `home_items_cache_fetched_at` | String(JSON) / int(ms) | Homeの商品一覧の最後に取得成功した結果とその取得時刻（オフライン時のフォールバック表示用）|
| `favorite_items_cache` | String(JSON) | お気に入り登録商品の最後に取得成功した商品データのキャッシュ（オフライン時のフォールバック表示用）|

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

## 文字数・数値の上限（管理者向け情報。アプリ内UIには一切表示しない）
入力欄にはそれぞれ`maxLength`（`MaxLengthEnforcement.enforced`でハード制限）または金額・日数の上限バリデーションを設定している。制限値を変更する際は、下表と実装（`Constants`クラスや各フォームのバリデータ）の両方を必ず同期させること。

### alamode_app（`lib/view/memo.dart` / `lib/view/user.dart`）
| 画面・欄 | 上限 | 実装場所 |
|---|---|---|
| お菓子の名前（present_name） | 40文字 | `Constants.nameMaxLength` |
| ブランド・会社名（present_brand） | 30文字 | `Constants.brandMaxLength` |
| 相手の名前（who） | 30文字 | `Constants.brandMaxLength`（共用）|
| 金額（present_price） | ¥9,999,999 | `Constants.maxPrice` |
| メモ（present_memo） | 200文字 | `Constants.memoMaxLength` |
| プロフィール名（MyPageScreen） | 30文字 | `user.dart`内リテラル |
| お問い合わせ：お名前 | 30文字 | `user.dart`内リテラル |
| お問い合わせ：メールアドレス | 100文字 | `user.dart`内リテラル |
| お問い合わせ：お問い合わせ内容／正しい内容／不具合の内容 | 500文字 | `user.dart`内リテラル |
| 企業向け問い合わせ：会社名／ご担当者名 | 30文字 | `user.dart`内リテラル |
| 企業向け問い合わせ：メールアドレス | 100文字 | `user.dart`内リテラル |
| 企業向け問い合わせ：お問い合わせ内容 | 500文字 | `user.dart`内リテラル |

### admin_app（`lib/view/item/item_form_screen.dart` / `lib/view/brand/brand_form_screen.dart` / `lib/widgets/common_widgets.dart`）
| 画面・欄 | 上限 | 実装場所 |
|---|---|---|
| 商品名（item_name） | 40文字 | `item_form_screen.dart`内リテラル |
| ブランド・会社名（Autocomplete入力欄） | 30文字 | `item_form_screen.dart`内リテラル |
| 価格（税抜／税込10%） | ¥9,999,999 | `item_form_screen.dart`内バリデータ |
| 賞味期限（item_expirydate） | 999日 | `item_form_screen.dart`内バリデータ |
| 商品説明（item_description） | 300文字 | `item_form_screen.dart`内リテラル |
| コピーライト表記（item_copyright） | 150文字 | `item_form_screen.dart`内リテラル |
| ブランド名（brand_name） | 30文字 | `brand_form_screen.dart`内リテラル |
| 会社名（brand_company） | 30文字 | `brand_form_screen.dart`内リテラル |
| 公式サイトURL系（`UrlInputField`共通ウィジェット、brand/item両方で使用） | 500文字 | `common_widgets.dart`の`UrlInputField` |

## オフライン時のデータ保護・キャッシュ表示

### Memoタブ（`PresentManagementService`, `lib/view/memo.dart`）
- ログイン中ユーザーがMemoの新規保存・更新・削除を行おうとした際にSupabaseへの通信が失敗した場合、それぞれ例外を投げる代わりに`pending_sync_presents`（SharedPreferences、`_op`が`create`/`update`/`delete`のJSONエントリ）へキューイングし、`true`（オフライン保留）を返す。データは消えない。
- 未同期の`create`エントリ自体をオフライン中に再度編集・削除しようとした場合（サーバーにまだ行が存在しないためupdate/delete APIが使えない）は、`_mutatePendingCreate()`がキュー内のcreateエントリ自体を書き換える・取り除くことで対応する。
- キューは「保存・更新・削除時」「一覧取得時」など通信の機会があるたびに`syncPendingPresents()`で自動フラッシュを試みる（`connectivity_plus`等の追加パッケージには依存しない、日和見的な同期）。
- 一覧取得（`_getAllPresentsFromSupabase`）では、未同期の`delete`対象は結果から除外し、未同期の`update`内容は該当行に上書き反映してから表示する（オフライン中の編集・削除がすぐに一覧へ反映されるようにするため）。取得自体がオフライン等で失敗した場合は、直近成功時にキャッシュした`presents_cache_$uid`を表示にフォールバックする（何も出ない状態を避けるため）。
- 保留中のMemo（未同期の新規登録・自分自身がキューに残っている更新後データ）はカードのヘッダーに雲に斜線のアイコン（オフライン保存中）で示される。

### Home / Favoriteタブ（`lib/view/home.dart` / `lib/view/favorite.dart`）
- Homeの商品一覧（`_ItemListState._getFilteredQuery`）は取得成功のたびに`home_items_cache`（SharedPreferences）へ結果を保存し、取得失敗時はそのキャッシュを現在の並び替え条件で並び替え直してフォールバック表示する。フォールバック中は一覧上部に「最終取得: M/d HH:mm」を添えた小さな注意バナーを表示する。
- Favoriteタブも同様に、favorite登録商品の取得成功時に`favorite_items_cache`へ保存し、失敗時は現在お気に入り登録されているIDに絞ってキャッシュから表示する。
- どちらもキャッシュが無い場合（初回起動でオフラインなど）は素直にエラー表示のままとする（無理にダミーデータを出さない）。

### ログイン・新規登録・お問い合わせ（`lib/view/auth.dart` / `lib/view/user.dart`）
- `_parseError()`（auth.dart）・`_submitInquiry()`（user.dart）双方に`_isNetworkError()`判定を実装し、通信エラー（`SocketException`/`Failed to fetch`/`ClientException`/`TimeoutException`等を含む場合）は「ネットワークに接続できません。通信環境をご確認のうえ、もう一度お試しください。」という明確な案内を表示する。
- お問い合わせフォームは以前`mailto:`リンクでメールアプリを起動する方式だったが、`inquiry`テーブルへ直接insertする方式に変更した（メールアプリが無い環境でも送信できるようにするため）。

## セキュリティ・プライバシー（他ユーザーの情報が漏れないための対策）

### クライアント側の多重防御（RLSに加えて、アプリ自身も他人の行を操作できないようにする）
以下は本来Supabase側のRLS（Row Level Security）で保証されるべきだが、RLSの設定不備があった場合の保険として、Dartコード側でも明示的に`user_id`で絞り込んでいる。
- `memo.dart`の`_updatePresentInSupabase`/`_deletePresentFromSupabase`/`_respondToApproval`: `useritem`/`event`のupdate・deleteに`.eq('user_id', uid)`を必ず付与。
- `favorite_service.dart`の`toggle()`: `favorite`のdeleteに`.eq('user_id', uid)`を必ず付与。

### `useritem_approved_image`ビュー（`item_image_service.dart`が使用）
- itemに画像が無い商品のフォールバックとして、他ユーザーが登録したuseritemの画像（本人が承認済みのもの）を表示する機能がある。これは意図的に他ユーザーの`useritem`データを一部参照する唯一の箇所。
- `useritem`テーブルには非公開のメモ・価格・ブランド名等も含まれるため、テーブルを直接クロスユーザーでselectする実装は絶対に避け、公開してよい列（`item_id`/`useritem_image`/`useritem_update`）だけに絞った専用ビュー経由でのみアクセスする（`0007_inquiry_table.sql`内で定義）。

### RLS現状（2026年に`pg_policies`で確認済み）
`user`/`who`/`useritem`/`event`/`favorite`はいずれも`《table》_own`という名前の`FOR ALL USING (auth.uid() = user_id)`ポリシー1本で保護されている。`with_check`列がnullでも問題ない: PostgreSQLの仕様上、ALL/UPDATE/INSERTポリシーで`WITH CHECK`を明示しない場合は`USING`句がそのまま`WITH CHECK`としても使われるため、insert/updateも実質的に「本人の`user_id`のみ」に制限されている。
`useritem`には上記に加えて管理者用の`useritem_admin_select_all`（SELECT）・`useritem_admin_update_item_id`（UPDATE、いずれも`is_admin`ユーザーのみ）が追加されているが、一般ユーザーの権限を広げるものではない。
このため、`item_image_service.dart`が以前直接`useritem`テーブルをクロスユーザーでselectしていた実装は、実際には**このRLSに阻まれて他ユーザーの承認済み画像を一件も取得できていなかった**（漏洩ではなく機能不全）。`useritem_approved_image`ビュー（postgresオーナー権限で実行されRLSの対象外）に切り替えたことで、意図通り機能するようになった。
`inquiry`は`inquiry_insert_anyone`（INSERT, with_check=true）のみで、select系ポリシーが無いことも確認済み。

### その他、把握しているリスクと対応状況
- **共有端末での残留データ**: 未ログイン（ゲスト）状態のMemo・お気に入りはブラウザのSharedPreferences（localStorage相当）にそのまま保存される。ログアウトしても自動では消えない（そもそもゲストデータはログイン状態と紐付いていないため）。共有PCで複数人が同じブラウザを使う場合、前の利用者のゲストデータが残る可能性がある。これは一般的なWebアプリのlocalStorageの性質上の制約であり、「新しい利用者」を検知する手段が無いため今回は対応していない。気になる場合は共有端末の利用者に「利用後はブラウザのデータを消去する」よう案内するのが現実的。
- **画像はクロスデバイス同期されない**: 画像は実際にはSupabase Storage等にアップロードされておらず、ブラウザのSharedPreferences内にBase64で保存され、そのローカルキー文字列だけが`useritem_image`としてサーバーに保存されている。そのため別端末・別ブラウザからは同じ画像が見えない（漏洩ではなく、逆に「見えなさすぎる」機能不足）。将来的に画像を本当に共有・同期したい場合はSupabase Storageへの実アップロードに変更する必要がある。
- **`user_name`のデフォルト値がメールアドレス**: 新規登録直後、プロフィール名を編集するまでは`user.user_name`にメールアドレスがそのまま入る（`auth_service.dart`の`_ensureUserRecord`）。この値は本人のMyPageScreen以外には一切表示されないコードになっているため現状漏洩経路は無いが、`user`テーブルのRLSが正しく本人限定になっていることが前提となる（上記の要確認事項を参照）。
- **admin_app側のRLS**: item/brand/useritemへの管理者権限（is_admin）による書き込み・全件参照は`admin_app`側の関心事のため今回のセッションでは対象外。ただしalamode_app側の`useritem`テーブルに対する管理者向けポリシー（`useritem_admin_select_all`等、`0001_admin_and_favorites.sql`）と、今回追加した`useritem_approved_image`ビューは独立しているため、互いに干渉しない。

## リリース前対応状況

### アカウント削除（`user.dart`の`MyPageScreen._deleteAccount()`）
- クライアントからは`event`/`useritem`/`who`/`favorite`/`user`の本人の行をRLS(own-row)の範囲でその場で削除し、ローカルの関連SharedPreferencesキー（`data_migrated_$uid`等、`pending_sync_presents`）も削除する。
- `auth.users`（ログイン用の認証情報自体）の削除はサービスロールが必要でクライアントからはできないため、削除実行前に`inquiry`テーブルへ`inquiry_type: 'account_deletion'`で依頼を記録し、運営者がSupabaseダッシュボードから手動で認証ユーザーを削除する運用とする。
- そのため、運営側が認証情報を削除するまでの間に同じメールアドレス・パスワードで再ログインした場合、データが無い状態で利用が再開される点をユーザーに確認ダイアログ内で明示している。

### テスト・静的解析
- `analysis_options.yaml`が存在しておらず、`flutter_lints`（pubspecに記載済み）が実質有効になっていなかった（`flutter analyze`は常にDartデフォルトの最小ルールのみで実行されていた）ため追加した。有効化後に新たに顕在化した60件はほぼ`info`レベルのスタイル系（`prefer_const_constructors`/`library_private_types_in_public_api`等）と`use_build_context_synchronously`（非同期処理を挟んだ後のBuildContext使用、`mounted`チェックの徹底を推奨）で、緊急の修正は不要だが今後まとめて手を入れる価値がある。
- `home.dart`に残っていた本番用途外の`print()`4箇所は`homeLogger`（loggingパッケージ）経由に変更。`logging`パッケージはこれまで推移的依存に頼っていたため`pubspec.yaml`に直接依存として追加した。
- `test/`ディレクトリを新設し、ロジックが独立している箇所（`Utils.formatCurrency`/`normalizeString`/`generateUniqueId`、`AdUtils`の広告差し込みインデックス計算、`CommonWidgets`の条件文字列パース/組み立て）の単体テストを追加（`flutter test`で16件全て通過）。Supabase等の外部通信を伴う箇所は今回のテスト対象に含めていない。

### エラーの可視化
- `main.dart`で`Logger.root`にリスナーを設定していなかったため、`presentLogger`等の`.warning()`呼び出しがこれまでコンソールにすら出力されていなかった。`Logger.root.onRecord.listen(...)`を追加し、あわせて`FlutterError.onError`/`PlatformDispatcher.instance.onError`で捕捉されない例外もログに残すようにした。外部のクラッシュ収集サービス（Sentry等）は未導入。導入する場合はこのリスナー内から送信を追加すればよい。

### 広告（AdMob不可・AdSense前提の下地のみ）
- 本アプリはFlutter Web専用のため、モバイル専用SDKのGoogle Mobile Ads(AdMob)は利用できない。Web版で実際に広告を表示するにはGoogle AdSenseの審査通過（サイトが実際に公開されている必要がある）が必要なため、このセッションでは実際の広告配信は実装していない。
- `web/index.html`にAdSenseスクリプトタグの雛形をコメントアウトで用意した。審査通過後、コメントを外してpublisher IDに置き換え、ドメイン直下に`ads.txt`を追加し、`lib/main.dart`の`AdUtils.buildAdBanner()`（現状ダミー枠）を実際の広告枠に差し替える必要がある。

### `inquiry`テーブルのスパム対策（未実装・提案のみ）
`inquiry_insert_anyone`は未ログインでも誰でもinsertできる設計のため、荒らし投稿のリスクがある。対策候補（優先度順）:
1. クライアント側の簡易クールダウン（例: 前回送信から一定時間は送信ボタンを無効化）とハニーポット項目（人には見えない隠しフィールドを用意し、値が入っていたら送信を握りつぶす）。実装コストが低く、簡単なボットには有効。
2. Supabaseのトリガー/関数でIPアドレスや時間帯あたりの件数を制限する（Edge Functionが必要になる可能性が高い）。
3. reCAPTCHA等のCAPTCHA導入（外部サービスの登録が必要）。
実際に荒らしが発生してから1を追加するのが費用対効果として妥当と考えられる。
