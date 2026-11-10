-- Refund notifications shown to the user after a store purchase is refunded.
--
-- The Google Play webhook records a row when a voided purchase notification
-- arrives. The client reads unacknowledged rows, shows the refund message and
-- marks the row as acknowledged, so the user learns that the purchase is no
-- longer valid instead of silently losing access.

create table if not exists public.purchase_refunds (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users (id) on delete cascade,
  purchase_token text not null unique,
  product_id text not null,
  created_at timestamptz not null default now(),
  acknowledged_at timestamptz
);

create index if not exists purchase_refunds_user_id_idx
  on public.purchase_refunds (user_id, acknowledged_at);

alter table public.purchase_refunds enable row level security;

drop policy if exists "Users can read own purchase refunds"
  on public.purchase_refunds;
create policy "Users can read own purchase refunds"
  on public.purchase_refunds
  for select
  using (auth.uid() = user_id);

drop policy if exists "Users can acknowledge own purchase refunds"
  on public.purchase_refunds;
create policy "Users can acknowledge own purchase refunds"
  on public.purchase_refunds
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
