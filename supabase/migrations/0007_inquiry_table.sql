-- ============================================================================
-- お問い合わせフォームをmailto:（メールアプリ起動）方式から、アプリ内から
-- 直接送信できる方式に変更するためのテーブル追加。
--
-- 実行方法: Supabaseダッシュボード > SQL Editor に貼り付けて実行してください。
-- ============================================================================

create table if not exists inquiry (
  inquiry_id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users (id),
  inquiry_type text not null, -- 'error_report' | 'bug_report' | 'other' | 'business'
  inquiry_name text,
  inquiry_email text,
  inquiry_company text,
  inquiry_content text not null,
  inquiry_createdate timestamptz not null default now()
);

alter table inquiry enable row level security;

-- 送信(insert)のみ誰でも可能。selectを一切許可しないため、送信者本人を含め
-- クライアントからは他人はもちろん自分の送信内容も読み返せない
-- （＝お問い合わせ内容が他ユーザーへ漏れる経路が存在しない）。
-- 管理者はSupabaseダッシュボード（サービスロール）から直接確認する運用とする。
create policy "inquiry_insert_anyone" on inquiry
  for insert with check (true);

-- ============================================================================
-- useritem_approved_image ビュー
--
-- 目的: item側にまだ画像が無い商品のフォールバック表示として、他ユーザーが
-- 登録したuseritemの画像を「本人が確認・承認済み(useritem_approved = true)」
-- に限定して閲覧できるようにしたい（item_image_service.dartの既存機能）。
-- ただしuseritemテーブルにはメモ・価格・ブランド名など非公開の個人データも
-- 含まれるため、テーブル自体を全ユーザーに公開する形にしてはならない。
-- そこで公開してよい列(item_id / useritem_image / useritem_update)だけを
-- 切り出したビューを用意し、クライアントはこのビュー経由でのみアクセスする。
-- ビューは作成者(postgres)権限で実行されるため、useritemテーブル自体の
-- RLS設定の如何に関わらず、ここで絞った列・行だけが見える。
-- ============================================================================

create or replace view useritem_approved_image as
select item_id, useritem_image, useritem_update
from useritem
where useritem_approved = true
  and useritem_image is not null;

grant select on useritem_approved_image to anon, authenticated;
