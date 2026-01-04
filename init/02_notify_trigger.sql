-- Create notification function for items table changes
-- This function sends NOTIFY events whenever items are inserted, updated, or deleted

CREATE OR REPLACE FUNCTION notify_items_changes()
    RETURNS TRIGGER AS $$
DECLARE
    payload JSON;
BEGIN
    IF TG_OP = 'INSERT' THEN
        payload = json_build_object(
            'operation', 'INSERT',
            'id', NEW.id,
            'data', row_to_json(NEW)
        );
    ELSIF TG_OP = 'UPDATE' THEN
        payload = json_build_object(
            'operation', 'UPDATE',
            'id', NEW.id,
            'data', row_to_json(NEW)
        );
    ELSIF TG_OP = 'DELETE' THEN
        payload = json_build_object(
            'operation', 'DELETE',
            'id', OLD.id,
            'data', row_to_json(OLD)
        );
    END IF;

    PERFORM pg_notify('items_changes', payload::text);

    -- Return appropriate value based on operation
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Note: The trigger itself must be created AFTER Joplin creates the items table
-- Run the apply_trigger.sql script after starting Joplin for the first time
