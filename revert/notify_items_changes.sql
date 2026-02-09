-- Revert joplin:notify_items_changes from pg

BEGIN;

DROP FUNCTION IF EXISTS public.notify_items_changes();

COMMIT;
