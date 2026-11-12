
USE emergency_system;

DELIMITER //

DROP TRIGGER IF EXISTS trg_inventory_audit //

CREATE TRIGGER trg_inventory_audit
AFTER UPDATE ON blood_inventory
FOR EACH ROW
BEGIN
    IF OLD.available_units <> NEW.available_units
       OR OLD.reserved_units <> NEW.reserved_units THEN

        INSERT INTO inventory_audit (
            inventory_id,
            old_available,
            new_available,
            old_reserved,
            new_reserved
        )
        VALUES (
            OLD.inventory_id,
            OLD.available_units,
            NEW.available_units,
            OLD.reserved_units,
            NEW.reserved_units
        );

    END IF;
END //

DELIMITER ;
