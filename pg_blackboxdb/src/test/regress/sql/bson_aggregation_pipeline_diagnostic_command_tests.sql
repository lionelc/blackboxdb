SET search_path TO blackboxdb_api,blackboxdb_core;

SET blackboxdb.next_collection_id TO 6600;
SET blackboxdb.next_collection_index_id TO 6600;

SELECT COUNT(*) FROM (SELECT blackboxdb_api.insert_one('diagnostic_db', 'diag_coll1', FORMAT('{ "_id": %s, "a": %s }', i, i)::blackboxdb_core.bson) FROM generate_series(1, 1000) i) innerQuery;
SELECT COUNT(*) FROM (SELECT blackboxdb_api.insert_one('diagnostic_db', 'diag_coll2', FORMAT('{ "_id": %s, "a": %s }', i, i)::blackboxdb_core.bson) FROM generate_series(1, 500) i) innerQuery;
SELECT COUNT(*) FROM (SELECT blackboxdb_api.insert_one('diagnostic_db', 'diag_coll3', FORMAT('{ "_id": %s, "a": %s }', i, i)::blackboxdb_core.bson) FROM generate_series(1, 100) i) innerQuery;

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('diagnostic_db', '{ "createIndexes": "diag_coll2", "indexes": [ { "key": { "a": 1 }, "name": "a_1" }]}', TRUE);

-- analyze for determinism
ANALYZE blackboxdb_data.documents_6601;
ANALYZE blackboxdb_data.documents_6602;
ANALYZE blackboxdb_data.documents_6603;

-- coll_stats should work
SELECT blackboxdb_api.coll_stats('diagnostic_db', 'diag_coll1');
SELECT blackboxdb_api.coll_stats('diagnostic_db', 'diag_coll2');
SELECT blackboxdb_api.coll_stats('diagnostic_db', 'diag_coll3');

-- db_stats should work
SELECT blackboxdb_api.db_stats('diagnostic_db');

-- coll_stats via aggregation should work.
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('diagnostic_db', '{ "aggregate": "diag_coll1", "pipeline": [ { "$collStats": { "storageStats": {} }}]}');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('diagnostic_db', '{ "aggregate": "diag_coll2", "pipeline": [ { "$collStats": { "storageStats": {} }}]}');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('diagnostic_db', '{ "aggregate": "diag_coll3", "pipeline": [ { "$collStats": { "storageStats": {} }}]}');

-- index_stats should work
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('diagnostic_db', '{ "aggregate": "diag_coll1", "pipeline": [ { "$indexStats": { }}, { "$project": { "accesses.since": 0 }}]}');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('diagnostic_db', '{ "aggregate": "diag_coll2", "pipeline": [ { "$indexStats": { }}, { "$project": { "accesses.since": 0 }}]}');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('diagnostic_db', '{ "aggregate": "diag_coll3", "pipeline": [ { "$indexStats": { }}, { "$project": { "accesses.since": 0 }}]}');