-- Revert joplin:apply_items_trigger from pg

BEGIN;

DROP TRIGGER IF EXISTS items_changes_trigger ON "items";

COMMIT;
