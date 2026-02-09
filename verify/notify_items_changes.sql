-- Verify joplin:notify_items_changes on pg

BEGIN;

SELECT has_function_privilege('public.notify_items_changes()', 'execute');

ROLLBACK;
