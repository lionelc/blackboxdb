GRANT USAGE ON SCHEMA blackboxdb_extended_rum_catalog TO blackboxdb_readwrite_role;
-- add the operators for the single path ops that match the regular index.
ALTER OPERATOR FAMILY blackboxdb_extended_rum_catalog.bson_extended_rum_single_path_ops USING blackboxdb_extended_rum
    ADD OPERATOR 25 blackboxdb_api_catalog.@<>(blackboxdb_core.bson, blackboxdb_core.bson),
    OPERATOR 26 blackboxdb_api_internal.@!>(blackboxdb_core.bson, blackboxdb_core.bson),
    OPERATOR 27 blackboxdb_api_internal.@!>=(blackboxdb_core.bson, blackboxdb_core.bson),
    OPERATOR 28 blackboxdb_api_internal.@!<(blackboxdb_core.bson, blackboxdb_core.bson),
    OPERATOR 29 blackboxdb_api_internal.@!<=(blackboxdb_core.bson, blackboxdb_core.bson);

#include "pg_blackboxdb/sql/schema/bson_hash_operator_class--0.23-0.sql"

ALTER OPERATOR FAMILY blackboxdb_extended_rum_catalog.bson_extended_rum_composite_path_ops USING blackboxdb_extended_rum
    ADD FUNCTION 6 (__CORE_SCHEMA__.bson) __API_SCHEMA_INTERNAL_V2__.gin_bson_composite_rum_config(internal);