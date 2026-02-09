-- Apply the items_changes trigger to the items table
-- This script is safe to run during init - it will only create the trigger if the items table exists
-- Can be re-run manually after Joplin starts: docker compose exec -T db psql -U joplin -d joplin < init/03_apply_trigger.sql

DO $$
BEGIN
    -- Check if the items table exists
    IF EXISTS (
        SELECT FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_name = 'items'
    ) THEN
        -- Drop trigger if it already exists (for re-running)
        DROP TRIGGER IF EXISTS items_changes_trigger ON "items";

        -- Create the trigger on the items table
        CREATE TRIGGER items_changes_trigger
            AFTER INSERT OR UPDATE OR DELETE ON "items"
            FOR EACH ROW
            EXECUTE FUNCTION notify_items_changes();

        RAISE NOTICE 'Trigger "items_changes_trigger" created successfully on "items" table';

    ELSE
        RAISE NOTICE 'Items table does not exist yet - skipping trigger creation';
        RAISE NOTICE 'Run this script again after Joplin server has initialized';
    END IF;
END $$;

-- Verify the trigger was created (if table exists)
SELECT
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE trigger_name = 'items_changes_trigger';
