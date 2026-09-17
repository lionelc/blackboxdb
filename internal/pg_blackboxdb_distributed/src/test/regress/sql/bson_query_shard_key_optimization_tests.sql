SET search_path TO blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog,blackboxdb_api_internal;
SET citus.next_shard_id TO 170000;
SET blackboxdb.next_collection_id TO 1700;
SET blackboxdb.next_collection_index_id TO 1700;

SELECT blackboxdb_api.drop_collection('db', 'shardkeyopt') IS NOT NULL;
SELECT blackboxdb_api.create_collection('db', 'shardkeyopt');


-- create an index on a.b
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', blackboxdb_distributed_test_helpers.generate_create_index_arg('shardkeyopt', 'a_b_1', '{"a.b": 1}'), true);


BEGIN;
-- avoid sequential scan (likely to be preferred on small tables)
set local enable_seqscan TO off;
set local blackboxdb.forceUseIndexIfAvailable to on;

EXPLAIN (COSTS OFF) SELECT object_id, document FROM blackboxdb_api.collection('db', 'shardkeyopt') WHERE document @@ '{ "a.b": { "$eq" : 1 }}';
EXPLAIN (COSTS OFF) SELECT object_id, document FROM blackboxdb_api.collection('db', 'shardkeyopt') WHERE document @@ '{ "a.b": { "$ne" : 1 }}';

EXPLAIN (COSTS OFF) SELECT object_id, document FROM blackboxdb_api.collection('db', 'shardkeyopt') WHERE document @@ '{ "a.b": { "$ne" : 1 }, "_id": { "$gt": { "$minKey": 1 } }}';
EXPLAIN (COSTS OFF) SELECT object_id, document FROM blackboxdb_api.collection('db', 'shardkeyopt') WHERE document @@ '{ "_id": { "$gt": { "$minKey": 1 } }}';
ROLLBACK;

-- shard the collection
SELECT blackboxdb_api.shard_collection('db', 'shardkeyopt', '{ "c": "hashed" }', false);


BEGIN;
-- avoid sequential scan (likely to be preferred on small tables)
set local enable_seqscan TO off;
set local blackboxdb.forceUseIndexIfAvailable to on;

EXPLAIN (COSTS OFF) SELECT object_id, document FROM blackboxdb_api.collection('db', 'shardkeyopt') WHERE document @@ '{ "a.b": { "$eq" : 1 }}';
EXPLAIN (COSTS OFF) SELECT object_id, document FROM blackboxdb_api.collection('db', 'shardkeyopt') WHERE document @@ '{ "a.b": { "$ne" : 1 }}';
EXPLAIN (COSTS OFF) SELECT object_id, document FROM blackboxdb_api.collection('db', 'shardkeyopt') WHERE document @@ '{ "a.b": { "$ne" : 1 }, "_id": { "$gt": { "$minKey": 1 } }}';
EXPLAIN (COSTS OFF) SELECT object_id, document FROM blackboxdb_api.collection('db', 'shardkeyopt') WHERE document @@ '{ "_id": { "$gt": { "$minKey": 1 } }}';

EXPLAIN (COSTS OFF) SELECT object_id, document FROM blackboxdb_api.collection('db', 'shardkeyopt') WHERE document @@ '{ "a.b": { "$eq" : 1 }, "c": 2 }';
EXPLAIN (COSTS OFF) SELECT object_id, document FROM blackboxdb_api.collection('db', 'shardkeyopt') WHERE document @@ '{ "a.b": { "$ne" : 1 }, "c": 2 }';
EXPLAIN (COSTS OFF) SELECT object_id, document FROM blackboxdb_api.collection('db', 'shardkeyopt') WHERE document @@ '{ "a.b": { "$ne" : 1 }, "c": 2, "_id": { "$gt": { "$minKey": 1 } }}';
EXPLAIN (COSTS OFF) SELECT object_id, document FROM blackboxdb_api.collection('db', 'shardkeyopt') WHERE document @@ '{ "c": 2, "_id": { "$gt": { "$minKey": 1 } }}';
ROLLBACK;
