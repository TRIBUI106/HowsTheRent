-- Hibernate auto-generates a CHECK constraint for every @Enumerated(EnumType.STRING) column the
-- first time ddl-auto creates its table, listing whatever enum constants existed at that moment.
-- spring.jpa.hibernate.ddl-auto=update never revisits an existing constraint when the Java enum
-- later gains a new value, so every one of these has been able to silently drift out of sync ever
-- since its table was first created.
--
-- Confirmed causing a real production incident: users_role_check did not include PLATFORM_ADMIN
-- (added to UserRole after the users table already existed — see V1's
-- "UPDATE users SET role = 'PLATFORM_ADMIN' WHERE role = 'ADMIN'"), so every attempt to create a
-- PLATFORM_ADMIN user failed at INSERT time with SQLSTATE 23514, surfacing to the client as a
-- bare, unhelpful 409/500 with no indication of which field or constraint was the problem.
--
-- Dropping these rather than re-adding an up-to-date version of each: @Enumerated(EnumType.STRING)
-- on a Java enum field is already airtight at the application layer — Hibernate can only ever
-- persist one of that enum's actual constants for a value written through JPA — so the DB-level
-- constraint is pure redundancy with no code path that benefits from it, at the cost of being able
-- to silently reintroduce this exact incident every time one of these enums gains a new value.

ALTER TABLE users                DROP CONSTRAINT IF EXISTS users_role_check;
ALTER TABLE audit_logs           DROP CONSTRAINT IF EXISTS audit_logs_action_check;
ALTER TABLE contracts            DROP CONSTRAINT IF EXISTS contracts_status_check;
ALTER TABLE fee_configs          DROP CONSTRAINT IF EXISTS fee_configs_water_mode_check;
ALTER TABLE invoices             DROP CONSTRAINT IF EXISTS invoices_status_check;
ALTER TABLE invoices             DROP CONSTRAINT IF EXISTS invoices_payment_method_check;
ALTER TABLE maintenance_notes    DROP CONSTRAINT IF EXISTS maintenance_notes_status_check;
ALTER TABLE maintenance_requests DROP CONSTRAINT IF EXISTS maintenance_requests_status_check;
ALTER TABLE maintenance_requests DROP CONSTRAINT IF EXISTS maintenance_requests_priority_check;
ALTER TABLE maintenance_requests DROP CONSTRAINT IF EXISTS maintenance_requests_category_check;
ALTER TABLE meter_readings       DROP CONSTRAINT IF EXISTS meter_readings_source_check;
ALTER TABLE rooms                DROP CONSTRAINT IF EXISTS rooms_status_check;
ALTER TABLE rooms                DROP CONSTRAINT IF EXISTS rooms_direction_check;
ALTER TABLE sla_rules            DROP CONSTRAINT IF EXISTS sla_rules_priority_check;
ALTER TABLE sla_rules            DROP CONSTRAINT IF EXISTS sla_rules_category_check;
