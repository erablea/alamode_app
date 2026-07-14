-- ============================================================================
-- 訂正: 0001で誤って新規作成した favorites(複数形) テーブルではなく、
-- 元々CLAUDE.mdに設計されていた favorite(単数形) テーブルを使うよう訂正。
-- favorites(複数形)は既にダッシュボードから削除済みの前提。
--
-- 実行方法: Supabaseダッシュボード > SQL Editor に貼り付けて実行してください。
-- ============================================================================

-- 既存のfavoriteテーブルにRLSを有効化(既に有効でもエラーにならない)
alter table favorite enable row level security;

-- upsertのonConflict('user_id,item_id')に必要な一意制約
create unique index if not exists favorite_user_id_item_id_key
  on favorite (user_id, item_id);

create policy "favorite_select_own" on favorite
  for select using (auth.uid() = user_id);

create policy "favorite_insert_own" on favorite
  for insert with check (auth.uid() = user_id);

create policy "favorite_update_own" on favorite
  for update using (auth.uid() = user_id);

create policy "favorite_delete_own" on favorite
  for delete using (auth.uid() = user_id);
