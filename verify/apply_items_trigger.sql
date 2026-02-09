-- Verify joplin:apply_items_trigger on pg

BEGIN;

SELECT 1 FROM information_schema.triggers
WHERE trigger_name = 'items_changes_trigger'
  AND event_object_table = 'items';

ROLLBACK;
