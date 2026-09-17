
SET search_path TO blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog,blackboxdb_api_internal;
SET citus.next_shard_id TO 380000;
SET blackboxdb.next_collection_id TO 3800;
SET blackboxdb.next_collection_index_id TO 3800;


set enable_seqscan TO off;
set blackboxdb.forceUseIndexIfAvailable to on;
set blackboxdb.forceDisableSeqScan to on;

SELECT blackboxdb_api.drop_collection('array_query_db', 'array_operator_tests') IS NOT NULL;
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('array_query_db', '{ "createIndexes": "array_operator_tests", "indexes": [ { "key": { "value": 1 }, "enableCompositeTerm": true, "name": "queryoperator_value" }, { "key": { "value.subfield": 1 }, "enableCompositeTerm": true, "name": "queryoperator_value_subfield" }] }', true) IS NOT NULL;

\i sql/bson_query_operator_array_tests_core.sql