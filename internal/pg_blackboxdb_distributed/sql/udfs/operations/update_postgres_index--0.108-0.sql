


CREATE OR REPLACE FUNCTION __API_DISTRIBUTED_SCHEMA__.update_postgres_index_worker(
    p_local_function_arg __CORE_SCHEMA_V2__.bson)
 RETURNS __CORE_SCHEMA_V2__.bson
 LANGUAGE C
AS 'MODULE_PATHNAME', $$blackboxdb_update_postgres_index_worker$$;