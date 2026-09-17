
set search_path to blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog,pg_catalog;
SET citus.next_shard_id TO 514000;
SET blackboxdb.next_collection_id TO 5140;
SET blackboxdb.next_collection_index_id TO 5140;

SET client_min_messages=WARNING;
SELECT blackboxdb_api.drop_collection('db', 'simple_negation_tests_explain');
SELECT blackboxdb_api.create_collection('db', 'simple_negation_tests_explain');
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "simple_negation_tests_explain", "indexes": [{ "key": { "$**": 1 }, "name": "myIdx1" }] }'::blackboxdb_core.bson, true);

BEGIN;
SET local search_path to blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog,pg_catalog;
set local enable_seqscan to off;
set local blackboxdb.forceUseIndexIfAvailable to on;
\i sql/bson_dollar_operators_negation_tests_explain_core.sql
ROLLBACK;