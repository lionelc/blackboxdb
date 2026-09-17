SET search_path TO blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog,blackboxdb_api_internal;
SET blackboxdb.next_collection_id TO 1100;
SET blackboxdb.next_collection_index_id TO 1100;

-- Test for Github issue #511
SELECT blackboxdb_api_catalog.bson_dollar_regex('{ "k": { "$regex": "^abc.*", "$options": "" } }', bson_build_document('k', '^abc.*'::text));
SELECT blackboxdb_api_catalog.bson_dollar_regex('{ "k": { "$regex": "^abc.*", "$options": "i" } }', bson_build_document('k', '^abc.*'::text));
