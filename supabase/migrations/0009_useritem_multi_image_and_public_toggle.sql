-- ============================================================================
-- 1. Memoで最大3枚まで選べる画像のうち、2枚目・3枚目もSupabaseへ保存できる
--    ようにする（これまでuseritem_image列が1つしか無く、ログイン中ユーザーは
--    実質1枚目しか保存されていなかった）。
-- 2. 投稿（useritem）単位で公開/非公開を選べるようにする
--    （useritem_public、初期値true=自動公開。ユーザーが個別に非公開へ変更可能）。
--
-- 実行方法: Supabaseダッシュボード > SQL Editor に貼り付けて実行してください。
-- ============================================================================

alter table useritem
  add column if not exists useritem_image2 text,
  add column if not exists useritem_image3 text,
  add column if not exists useritem_public boolean not null default true;

-- 0008で作成したuseritem_public_imageビューを、2枚目・3枚目とuseritem_publicの
-- 条件を含む形に更新する。
create or replace view useritem_public_image as
select useritem_id, item_id, useritem_image, useritem_image2, useritem_image3,
       useritem_update
from useritem
where useritem_public = true
  and useritem_image like 'https://%';

grant select on useritem_public_image to anon, authenticated;
