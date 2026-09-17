SET search_path TO blackboxdb_api,blackboxdb_api_catalog;

SET blackboxdb.next_collection_id TO 782000;
SET blackboxdb.next_collection_index_id TO 782000;

CREATE SCHEMA cache_schema;

CREATE OR REPLACE FUNCTION cache_schema.validate_collection_cache(
    p_database_name text,
    p_collection_name text)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS 'pg_blackboxdb', $function$validate_collection_cache_entry$function$;

SELECT blackboxdb_api.create_collection('db', 'cache_test_collection');

-- SET options here, any new option included in the collection should be added here.
SET blackboxdb.enablePreImages to on;
SELECT blackboxdb_api.coll_mod('db', 'cache_test_collection','{"collMod": "cache_test_collection", "changeStreamPreAndPostImages": { "enabled": true }}'::blackboxdb_core.bson);

SELECT options FROM blackboxdb_api_catalog.collections WHERE collection_name = 'cache_test_collection';

SELECT cache_schema.validate_collection_cache('db', 'cache_test_collection');