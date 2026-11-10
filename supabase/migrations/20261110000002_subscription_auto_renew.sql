-- Cancelling a subscription through Google Play only stops future charges.
-- The paid period must stay accessible until `expires_at`, so auto-renew is
-- tracked separately from the access flag.

alter table public.subscriptions
  add column if not exists is_auto_renew boolean not null default true;

comment on column public.subscriptions.is_auto_renew is
  'Whether Google Play will renew the subscription; false after a user cancels auto-renew but access remains until expires_at.';
