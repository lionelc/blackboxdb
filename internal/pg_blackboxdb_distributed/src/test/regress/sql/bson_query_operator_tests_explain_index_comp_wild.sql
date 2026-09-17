SET search_path TO blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog,blackboxdb_api_internal;
SET citus.next_shard_id TO 1100000;
SET blackboxdb.next_collection_id TO 1100;
SET blackboxdb.next_collection_index_id TO 1100;

set blackboxdb.enableExtendedExplainPlans to on;

SELECT blackboxdb_api.drop_collection('db', 'queryoperator') IS NOT NULL;
SELECT blackboxdb_api.create_collection('db', 'queryoperator');

SELECT blackboxdb_api.drop_collection('db', 'queryoperatorIn') IS NOT NULL;
SELECT blackboxdb_api.create_collection('db', 'queryoperatorIn');

SELECT blackboxdb_api.drop_collection('db', 'nullfield') IS NOT NULL;
SELECT blackboxdb_api.create_collection('db', 'nullfield');

SELECT blackboxdb_api.drop_collection('db', 'singlepathindexexists') IS NOT NULL;
SELECT blackboxdb_api.create_collection('db', 'singlepathindexexists');

-- create a composite index
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "queryoperator", "indexes": [ { "key": { "a.$**": 1 }, "enableCompositeTerm": true, "name": "queryoperator_a" }] }', true);
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "queryoperator", "indexes": [ { "key": { "b.$**": 1 }, "enableCompositeTerm": true, "name": "queryoperator_b" }] }', true);
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "queryoperator", "indexes": [ { "key": { "c.$**": 1 }, "enableCompositeTerm": true, "name": "queryoperator_c" }] }', true);

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "nullfield", "indexes": [ { "key": { "$**": 1 }, "enableCompositeTerm": true, "name": "nullfield_root" }] }', true);
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "queryoperatorIn", "indexes": [ { "key": { "$**": 1 }, "enableCompositeTerm": true, "name": "queryoperatorin_root" }] }', true);

-- create single path index
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "singlepathindexexists", "indexes": [ { "key": { "a": 1 }, "enableCompositeTerm": true, "name": "a_index" }] }', true);

-- show the indexes
\d blackboxdb_data.documents_1100

BEGIN;
SET LOCAL citus.enable_local_execution TO OFF;
set local blackboxdb.useLocalExecutionShardQueries to off;
-- avoid sequential scan (likely to be preferred on small tables)
set local enable_seqscan TO off;
set local blackboxdb.forceUseIndexIfAvailable to on;
set local blackboxdb.enableExtendedExplainPlans to on;

\i sql/bson_query_operator_tests_explain_core.sql
COMMIT;
