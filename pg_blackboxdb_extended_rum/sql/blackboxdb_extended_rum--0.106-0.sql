CREATE FUNCTION blackboxdb_extended_rumhandler(internal)
RETURNS index_am_handler
AS 'MODULE_PATHNAME'
LANGUAGE C;

/*
 * RUM access method
 */

CREATE SCHEMA blackboxdb_extended_rum_catalog;
CREATE ACCESS METHOD blackboxdb_extended_rum TYPE INDEX HANDLER blackboxdb_extended_rumhandler;

#include "pg_blackboxdb/sql/schema/single_path_operator_class--0.10-0.sql"
#include "pg_blackboxdb/sql/schema/composite_path_operator_class--0.103-0.sql"

-- register order by functions
ALTER OPERATOR FAMILY blackboxdb_extended_rum_catalog.bson_extended_rum_composite_path_ops USING blackboxdb_extended_rum ADD FUNCTION 8 (blackboxdb_core.bson)blackboxdb_api_internal.bson_rum_composite_ordering(bytea, blackboxdb_core.bson, int2, internal);
ALTER OPERATOR FAMILY blackboxdb_extended_rum_catalog.bson_extended_rum_composite_path_ops USING blackboxdb_extended_rum ADD OPERATOR 21 blackboxdb_api_catalog.|-<>(blackboxdb_core.bson, blackboxdb_core.bson) FOR ORDER BY blackboxdb_core.bson_btree_ops;

GRANT USAGE ON SCHEMA blackboxdb_extended_rum_catalog TO blackboxdb_admin_role;
GRANT USAGE ON SCHEMA blackboxdb_extended_rum_catalog TO blackboxdb_readonly_role;