-- Expand-and-Contract: contours get a multi-category array while the legacy
-- single-value `category` column stays in place for older clients.
--
-- Phase 1 (this migration): expand.
--   * add `categories`;
--   * backfill it from `category`;
--   * keep both columns in sync for legacy writers.
-- Phase 2 (future): contract, once every supported client reads `categories`.
--
-- `categories` is text[] rather than a Postgres enum array because the legacy
-- `category` column is text and production rows may contain values that are
-- not part of the current Dart enum (for example categories added on the
-- server). A hard cast to an enum would make this migration fail for those
-- rows; the app ignores unknown strings and still reads `category` as a
-- fallback.

alter table public.contours
  add column if not exists categories text[] not null default '{}';

-- Backfill only rows that were not populated yet, so re-running the migration
-- never overwrites a multi-category value.
update public.contours
set categories = array[category]
where category is not null
  and btrim(category) <> ''
  and coalesce(cardinality(categories), 0) = 0;

-- `.contains('categories', [category])` filtering uses the array containment
-- operator, which a GIN index accelerates.
create index if not exists contours_categories_gin_idx
  on public.contours using gin (categories);

-- Older clients only write `category`. Fill the new array on insert and on
-- updates that change the legacy column, without overwriting an existing
-- multi-category value written by a newer client.
create or replace function public.sync_contour_categories()
returns trigger
language plpgsql
as $$
begin
  if coalesce(cardinality(new.categories), 0) = 0
     and new.category is not null
     and btrim(new.category) <> '' then
    new.categories := array[new.category];
  end if;
  return new;
end;
$$;

drop trigger if exists contours_sync_categories on public.contours;

create trigger contours_sync_categories
  before insert or update of category on public.contours
  for each row execute function public.sync_contour_categories();
