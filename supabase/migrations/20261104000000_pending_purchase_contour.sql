-- Link a queued purchase to the contour it unlocks.
--
-- Pending purchases were stored without the contour they belong to, so the
-- gallery could not tell the user that the project was already being paid for
-- and offered the same purchase again. The column also lets a restored
-- transaction recover the contour it was originally started for.
alter table public.pending_purchases
  add column if not exists contour_id uuid references public.contours(id) on delete set null;
