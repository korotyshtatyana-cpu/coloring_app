-- Persist subscription purchases and automatic renewals.
--
-- A subscription keeps one row in `subscriptions` keyed by purchase token, so
-- renewals overwrite the previous expiry. The history screen needs to show the
-- billing period of every purchase and to mark periods renewed automatically,
-- which requires keeping one row per paid period.

alter table public.subscriptions
  add column if not exists base_plan_id text;

create table if not exists public.subscription_purchases (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users (id) on delete cascade,
  subscription_id uuid references public.subscriptions (id) on delete set null,
  purchase_token text not null,
  product_id text not null,
  plan_type text not null,
  base_plan_id text,
  order_id text,
  is_auto_renewal boolean not null default false,
  started_at timestamptz not null default now(),
  expires_at timestamptz,
  created_at timestamptz not null default now()
);

-- A renewal is identified by the token and the period it pays for. Google Play
-- can deliver the same notification more than once; the index keeps the
-- history idempotent.
create unique index if not exists subscription_purchases_token_expiry_key
  on public.subscription_purchases (purchase_token, expires_at);

create index if not exists subscription_purchases_user_id_idx
  on public.subscription_purchases (user_id, started_at desc);

alter table public.subscription_purchases enable row level security;

drop policy if exists "Users can read own subscription purchases"
  on public.subscription_purchases;
create policy "Users can read own subscription purchases"
  on public.subscription_purchases
  for select
  using (auth.uid() = user_id);

-- Backfill the currently known subscriptions so existing buyers keep an entry
-- in the history. The billing period of old rows is unknown and stays null.
insert into public.subscription_purchases (
  user_id,
  subscription_id,
  purchase_token,
  product_id,
  plan_type,
  base_plan_id,
  is_auto_renewal,
  started_at,
  expires_at
)
select
  s.user_id,
  s.id,
  s.purchase_token,
  s.product_id,
  s.plan_type,
  s.base_plan_id,
  false,
  coalesce(s.started_at, s.created_at, now()),
  s.expires_at
from public.subscriptions s
where s.purchase_token is not null
on conflict do nothing;
