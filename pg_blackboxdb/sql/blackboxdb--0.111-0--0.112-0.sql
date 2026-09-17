ALTER TABLE __API_CATALOG_SCHEMA__.collections ADD COLUMN IF NOT EXISTS options __CORE_SCHEMA__.bson DEFAULT NULL;

-- Revoke public execute on all functions, procedures and aggregates in blackboxdb_api_v2 schema
REVOKE EXECUTE ON ALL ROUTINES IN SCHEMA blackboxdb_api_v2 FROM PUBLIC;

-- Grant execute on readwrite routines to blackboxdb_readwrite_role
GRANT EXECUTE ON PROCEDURE blackboxdb_api_v2.create_indexes(text, blackboxdb_core.bson, blackboxdb_core.bson, boolean) TO blackboxdb_readwrite_role;
GRANT EXECUTE ON PROCEDURE blackboxdb_api_v2.drop_indexes(text, blackboxdb_core.bson, blackboxdb_core.bson) TO blackboxdb_readwrite_role;
GRANT EXECUTE ON PROCEDURE blackboxdb_api_v2.insert_bulk(text, blackboxdb_core.bson, blackboxdb_core.bsonsequence, text, blackboxdb_core.bson, boolean) TO blackboxdb_readwrite_role;
GRANT EXECUTE ON FUNCTION blackboxdb_api_v2.coll_stats(text, text, float8) TO blackboxdb_readwrite_role;
GRANT EXECUTE ON FUNCTION blackboxdb_api_v2.collection(text, text) TO blackboxdb_readwrite_role;
GRANT EXECUTE ON FUNCTION blackboxdb_api_v2.drop_collection(text, text, __CORE_SCHEMA_V2__.bson, uuid, bool) TO blackboxdb_readwrite_role;
GRANT EXECUTE ON FUNCTION blackboxdb_api_v2.rename_collection(text, text, text, boolean) TO blackboxdb_readwrite_role;
GRANT EXECUTE ON FUNCTION blackboxdb_api_v2.rename_collection(__CORE_SCHEMA_V2__.bson) TO blackboxdb_readwrite_role;

-- Grant execute on read-only routines to blackboxdb_readonly_role
GRANT EXECUTE ON FUNCTION blackboxdb_api_v2.aggregate_cursor_first_page(text, blackboxdb_core.bson, bigint) TO blackboxdb_readonly_role;
GRANT EXECUTE ON FUNCTION blackboxdb_api_v2.coll_stats(text, text, float8) TO blackboxdb_readonly_role;
GRANT EXECUTE ON FUNCTION blackboxdb_api_v2.collection(text, text) TO blackboxdb_readonly_role;
GRANT EXECUTE ON FUNCTION blackboxdb_api_v2.count_query(text, blackboxdb_core.bson) TO blackboxdb_readonly_role;
GRANT EXECUTE ON FUNCTION blackboxdb_api_v2.cursor_get_more(text, blackboxdb_core.bson, blackboxdb_core.bson) TO blackboxdb_readonly_role;
GRANT EXECUTE ON FUNCTION blackboxdb_api_v2.db_stats(text, double precision, boolean) TO blackboxdb_readonly_role;
GRANT EXECUTE ON FUNCTION blackboxdb_api_v2.distinct_query(text, blackboxdb_core.bson) TO blackboxdb_readonly_role;
GRANT EXECUTE ON FUNCTION blackboxdb_api_v2.find_cursor_first_page(text, blackboxdb_core.bson, bigint) TO blackboxdb_readonly_role;
GRANT EXECUTE ON FUNCTION blackboxdb_api_v2.list_collections_cursor_first_page(text, blackboxdb_core.bson, bigint) TO blackboxdb_readonly_role;
GRANT EXECUTE ON FUNCTION blackboxdb_api_v2.list_databases(blackboxdb_core.bson) TO blackboxdb_readonly_role;
GRANT EXECUTE ON FUNCTION blackboxdb_api_v2.list_indexes_cursor_first_page(text, blackboxdb_core.bson, bigint) TO blackboxdb_readonly_role;

-- Grant execute on admin-only routines to blackboxdb_admin_role
GRANT EXECUTE ON FUNCTION blackboxdb_api_v2.current_op_command(blackboxdb_core.bson) TO blackboxdb_admin_role;
GRANT EXECUTE ON FUNCTION blackboxdb_api_v2.drop_database(text, blackboxdb_core.bson) TO blackboxdb_admin_role;
GRANT EXECUTE ON FUNCTION blackboxdb_api_v2.validate(text, blackboxdb_core.bson) TO blackboxdb_admin_role;

#include "udfs/index_mgmt/drop_indexes--0.112-0.sql"
#include "udfs/commands_diagnostic/index_stats--0.112-0.sql"
