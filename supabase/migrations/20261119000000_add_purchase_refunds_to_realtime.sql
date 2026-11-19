-- Supabase Realtime only streams postgres_changes for tables that are part of
-- the `supabase_realtime` publication. The refund monitor subscribes to
-- inserts on public.purchase_refunds, so the table has to be published.
-- The guard keeps this migration safe when Realtime for all tables is already
-- enabled in the project settings.
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
     and not exists (
       select 1
       from pg_publication_tables
       where pubname = 'supabase_realtime'
         and schemaname = 'public'
         and tablename = 'purchase_refunds'
     ) then
    alter publication supabase_realtime add table public.purchase_refunds;
  end if;
end $$;
