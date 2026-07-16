-- ============================================================================
-- 洋酒条件をuseritem/item両方に追加
--
-- 実行方法: Supabaseダッシュボード > SQL Editor に貼り付けて実行してください。
-- ============================================================================

alter table useritem
  add column if not exists useritem_alcohol text;

alter table item
  add column if not exists item_alcohol boolean;
