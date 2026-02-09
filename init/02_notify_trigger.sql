-- Create notification function for items table changes
-- This function sends NOTIFY events whenever items are inserted, updated, or deleted
-- Excludes the large content field, sending only metadata

CREATE OR REPLACE FUNCTION public.notify_items_changes()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    payload JSON;
    data_obj JSON;
BEGIN
    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
        -- Build JSON object with metadata only (exclude large content field)
        data_obj = json_build_object(
            'id', NEW.id,
            'name', NEW.name,
            'mime_type', NEW.mime_type,
            'content_size', NEW.content_size,
            'jop_id', NEW.jop_id,
            'jop_parent_id', NEW.jop_parent_id,
            'jop_type', NEW.jop_type,
            'jop_encryption_applied', NEW.jop_encryption_applied,
            'jop_share_id', NEW.jop_share_id,
            'jop_updated_time', NEW.jop_updated_time,
            'owner_id', NEW.owner_id,
            'updated_time', NEW.updated_time,
            'created_time', NEW.created_time
        );

        payload = json_build_object(
            'operation', TG_OP,
            'id', NEW.id,
            'data', data_obj
        );
    ELSIF TG_OP = 'DELETE' THEN
        -- For DELETE, metadata only (exclude large content field)
        data_obj = json_build_object(
            'id', OLD.id,
            'name', OLD.name,
            'mime_type', OLD.mime_type,
            'content_size', OLD.content_size,
            'jop_id', OLD.jop_id,
            'jop_parent_id', OLD.jop_parent_id,
            'jop_type', OLD.jop_type,
            'jop_encryption_applied', OLD.jop_encryption_applied,
            'jop_share_id', OLD.jop_share_id,
            'jop_updated_time', OLD.jop_updated_time,
            'owner_id', OLD.owner_id,
            'updated_time', OLD.updated_time,
            'created_time', OLD.created_time
        );

        payload = json_build_object(
            'operation', 'DELETE',
            'id', OLD.id,
            'data', data_obj
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
$function$;

-- Note: The trigger itself must be created AFTER Joplin creates the items table
-- Run the apply_trigger.sql script after starting Joplin for the first time
