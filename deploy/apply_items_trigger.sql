-- Deploy joplin:apply_items_trigger to pg
-- requires: notify_items_changes

BEGIN;

DROP TRIGGER IF EXISTS items_changes_trigger ON "items";

CREATE TRIGGER items_changes_trigger
    AFTER INSERT OR UPDATE OR DELETE ON "items"
    FOR EACH ROW
    EXECUTE FUNCTION notify_items_changes();

COMMIT;
