-- 既存のitem_price（税込10%価格）をitem_price10percentへリネームし、
-- item_priceは税抜価格（本体価格）として新規作成する。
-- 税抜価格を基準に持つことで、将来消費税率が変わってもitem_price10percentを
-- 再計算するだけで対応できるようにする。
alter table item rename column item_price to item_price10percent;
alter table item add column if not exists item_price numeric;

-- 数量・期間限定かどうか
alter table item add column if not exists item_limited boolean;

-- 実店舗での取り扱いがあるかどうか
alter table item add column if not exists item_physicalstore boolean;

-- home画面に表示するかどうか（管理者が個別に非表示にできる）。
-- 既存データは全てtrueとして扱う。
alter table item add column if not exists item_show_on_home boolean not null default true;
