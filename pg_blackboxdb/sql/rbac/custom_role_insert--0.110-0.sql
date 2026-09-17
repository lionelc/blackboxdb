/*
 * Insert Privileged Action System Role
 * 
 * Supported Operations: insert, insert_bulk, insert_one
 */

DO
$do$
BEGIN
	IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'blackboxdb_api_insert_role') THEN
        CREATE ROLE blackboxdb_api_insert_role;
    END IF;
END
$do$;

GRANT USAGE ON SCHEMA __API_SCHEMA_INTERNAL__ TO blackboxdb_api_insert_role;
GRANT USAGE ON SCHEMA __API_SCHEMA_INTERNAL_V2__ TO blackboxdb_api_insert_role;

GRANT USAGE ON SCHEMA __API_CATALOG_SCHEMA_V2__ TO blackboxdb_api_insert_role;
GRANT USAGE ON SCHEMA __API_CATALOG_SCHEMA__ TO blackboxdb_api_insert_role;

GRANT USAGE ON SCHEMA blackboxdb_api_internal_readwrite TO blackboxdb_api_insert_role;
GRANT USAGE ON SCHEMA blackboxdb_api_internal_readonly TO blackboxdb_api_insert_role;

GRANT USAGE ON SCHEMA blackboxdb_api_v2 TO blackboxdb_api_insert_role;

GRANT USAGE ON SCHEMA __CORE_SCHEMA_V2__ TO blackboxdb_api_insert_role;

GRANT USAGE ON SCHEMA __API_DATA_SCHEMA__ TO blackboxdb_api_insert_role;

-- Grant execute on insert-related functions
GRANT EXECUTE ON FUNCTION blackboxdb_api_v2.insert(text, blackboxdb_core.bson, blackboxdb_core.bsonsequence, text) TO blackboxdb_api_insert_role;
GRANT EXECUTE ON PROCEDURE blackboxdb_api_v2.insert_bulk(text, blackboxdb_core.bson, blackboxdb_core.bsonsequence, text, blackboxdb_core.bson, boolean) TO blackboxdb_api_insert_role;
GRANT EXECUTE ON FUNCTION blackboxdb_api_v2.insert_one(text, text, blackboxdb_core.bson, text) TO blackboxdb_api_insert_role;