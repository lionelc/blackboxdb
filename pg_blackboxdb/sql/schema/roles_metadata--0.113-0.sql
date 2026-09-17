-- Add role table grants and schema USAGE WITH GRANT OPTION for the root role,
-- so it can manage custom roles via createRole/dropRole.
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'blackboxdb_admin_role') THEN
        EXECUTE 'GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE blackboxdb_api_catalog.roles TO blackboxdb_admin_role';
        EXECUTE 'GRANT USAGE ON SCHEMA blackboxdb_api_catalog, blackboxdb_core, blackboxdb_data, blackboxdb_api, blackboxdb_api_internal TO blackboxdb_admin_role WITH GRANT OPTION';
    END IF;
END $$;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'blackboxdb_admin_role') THEN
        EXECUTE 'GRANT USAGE ON SCHEMA blackboxdb_api_internal_readonly TO blackboxdb_admin_role WITH GRANT OPTION';
    END IF;
END $$;
