
CREATE OR REPLACE FUNCTION __API_SCHEMA_INTERNAL_V2__.bson_get_rewritten_sql(
    p_collection_name text,
    p_spec __CORE_SCHEMA_V2__.bson)
RETURNS text
LANGUAGE C
VOLATILE PARALLEL UNSAFE STRICT
AS 'MODULE_PATHNAME', $function$command_bson_get_rewritten_sql$function$;
