/*
 * Find Privileged Action System Role
 * 
 * Supported Operations:  find, aggregate, count, distinct, cursor_get_more
 */

DO
$do$
BEGIN
	IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'blackboxdb_api_find_role') THEN
        CREATE ROLE blackboxdb_api_find_role;
    END IF;
END
$do$;

GRANT USAGE ON SCHEMA __API_SCHEMA_INTERNAL__ TO blackboxdb_api_find_role;
GRANT USAGE ON SCHEMA __API_SCHEMA_INTERNAL_V2__ TO blackboxdb_api_find_role;

GRANT USAGE ON SCHEMA __API_CATALOG_SCHEMA_V2__ TO blackboxdb_api_find_role;
GRANT USAGE ON SCHEMA __API_CATALOG_SCHEMA__ TO blackboxdb_api_find_role;

GRANT USAGE ON SCHEMA blackboxdb_api_internal_readonly TO blackboxdb_api_find_role;

GRANT USAGE ON SCHEMA blackboxdb_api_v2 TO blackboxdb_api_find_role;

GRANT USAGE ON SCHEMA __CORE_SCHEMA_V2__ TO blackboxdb_api_find_role;

GRANT USAGE ON SCHEMA __API_DATA_SCHEMA__ TO blackboxdb_api_find_role;

-- Grant execute on find-related functions
GRANT EXECUTE ON FUNCTION blackboxdb_api_v2.aggregate_cursor_first_page(text, blackboxdb_core.bson, bigint) TO blackboxdb_api_find_role;
GRANT EXECUTE ON FUNCTION blackboxdb_api_v2.count_query(text, blackboxdb_core.bson) TO blackboxdb_api_find_role;
GRANT EXECUTE ON FUNCTION blackboxdb_api_v2.cursor_get_more(text, blackboxdb_core.bson, blackboxdb_core.bson) TO blackboxdb_api_find_role;
GRANT EXECUTE ON FUNCTION blackboxdb_api_v2.distinct_query(text, blackboxdb_core.bson) TO blackboxdb_api_find_role;
GRANT EXECUTE ON FUNCTION blackboxdb_api_v2.find_cursor_first_page(text, blackboxdb_core.bson, bigint) TO blackboxdb_api_find_role;