-- Billing support: per-contour Google Play product identifier and a unique
-- purchase token index used by the verify-purchase and google-play-webhook
-- Edge Functions.

alter table public.contours
  add column if not exists product_id text;

create unique index if not exists contours_product_id_key
  on public.contours (product_id)
  where product_id is not null;

create unique index if not exists subscriptions_purchase_token_key
  on public.subscriptions (purchase_token)
  where purchase_token is not null;
