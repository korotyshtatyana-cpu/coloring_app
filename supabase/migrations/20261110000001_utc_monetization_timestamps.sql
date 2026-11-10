-- Store monetization timestamps with an explicit timezone.
--
-- These tables used `timestamp without time zone` while every writer already
-- produced UTC. The ambiguous type made clients guess the zone and display
-- server time as if it were local. `timestamptz` stores one canonical moment;
-- the app converts it to the device timezone only when rendering.
--
-- Existing values were written in UTC, so interpret them as UTC during the
-- conversion.

alter table public.subscriptions
  alter column started_at type timestamptz using started_at at time zone 'UTC',
  alter column expires_at type timestamptz using expires_at at time zone 'UTC',
  alter column created_at type timestamptz using created_at at time zone 'UTC',
  alter column updated_at type timestamptz using updated_at at time zone 'UTC';

alter table public.pending_purchases
  alter column created_at type timestamptz using created_at at time zone 'UTC',
  alter column resolved_at type timestamptz using resolved_at at time zone 'UTC';

alter table public.user_entitlements
  alter column granted_at type timestamptz using granted_at at time zone 'UTC',
  alter column expires_at type timestamptz using expires_at at time zone 'UTC';
