SET search_path TO blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog,pg_catalog;

SET citus.next_shard_id TO 19850000;
SET blackboxdb.next_collection_id TO 19850;
SET blackboxdb.next_collection_index_id TO 19850;

-- =============================================================================
-- Test 1: Sharded $first/$last with collation
-- Exercises combine function (send/recv) path across shards with collation.
-- =============================================================================

-- Setup and shard data
SELECT blackboxdb_api.insert_one('db', 'fl_collation_test', '{ "_id": 1, "g": "A", "name": "cherry" }');
SELECT blackboxdb_api.insert_one('db', 'fl_collation_test', '{ "_id": 2, "g": "A", "name": "BANANA" }');
SELECT blackboxdb_api.insert_one('db', 'fl_collation_test', '{ "_id": 3, "g": "A", "name": "Apple" }');
SELECT blackboxdb_api.insert_one('db', 'fl_collation_test', '{ "_id": 4, "g": "a", "name": "date" }');
SELECT blackboxdb_api.insert_one('db', 'fl_collation_test', '{ "_id": 5, "g": "a", "name": "FIG" }');
SELECT blackboxdb_api.insert_one('db', 'fl_collation_test', '{ "_id": 6, "g": "B", "name": "grape" }');
SELECT blackboxdb_api.insert_one('db', 'fl_collation_test', '{ "_id": 7, "g": "B", "name": "KIWI" }');

SELECT blackboxdb_api.shard_collection('db', 'fl_collation_test', '{ "_id": "hashed" }', false);

SET blackboxdb_core.enableCollation TO on;
SET blackboxdb.enableCollationWithNewGroupAccumulators TO on;

-- 1a. GUC ON: collation-sensitive $first/$last after sharding
SET blackboxdb.enableNewWithExprAccumulators TO on;

set citus.propagate_set_commands to 'local';
BEGIN;
set local citus.max_adaptive_executor_pool_size to 1;
set local citus.enable_local_execution to off;

-- With collation (case-insensitive strength 1): "cherry" eq "CHERRY" → matched
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "fl_collation_test", "pipeline": [{ "$group": { "_id": "$g", "firstMatch": { "$first": { "$cond": { "if": { "$eq": ["$name", "CHERRY"] }, "then": "matched", "else": "no-match" } } }, "lastMatch": { "$last": { "$cond": { "if": { "$eq": ["$name", "CHERRY"] }, "then": "matched", "else": "no-match" } } } } }, { "$sort": { "_id": 1 } }], "cursor": {}, "collation": { "locale": "en", "strength": 1 } }');

-- Without collation baseline (binary: "cherry" != "CHERRY")
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "fl_collation_test", "pipeline": [{ "$group": { "_id": "$g", "firstMatch": { "$first": { "$cond": { "if": { "$eq": ["$name", "CHERRY"] }, "then": "matched", "else": "no-match" } } }, "lastMatch": { "$last": { "$cond": { "if": { "$eq": ["$name", "CHERRY"] }, "then": "matched", "else": "no-match" } } } } }, { "$sort": { "_id": 1 } }], "cursor": {} }');

-- Simple field reference with collation
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "fl_collation_test", "pipeline": [{ "$group": { "_id": "$g", "firstName": { "$first": "$name" }, "lastName": { "$last": "$name" } } }, { "$sort": { "_id": 1 } }], "cursor": {}, "collation": { "locale": "en", "strength": 1 } }');

-- Constant _id group with collation-sensitive expression
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "fl_collation_test", "pipeline": [{ "$group": { "_id": null, "firstMatch": { "$first": { "$cond": { "if": { "$eq": ["$name", "CHERRY"] }, "then": "matched", "else": "no-match" } } }, "lastMatch": { "$last": { "$cond": { "if": { "$eq": ["$name", "CHERRY"] }, "then": "matched", "else": "no-match" } } } } }], "cursor": {}, "collation": { "locale": "en", "strength": 1 } }');

ROLLBACK;

-- 1b. GUC OFF: collation with old accumulators → error
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SET blackboxdb.enableCollationWithNewGroupAccumulators TO off;

SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "fl_collation_test", "pipeline": [{ "$group": { "_id": "$g", "f": { "$first": "$name" }, "l": { "$last": "$name" } } }, { "$sort": { "_id": 1 } }], "cursor": {}, "collation": { "locale": "en", "strength": 1 } }');

SET blackboxdb.enableCollationWithNewGroupAccumulators TO off;
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SET blackboxdb_core.enableCollation TO off;

-- =============================================================================
-- Test 2: Sharded $first/$last where every document in the group has a missing
-- field. With hashed _id sharding the docs land on different shards, so the
-- EOD (missing) value must survive the send/recv/combine path and come back
-- as null in the final result.
-- =============================================================================

SELECT blackboxdb_api.insert_one('db', 'fl_missing_test', '{ "_id": 1, "category": "electronics" }');
SELECT blackboxdb_api.insert_one('db', 'fl_missing_test', '{ "_id": 2, "category": "electronics" }');

SELECT blackboxdb_api.shard_collection('db', 'fl_missing_test', '{ "_id": "hashed" }', false);

-- 2a. GUC ON: $first and $last on missing nested field
SET blackboxdb.enableNewWithExprAccumulators TO on;

set citus.propagate_set_commands to 'local';
BEGIN;
set local citus.max_adaptive_executor_pool_size to 1;
set local citus.enable_local_execution to off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "fl_missing_test", "pipeline": [{ "$group": { "_id": "$category", "firstResult": { "$first": "$profile.email" }, "lastResult": { "$last": "$profile.email" } } }], "cursor": {} }');
ROLLBACK;

-- 2b. GUC OFF: $first and $last on missing nested field
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;

set citus.propagate_set_commands to 'local';
BEGIN;
set local citus.max_adaptive_executor_pool_size to 1;
set local citus.enable_local_execution to off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "fl_missing_test", "pipeline": [{ "$group": { "_id": "$category", "firstResult": { "$first": "$profile.email" }, "lastResult": { "$last": "$profile.email" } } }], "cursor": {} }');
ROLLBACK;

SELECT blackboxdb_api.drop_collection('db', 'fl_missing_test');

-- =============================================================================
-- Test 3: Sharded $setWindowFields for $first/$last
-- Covers data correctness and EXPLAIN for both sortBy and no-sortBy paths
-- with GUC on and off. Uses both $first and $last in every query.
-- =============================================================================

SELECT blackboxdb_api.insert_one('db', 'wfl_dist_test', '{ "_id": 1, "g": "A", "v": 10, "name": "alpha" }');
SELECT blackboxdb_api.insert_one('db', 'wfl_dist_test', '{ "_id": 2, "g": "B", "v": 20, "name": "beta" }');
SELECT blackboxdb_api.insert_one('db', 'wfl_dist_test', '{ "_id": 3, "g": "A", "v": 30, "name": "gamma" }');
SELECT blackboxdb_api.insert_one('db', 'wfl_dist_test', '{ "_id": 4, "g": "B", "v": 40, "name": "delta" }');

SELECT blackboxdb_api.shard_collection('db', 'wfl_dist_test', '{ "_id": "hashed" }', false);

-- 3a. GUC ON: $first/$last with sortBy - data correctness
SET blackboxdb.enableNewWithExprAccumulators TO on;

set citus.propagate_set_commands to 'local';
BEGIN;
set local citus.max_adaptive_executor_pool_size to 1;
set local citus.enable_local_execution to off;

SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "wfl_dist_test", "pipeline": [{ "$setWindowFields": { "partitionBy": "$g", "sortBy": { "v": 1 }, "output": { "firstVal": { "$first": "$v" }, "lastName": { "$last": "$name" } } } }, { "$sort": { "_id": 1 } }], "cursor": {} }');

-- 3b. GUC ON: $first/$last without sortBy - data correctness
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "wfl_dist_test", "pipeline": [{ "$setWindowFields": { "partitionBy": "$g", "output": { "firstVal": { "$first": "$v" }, "lastName": { "$last": "$name" } } } }, { "$sort": { "_id": 1 } }], "cursor": {} }');

ROLLBACK;

-- 3c. GUC OFF: $first/$last with sortBy - data correctness
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;

set citus.propagate_set_commands to 'local';
BEGIN;
set local citus.max_adaptive_executor_pool_size to 1;
set local citus.enable_local_execution to off;

SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "wfl_dist_test", "pipeline": [{ "$setWindowFields": { "partitionBy": "$g", "sortBy": { "v": 1 }, "output": { "firstVal": { "$first": "$v" }, "lastName": { "$last": "$name" } } } }, { "$sort": { "_id": 1 } }], "cursor": {} }');

-- 3d. GUC OFF: $first/$last without sortBy - data correctness
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "wfl_dist_test", "pipeline": [{ "$setWindowFields": { "partitionBy": "$g", "output": { "firstVal": { "$first": "$v" }, "lastName": { "$last": "$name" } } } }, { "$sort": { "_id": 1 } }], "cursor": {} }');

ROLLBACK;

-- 3e. GUC ON: EXPLAIN $first/$last with sortBy → bsonfirst / bsonlast (sorted path)
SET blackboxdb.enableNewWithExprAccumulators TO on;

SELECT blackboxdb_distributed_test_helpers.run_explain_and_trim($cmd$ EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "wfl_dist_test", "pipeline": [{ "$setWindowFields": { "partitionBy": "$g", "sortBy": { "v": 1 }, "output": { "firstVal": { "$first": "$v" }, "lastName": { "$last": "$name" } } } }], "cursor": {} }') $cmd$);

-- 3f. GUC ON: EXPLAIN $first/$last without sortBy → bsonfirstwithexpr / bsonlastwithexpr
SELECT blackboxdb_distributed_test_helpers.run_explain_and_trim($cmd$ EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "wfl_dist_test", "pipeline": [{ "$setWindowFields": { "partitionBy": "$g", "output": { "firstVal": { "$first": "$v" }, "lastName": { "$last": "$name" } } } }], "cursor": {} }') $cmd$);

-- 3g. GUC OFF: EXPLAIN $first/$last with sortBy → bsonfirst / bsonlast (sorted path)
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;

SELECT blackboxdb_distributed_test_helpers.run_explain_and_trim($cmd$ EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "wfl_dist_test", "pipeline": [{ "$setWindowFields": { "partitionBy": "$g", "sortBy": { "v": 1 }, "output": { "firstVal": { "$first": "$v" }, "lastName": { "$last": "$name" } } } }], "cursor": {} }') $cmd$);

-- 3h. GUC OFF: EXPLAIN $first/$last without sortBy → bsonfirstonsorted / bsonlastonsorted
SELECT blackboxdb_distributed_test_helpers.run_explain_and_trim($cmd$ EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "wfl_dist_test", "pipeline": [{ "$setWindowFields": { "partitionBy": "$g", "output": { "firstVal": { "$first": "$v" }, "lastName": { "$last": "$name" } } } }], "cursor": {} }') $cmd$);

SELECT blackboxdb_api.drop_collection('db', 'wfl_dist_test');

-- =============================================================================
-- Test 4: Sharded $sort + $group with only $first and enableSortGroupStage.
-- When enableSortGroupStage is on, the Sort node should disappear and
-- $first should use aggregate-internal ORDER BY instead.
-- =============================================================================

SELECT blackboxdb_api.insert_one('db', 'fl_sortgroup_dist', '{ "_id": 1, "g": "X", "seq": 30, "val": "third" }');
SELECT blackboxdb_api.insert_one('db', 'fl_sortgroup_dist', '{ "_id": 2, "g": "X", "seq": 10, "val": "first" }');
SELECT blackboxdb_api.insert_one('db', 'fl_sortgroup_dist', '{ "_id": 3, "g": "X", "seq": 20, "val": "second" }');
SELECT blackboxdb_api.insert_one('db', 'fl_sortgroup_dist', '{ "_id": 4, "g": "Y", "seq": 50, "val": "later" }');
SELECT blackboxdb_api.insert_one('db', 'fl_sortgroup_dist', '{ "_id": 5, "g": "Y", "seq": 5, "val": "earliest" }');
SELECT blackboxdb_api.insert_one('db', 'fl_sortgroup_dist', '{ "_id": 6, "g": "Z", "seq": 40, "val": "high" }');
SELECT blackboxdb_api.insert_one('db', 'fl_sortgroup_dist', '{ "_id": 7, "g": "Z", "seq": 15, "val": "low" }');
SELECT blackboxdb_api.insert_one('db', 'fl_sortgroup_dist', '{ "_id": 8, "g": "Z", "seq": 25, "val": "mid" }');
SELECT blackboxdb_api.insert_one('db', 'fl_sortgroup_dist', '{ "_id": 9, "g": "W", "seq": 100, "val": "only-high" }');
SELECT blackboxdb_api.insert_one('db', 'fl_sortgroup_dist', '{ "_id": 10, "g": "W", "seq": 1, "val": "only-low" }');

SELECT blackboxdb_api.shard_collection('db', 'fl_sortgroup_dist', '{ "_id": "hashed" }', false);

-- 4a. sortGroup OFF: Sort node should be present, data correctness
SET blackboxdb.enableSortGroupStage TO off;

set citus.propagate_set_commands to 'local';
BEGIN;
set local citus.max_adaptive_executor_pool_size to 1;
set local citus.enable_local_execution to off;

SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "fl_sortgroup_dist", "pipeline": [ { "$sort": { "g": 1, "seq": 1 } }, { "$group": { "_id": "$g", "firstVal": { "$first": "$val" } } } ] }');

ROLLBACK;

-- 4b. sortGroup ON: Sort node should disappear, orderby pushed to aggregate
SET blackboxdb.enableSortGroupStage TO on;
SET blackboxdb.enableSortPushToAccumulatorWithPrefix TO on;

set citus.propagate_set_commands to 'local';
BEGIN;
set local citus.max_adaptive_executor_pool_size to 1;
set local citus.enable_local_execution to off;

SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "fl_sortgroup_dist", "pipeline": [ { "$sort": { "g": 1, "seq": 1 } }, { "$group": { "_id": "$g", "firstVal": { "$first": "$val" } } } ] }');

ROLLBACK;

RESET blackboxdb.enableSortGroupStage;
RESET blackboxdb.enableSortPushToAccumulatorWithPrefix;
SELECT blackboxdb_api.drop_collection('db', 'fl_sortgroup_dist');

-- =============================================================================
-- Test 5: Sharded $group with $first using an expression, exercising the
-- relpath distinct-scan path on worker shards (enableDistinctScanForGroupFirst).
-- Use one document per category so $first on each group is deterministic
-- regardless of shard-local row ordering.
-- =============================================================================

SELECT blackboxdb_api.insert_one('db', 'fl_distinct_dist', '{ "_id": 1, "category": "A", "name": "alpha" }');
SELECT blackboxdb_api.insert_one('db', 'fl_distinct_dist', '{ "_id": 2, "category": "B", "name": "beta" }');
SELECT blackboxdb_api.insert_one('db', 'fl_distinct_dist', '{ "_id": 3, "category": "C", "name": "gamma" }');

SELECT blackboxdb_api.shard_collection('db', 'fl_distinct_dist', '{ "_id": "hashed" }', false);

set citus.propagate_set_commands to 'local';
BEGIN;
set local citus.max_adaptive_executor_pool_size to 1;
set local citus.enable_local_execution to off;
SET LOCAL blackboxdb.enableNewWithExprAccumulators TO on;
SET LOCAL blackboxdb.enableDistinctScanForGroupFirst TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "fl_distinct_dist", "pipeline": [ { "$group": { "_id": "$category", "firstExpr": { "$first": { "$concat": ["$name", "-seen"] } } } }, { "$sort": { "_id": 1 } } ], "cursor": {} }');
ROLLBACK;

SELECT blackboxdb_api.drop_collection('db', 'fl_distinct_dist');

SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;

-- =============================================================================
-- Test 6: reshaping ($project) stage before $group on a sharded collection.
-- The $project makes the $first/$last accumulator's document argument a
-- computed expression (not the raw stored column), and sharding forces
-- two-phase distributed aggregation. The document argument must present a type
-- that exactly matches the WithExpr aggregate signature or the distributed
-- partial aggregation aborts.
-- =============================================================================

SELECT blackboxdb_api.insert_one('db', 'fl_project_group_dist', '{ "_id": 1, "g": "A", "a": "alpha" }');
SELECT blackboxdb_api.insert_one('db', 'fl_project_group_dist', '{ "_id": 2, "g": "A", "a": "apple" }');
SELECT blackboxdb_api.insert_one('db', 'fl_project_group_dist', '{ "_id": 3, "g": "B", "a": "beta" }');
SELECT blackboxdb_api.insert_one('db', 'fl_project_group_dist', '{ "_id": 4, "g": "B", "a": "berry" }');

SELECT blackboxdb_api.shard_collection('db', 'fl_project_group_dist', '{ "_id": "hashed" }', false);

set citus.propagate_set_commands to 'local';
BEGIN;
set local citus.max_adaptive_executor_pool_size to 1;
set local citus.enable_local_execution to off;
SET LOCAL blackboxdb.enableNewWithExprAccumulators TO on;

-- Global group after a $project: $first/$last on a projected field.
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "fl_project_group_dist", "pipeline": [ { "$project": { "_id": 0, "a": 1 } }, { "$group": { "_id": null, "firstVal": { "$first": "$a" }, "lastVal": { "$last": "$a" } } } ], "cursor": {} }');

-- Grouped by a non shard-key field after a $project, with a following $sort.
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "fl_project_group_dist", "pipeline": [ { "$project": { "_id": 0, "g": 1, "a": 1 } }, { "$group": { "_id": "$g", "firstVal": { "$first": "$a" }, "lastVal": { "$last": "$a" } } }, { "$sort": { "_id": 1 } } ], "cursor": {} }');

ROLLBACK;

SELECT blackboxdb_api.drop_collection('db', 'fl_project_group_dist');

SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
