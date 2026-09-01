-- ============================================================================
-- ユーザーが投稿した写真をSupabase Storageに保存し、他ユーザーにも
-- （食べログのように）公開できるようにするための変更。
-- これまでは端末ローカル保存（SharedPreferencesのBase64／ローカルファイル
-- パス）のキー文字列をuseritem_imageに入れていたため、本人の端末以外
-- では画像が表示できなかった。
--
-- 公開の仕組み: 投稿時点で自動的に公開（承認フロー無し）。
-- 不適切な画像への対応は、通報ボタン→inquiryテーブルへの記録→
-- 運営者が手動でuseritem_imageを削除、という運用にする。
--
-- 実行方法: Supabaseダッシュボード > SQL Editor に貼り付けて実行してください。
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Storageバケット作成（公開読み取り可）
-- ----------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('useritem-images', 'useritem-images', true)
on conflict (id) do nothing;

-- ----------------------------------------------------------------------------
-- 2. Storageオブジェクトのポリシー
--    パスは "{user_id}/{ファイル名}" 形式で保存する想定。
--    本人のフォルダ配下にのみ書き込み・削除でき、読み取りは誰でも可能。
-- ----------------------------------------------------------------------------
create policy "useritem_images_insert_own" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'useritem-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "useritem_images_update_own" on storage.objects
  for update to authenticated
  using (
    bucket_id = 'useritem-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "useritem_images_delete_own" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'useritem-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "useritem_images_public_read" on storage.objects
  for select to public
  using (bucket_id = 'useritem-images');

-- ----------------------------------------------------------------------------
-- 3. 公開閲覧用ビュー
--    0007で作ったuseritem_approved_imageは「管理者確認済み」限定だったが、
--    今回は投稿時点で自動公開する方針のため、useritem_approvedに依存しない
--    新しいビューを用意する（useritem_approved_imageは別目的
--    ＝公式itemとの紐づけ確認用なのでそのまま残す）。
--    Storageアップロード後のURLのみを対象とする(https)ため、旧来の
--    端末ローカル保存キー文字列が誤って公開されることはない。
-- ----------------------------------------------------------------------------
create or replace view useritem_public_image as
select useritem_id, item_id, useritem_image, useritem_update
from useritem
where useritem_image like 'https://%';

grant select on useritem_public_image to anon, authenticated;

-- ----------------------------------------------------------------------------
-- 4. inquiry_typeに'photo_report'を追加（スキーマ変更は不要、テキスト列のため）
--    通報時は inquiry_content に対象のuseritem_id/item_idと理由を記録する。
-- ----------------------------------------------------------------------------
comment on column inquiry.inquiry_type is
  'error_report | bug_report | other | business | account_deletion | photo_report';
