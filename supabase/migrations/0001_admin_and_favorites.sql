-- ============================================================================
-- admin_app 導入 + お気に入りSupabase同期のためのスキーマ変更
--
-- 実行方法: Supabaseダッシュボード > SQL Editor に貼り付けて実行してください。
-- このリポジトリからは自動実行されません（このセッションからはネットワーク
-- ポリシーによりSupabaseへ直接接続できないため、手動実行が必要です）。
--
-- 前提: item.item_id / useritem.useritem_id が uuid 型であること。
-- もし実際の型が text や bigint の場合は、下記の型指定（uuid の部分）を
-- 実際の型に合わせて書き換えてから実行してください。
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. user テーブルに管理者フラグを追加
-- ----------------------------------------------------------------------------
alter table "user"
  add column if not exists is_admin boolean not null default false;

-- ----------------------------------------------------------------------------
-- 2. (訂正: このセクションは廃止)
--    ここでは新規に favorites(複数形) テーブルを作成していたが、
--    元々 favorite(単数形) テーブルが既に存在していたための誤り。
--    0002_use_existing_favorite_table.sql で訂正している。
--    favorites(複数形)テーブルは手動で削除済みの前提。
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- 3. useritem_review テーブル新規作成
--    admin_appの統合(昇格)作業の進捗管理専用。useritem自体には一切書き込まない。
-- ----------------------------------------------------------------------------
create table if not exists useritem_review (
  useritem_id uuid primary key references useritem (useritem_id) on delete cascade,
  reviewed_at timestamptz not null default now(),
  reviewed_by uuid references auth.users (id),
  promoted_item_id uuid references item (item_id)
);

alter table useritem_review enable row level security;

create policy "useritem_review_admin_all" on useritem_review
  for all using (
    exists (
      select 1 from "user" u
      where u.user_id = auth.uid() and u.is_admin
    )
  );

-- ----------------------------------------------------------------------------
-- 4. useritem テーブル: 管理者は全ユーザーの行を読めるようにする
--    （既存の「本人のみ」ポリシーはそのまま残し、これは追加のポリシー）
-- ----------------------------------------------------------------------------
create policy "useritem_admin_select_all" on useritem
  for select using (
    exists (
      select 1 from "user" u
      where u.user_id = auth.uid() and u.is_admin
    )
  );

-- ----------------------------------------------------------------------------
-- 5. item / brand テーブル: 書き込みは管理者のみに制限
--    ※ 既存のRLS状態が不明なため、まず現状のポリシーを確認してから
--       このセクションを実行してください（意図せず一般ユーザーの書き込みを
--       塞いでしまわないように）。読み取り(select)は誰でも可のまま維持します。
-- ----------------------------------------------------------------------------
create policy "item_admin_insert" on item
  for insert with check (
    exists (select 1 from "user" u where u.user_id = auth.uid() and u.is_admin)
  );

create policy "item_admin_update" on item
  for update using (
    exists (select 1 from "user" u where u.user_id = auth.uid() and u.is_admin)
  );

create policy "item_admin_delete" on item
  for delete using (
    exists (select 1 from "user" u where u.user_id = auth.uid() and u.is_admin)
  );

create policy "brand_admin_insert" on brand
  for insert with check (
    exists (select 1 from "user" u where u.user_id = auth.uid() and u.is_admin)
  );

create policy "brand_admin_update" on brand
  for update using (
    exists (select 1 from "user" u where u.user_id = auth.uid() and u.is_admin)
  );

create policy "brand_admin_delete" on brand
  for delete using (
    exists (select 1 from "user" u where u.user_id = auth.uid() and u.is_admin)
  );

-- ----------------------------------------------------------------------------
-- 6. 自分のアカウントを管理者にする
--    '<YOUR_ADMIN_EMAIL>' を実際のメールアドレスに書き換えてから実行してください。
-- ----------------------------------------------------------------------------
-- update "user"
--   set is_admin = true
--   where user_id = (
--     select id from auth.users where email = '<YOUR_ADMIN_EMAIL>'
--   );
