-- Credit purchases: users buy a single credit from the store and spend it to
-- unlock one contour permanently.

alter table public.users
  add column if not exists credits integer not null default 0;

create table if not exists public.processed_purchases (
  purchase_token text primary key,
  user_id uuid not null references public.users (id) on delete cascade,
  product_id text not null,
  created_at timestamptz not null default now()
);

create index if not exists processed_purchases_user_id_idx
  on public.processed_purchases (user_id);

alter table public.processed_purchases enable row level security;

create unique index if not exists user_entitlements_user_id_contour_id_key
  on public.user_entitlements (user_id, contour_id);

create or replace function public.add_credits(
  p_user_id uuid,
  p_purchase_token text,
  p_product_id text
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_balance integer;
begin
  insert into public.processed_purchases (purchase_token, user_id, product_id)
  values (p_purchase_token, p_user_id, p_product_id)
  on conflict (purchase_token) do nothing;

  if found then
    update public.users
       set credits = coalesce(credits, 0) + 1
     where id = p_user_id;
  end if;

  select coalesce(credits, 0)
    into v_balance
    from public.users
   where id = p_user_id;

  if v_balance is null then
    raise exception 'user_not_found';
  end if;

  return v_balance;
end;
$$;

create or replace function public.spend_credit_and_unlock(
  p_user_id uuid,
  p_contour_id uuid,
  p_purchase_token text default null
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_balance integer;
begin
  if exists (
    select 1
      from public.user_entitlements
     where user_id = p_user_id
       and contour_id = p_contour_id
       and type = 'purchase'
       and (expires_at is null or expires_at > now())
  ) then
    select coalesce(credits, 0)
      into v_balance
      from public.users
     where id = p_user_id;

    return coalesce(v_balance, 0);
  end if;

  update public.users
     set credits = coalesce(credits, 0) - 1
   where id = p_user_id
     and coalesce(credits, 0) > 0
  returning credits into v_balance;

  if not found then
    raise exception 'insufficient_credits';
  end if;

  insert into public.user_entitlements (
    user_id,
    contour_id,
    type,
    granted_at,
    expires_at,
    purchase_token
  ) values (
    p_user_id,
    p_contour_id,
    'purchase',
    now(),
    null,
    p_purchase_token
  )
  on conflict (user_id, contour_id) do update
    set type = 'purchase',
        granted_at = now(),
        expires_at = null,
        purchase_token = coalesce(
          excluded.purchase_token,
          public.user_entitlements.purchase_token
        );

  return v_balance;
end;
$$;

revoke all on function public.add_credits(uuid, text, text) from public;
revoke all on function public.spend_credit_and_unlock(uuid, uuid, text)
  from public;
revoke all on function public.add_credits(uuid, text, text)
  from anon, authenticated;
revoke all on function public.spend_credit_and_unlock(uuid, uuid, text)
  from anon, authenticated;

grant execute on function public.add_credits(uuid, text, text)
  to service_role;
grant execute on function public.spend_credit_and_unlock(uuid, uuid, text)
  to service_role;
