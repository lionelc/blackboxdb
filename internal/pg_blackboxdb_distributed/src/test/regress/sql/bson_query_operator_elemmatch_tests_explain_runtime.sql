
SET search_path TO blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog,blackboxdb_api_internal;
SET citus.next_shard_id TO 720000;
SET blackboxdb.next_collection_id TO 7200;
SET blackboxdb.next_collection_index_id TO 7200;

SELECT blackboxdb_api.drop_collection('db', 'elemmatchtest') IS NOT NULL;
SELECT blackboxdb_api.create_collection('db', 'elemmatchtest') IS NOT NULL;


-- avoid plans that use the primary key index
SELECT blackboxdb_distributed_test_helpers.drop_primary_key('db','elemmatchtest');

BEGIN;
set local enable_seqscan TO on;
set local citus.enable_local_execution TO OFF;
set local blackboxdb.useLocalExecutionShardQueries to off;
\i sql/bson_query_operator_elemmatch_tests_explain_core.sql
ROLLBACK;

-- Shard the collection and run an explain analyze
SELECT blackboxdb_api.shard_collection('db','elemmatchtest', '{"_id":"hashed"}', false);

BEGIN;
set local enable_seqscan TO on;
SELECT blackboxdb_distributed_test_helpers.mask_plan_id_from_distributed_subplan($Q$
EXPLAIN (COSTS OFF) SELECT object_id, document FROM blackboxdb_api.collection('db', 'elemmatchtest') where document @@ '{"a.b" : { "$elemMatch": {"$gte" : 10, "$lte" : 15} }}';
$Q$);

SELECT blackboxdb_distributed_test_helpers.mask_plan_id_from_distributed_subplan($Q$
EXPLAIN (COSTS OFF) SELECT object_id, document FROM blackboxdb_api.collection('db', 'elemmatchtest') where document @@ '{"a" : { "$elemMatch": { "$or": [{ "b": {"$gte": 1} }, { "b": { "$lt": 2 }}] } } }';
$Q$);
ROLLBACK;
