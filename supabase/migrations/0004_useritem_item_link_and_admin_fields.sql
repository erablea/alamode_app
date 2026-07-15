-- ============================================================================
-- useritem⇔item連携、ユーザー承認フラグ、item側の管理者専用フィールド、
-- home表示順のためのスキーマ変更
--
-- 実行方法: Supabaseダッシュボード > SQL Editor に貼り付けて実行してください。
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. useritem: ユーザーが「これは公式データと同じ」と確認したかのフラグ
--    null = 未回答, true = 確認した(公式itemに紐づけ確定), false = 違うと回答
--    ※useritem.item_id列は元々のCLAUDE.md記載のスキーマに既に存在する前提。
-- ----------------------------------------------------------------------------
alter table useritem
  add column if not exists useritem_approved boolean;

-- ----------------------------------------------------------------------------
-- 2. admin_appがuseritem.item_idを更新できるようにする(昇格時の紐づけ用)
--    useritem_approvedは既存の「本人のみ更新可」ポリシーで更新可能な想定。
-- ----------------------------------------------------------------------------
create policy "useritem_admin_update_item_id" on useritem
  for update using (
    exists (
      select 1 from "user" u
      where u.user_id = auth.uid() and u.is_admin
    )
  );

-- ----------------------------------------------------------------------------
-- 3. item: 管理者専用フィールド(alamode_appのUIには表示しない)
-- ----------------------------------------------------------------------------
alter table item
  add column if not exists license_status boolean,
  add column if not exists permission_date date,
  add column if not exists copyright text;

-- ----------------------------------------------------------------------------
-- 4. item: home画面での表示順(管理者app側で編集する)
-- ----------------------------------------------------------------------------
alter table item
  add column if not exists item_display_order integer;
