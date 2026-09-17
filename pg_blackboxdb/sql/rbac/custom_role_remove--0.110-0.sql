/*
 * Remove Privileged Action System Role
 * 
 * Supported Operations: delete
 */

DO
$do$
BEGIN
	IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'blackboxdb_api_remove_role') THEN
        CREATE ROLE blackboxdb_api_remove_role;
    END IF;
END
$do$;

GRANT USAGE ON SCHEMA __API_SCHEMA_INTERNAL__ TO blackboxdb_api_remove_role;
GRANT USAGE ON SCHEMA __API_SCHEMA_INTERNAL_V2__ TO blackboxdb_api_remove_role;

GRANT USAGE ON SCHEMA __API_CATALOG_SCHEMA_V2__ TO blackboxdb_api_remove_role;
GRANT USAGE ON SCHEMA __API_CATALOG_SCHEMA__ TO blackboxdb_api_remove_role;

GRANT USAGE ON SCHEMA blackboxdb_api_internal_readwrite TO blackboxdb_api_remove_role;
GRANT USAGE ON SCHEMA blackboxdb_api_internal_readonly TO blackboxdb_api_remove_role;

GRANT USAGE ON SCHEMA blackboxdb_api_v2 TO blackboxdb_api_remove_role;

GRANT USAGE ON SCHEMA __CORE_SCHEMA_V2__ TO blackboxdb_api_remove_role;

GRANT USAGE ON SCHEMA __API_DATA_SCHEMA__ TO blackboxdb_api_remove_role;

-- Grant execute on delete-related functions
GRANT EXECUTE ON FUNCTION blackboxdb_api_v2.delete(text, blackboxdb_core.bson, blackboxdb_core.bsonsequence, text) TO blackboxdb_api_remove_role;
