SET search_path TO blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog,blackboxdb_api_internal;

SET citus.next_shard_id TO 640000;
SET blackboxdb.next_collection_id TO 6400;
SET blackboxdb.next_collection_index_id TO 6400;

-- if blackboxdb_extended_rum exists, set alternate index handler
SELECT pg_catalog.set_config('blackboxdb.alternate_index_handler_name', 'extended_rum', false), extname FROM pg_extension WHERE extname = 'blackboxdb_extended_rum';

-- The scope of this test is to verify EXPLAIN output, but due to a citus bug will only run in pg17 and pg18.
-- Window aggregate EXPLAIN output will be covered in a seperate test that runs on all versions.

-- Insert and shard a single collection used by all tests below
SELECT blackboxdb_api.insert_one('db','group_firstlast_dist','{ "_id": 1, "category": "A", "val": 10, "name": "alpha" }', NULL);
SELECT blackboxdb_api.insert_one('db','group_firstlast_dist','{ "_id": 2, "category": "B", "val": 20, "name": "beta" }', NULL);
SELECT blackboxdb_api.insert_one('db','group_firstlast_dist','{ "_id": 3, "category": "A", "val": 30, "name": "gamma" }', NULL);
SELECT blackboxdb_api.insert_one('db','group_firstlast_dist','{ "_id": 4, "category": "B", "val": 40, "name": "delta" }', NULL);
SELECT blackboxdb_api.insert_one('db','group_firstlast_dist','{ "_id": 5, "category": "A", "val": 50, "name": "epsilon" }', NULL);
SELECT blackboxdb_api.insert_one('db','group_firstlast_dist','{ "_id": 6, "category": "C", "val": 60, "name": "zeta" }', NULL);

SET blackboxdb.defaultUseCompositeOpClass TO on;
\set prevEcho :ECHO
\set ECHO none
\o /dev/null
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db',
  '{ "createIndexes": "group_firstlast_dist", "indexes": [{ "key": { "category": 1 }, "name": "idx_category", "enableOrderedIndex": true }] }',
  true);
\o
\set ECHO :prevEcho

SELECT blackboxdb_api.shard_collection('db', 'group_firstlast_dist', '{ "_id": "hashed" }', false);

set citus.propagate_set_commands to 'local';

-- ===== $first without $sort =====

-- GUC OFF: should show bsonfirstonsorted
SET blackboxdb.enableNewWithExprAccumulators TO off;
BEGIN;
set local citus.max_adaptive_executor_pool_size to 1;
set local citus.enable_local_execution to off;
set local citus.explain_analyze_sort_method to taskId;
SET blackboxdb.enableDebugQueryText TO on;
SELECT blackboxdb_distributed_test_helpers.run_explain_and_trim($cmd$
  EXPLAIN (ANALYZE ON, COSTS OFF, BUFFERS OFF, TIMING OFF, SUMMARY OFF, VERBOSE ON)
  SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "group_firstlast_dist", "pipeline": [ { "$group": { "_id": "$category", "firstVal": { "$first": "$val" }, "firstName": { "$first": "$name" } } } ], "cursor": {} }')
$cmd$);
ROLLBACK;

-- GUC OFF + direct-field $first: worker should not use the distinct scan.
-- This is the old accumulator path: shard workers project rows and the final
-- grouped $first is applied above the distributed scan, so this plan is
-- expected to differ from the with-expr case below.
SET blackboxdb.enableNewWithExprAccumulators TO off;
BEGIN;
set local citus.max_adaptive_executor_pool_size to 1;
set local citus.enable_local_execution to off;
set local citus.explain_analyze_sort_method to taskId;
set local enable_seqscan to off;
set local enable_bitmapscan to off;
set local enable_hashagg to off;
SET LOCAL blackboxdb_api.forceUseIndexIfAvailable TO on;
SET LOCAL blackboxdb.enableDebugQueryText TO on;
SET LOCAL blackboxdb.enableDistinctScanForGroupFirst TO on;
SELECT blackboxdb_distributed_test_helpers.run_explain_and_trim($cmd$
  EXPLAIN (ANALYZE ON, COSTS OFF, BUFFERS OFF, TIMING OFF, SUMMARY OFF, VERBOSE ON)
  SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "group_firstlast_dist", "pipeline": [ { "$group": { "_id": "$category", "firstVal": { "$first": "$val" } } }, { "$sort": { "_id": 1 } } ], "cursor": {} }')
$cmd$);
ROLLBACK;
-- GUC ON: should show bsonfirstwithexpr
SET blackboxdb.enableNewWithExprAccumulators TO on;
BEGIN;
set local citus.max_adaptive_executor_pool_size to 1;
set local citus.enable_local_execution to off;
set local citus.explain_analyze_sort_method to taskId;
SET blackboxdb.enableDebugQueryText TO on;
SELECT blackboxdb_distributed_test_helpers.run_explain_and_trim($cmd$
  EXPLAIN (ANALYZE ON, COSTS OFF, BUFFERS OFF, TIMING OFF, SUMMARY OFF, VERBOSE ON)
  SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "group_firstlast_dist", "pipeline": [ { "$group": { "_id": "$category", "firstVal": { "$first": "$val" }, "firstName": { "$first": "$name" } } } ], "cursor": {} }')
$cmd$);
ROLLBACK;

-- GUC ON + distinct scan for $first with expression: worker should use
-- BlackboxDBApiDistinctQueryScan with bsonfirstwithexpr.
-- With the new accumulator path, Citus pushes a worker_partial_agg wrapper to
-- shard workers. The relpath distinct-scan hook unwraps that wrapper, sees the
-- underlying bsonfirstwithexpr aggregate, and can optimize the shard scan.
BEGIN;
set local citus.max_adaptive_executor_pool_size to 1;
set local citus.enable_local_execution to off;
set local citus.explain_analyze_sort_method to taskId;
set local enable_seqscan to off;
set local enable_bitmapscan to off;
set local enable_hashagg to off;
SET LOCAL blackboxdb_api.forceUseIndexIfAvailable TO on;
SET LOCAL blackboxdb.enableDebugQueryText TO on;
SET LOCAL blackboxdb.enableDistinctScanForGroupFirst TO on;
SELECT blackboxdb_distributed_test_helpers.run_explain_and_trim($cmd$
  EXPLAIN (ANALYZE ON, COSTS OFF, BUFFERS OFF, TIMING OFF, SUMMARY OFF, VERBOSE ON)
  SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "group_firstlast_dist", "pipeline": [ { "$group": { "_id": "$category", "firstExpr": { "$first": { "$concat": ["$name", "-seen"] } } } }, { "$sort": { "_id": 1 } } ], "cursor": {} }')
$cmd$);
ROLLBACK;
-- Single group without $sort (GUC on) - should show bsonfirstwithexpr
BEGIN;
set local citus.max_adaptive_executor_pool_size to 1;
set local citus.enable_local_execution to off;
set local citus.explain_analyze_sort_method to taskId;
SET blackboxdb.enableDebugQueryText TO on;
SELECT blackboxdb_distributed_test_helpers.run_explain_and_trim($cmd$
  EXPLAIN (ANALYZE ON, COSTS OFF, BUFFERS OFF, TIMING OFF, SUMMARY OFF, VERBOSE ON)
  SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "group_firstlast_dist", "pipeline": [ { "$group": { "_id": null, "firstName": { "$first": "$name" } } } ], "cursor": {} }')
$cmd$);
ROLLBACK;

-- ===== $first with $sort =====

-- GUC OFF: with $sort - uses bsonfirst
SET blackboxdb.enableNewWithExprAccumulators TO off;
BEGIN;
set local citus.max_adaptive_executor_pool_size to 1;
set local citus.enable_local_execution to off;
set local citus.explain_analyze_sort_method to taskId;
SET blackboxdb.enableDebugQueryText TO on;
SELECT blackboxdb_distributed_test_helpers.run_explain_and_trim($cmd$
  EXPLAIN (ANALYZE ON, COSTS OFF, BUFFERS OFF, TIMING OFF, SUMMARY OFF, VERBOSE ON)
  SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "group_firstlast_dist", "pipeline": [ { "$sort": { "val": -1 } }, { "$group": { "_id": "$category", "firstVal": { "$first": "$val" }, "firstName": { "$first": "$name" } } } ], "cursor": {} }')
$cmd$);
ROLLBACK;

-- GUC ON: should still use bsonfirst (not new accumulators) when $sort precedes
SET blackboxdb.enableNewWithExprAccumulators TO on;
BEGIN;
set local citus.max_adaptive_executor_pool_size to 1;
set local citus.enable_local_execution to off;
set local citus.explain_analyze_sort_method to taskId;
SET blackboxdb.enableDebugQueryText TO on;
SELECT blackboxdb_distributed_test_helpers.run_explain_and_trim($cmd$
  EXPLAIN (ANALYZE ON, COSTS OFF, BUFFERS OFF, TIMING OFF, SUMMARY OFF, VERBOSE ON)
  SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "group_firstlast_dist", "pipeline": [ { "$sort": { "val": -1 } }, { "$group": { "_id": "$category", "firstVal": { "$first": "$val" }, "firstName": { "$first": "$name" } } } ], "cursor": {} }')
$cmd$);
ROLLBACK;

-- Single group with $sort (GUC on)
BEGIN;
set local citus.max_adaptive_executor_pool_size to 1;
set local citus.enable_local_execution to off;
set local citus.explain_analyze_sort_method to taskId;
SET blackboxdb.enableDebugQueryText TO on;
SELECT blackboxdb_distributed_test_helpers.run_explain_and_trim($cmd$
  EXPLAIN (ANALYZE ON, COSTS OFF, BUFFERS OFF, TIMING OFF, SUMMARY OFF, VERBOSE ON)
  SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "group_firstlast_dist", "pipeline": [ { "$sort": { "val": -1 } }, { "$group": { "_id": null, "firstName": { "$first": "$name" } } } ], "cursor": {} }')
$cmd$);
ROLLBACK;

-- ===== $last without $sort =====

-- GUC OFF: should show bsonlastonsorted
SET blackboxdb.enableNewWithExprAccumulators TO off;
BEGIN;
set local citus.max_adaptive_executor_pool_size to 1;
set local citus.enable_local_execution to off;
set local citus.explain_analyze_sort_method to taskId;
SET blackboxdb.enableDebugQueryText TO on;
SELECT blackboxdb_distributed_test_helpers.run_explain_and_trim($cmd$
  EXPLAIN (ANALYZE ON, COSTS OFF, BUFFERS OFF, TIMING OFF, SUMMARY OFF, VERBOSE ON)
  SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "group_firstlast_dist", "pipeline": [ { "$group": { "_id": "$category", "lastVal": { "$last": "$val" }, "lastName": { "$last": "$name" } } } ], "cursor": {} }')
$cmd$);
ROLLBACK;

-- GUC ON: should show bsonlastwithexpr
SET blackboxdb.enableNewWithExprAccumulators TO on;
BEGIN;
set local citus.max_adaptive_executor_pool_size to 1;
set local citus.enable_local_execution to off;
set local citus.explain_analyze_sort_method to taskId;
SET blackboxdb.enableDebugQueryText TO on;
SELECT blackboxdb_distributed_test_helpers.run_explain_and_trim($cmd$
  EXPLAIN (ANALYZE ON, COSTS OFF, BUFFERS OFF, TIMING OFF, SUMMARY OFF, VERBOSE ON)
  SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "group_firstlast_dist", "pipeline": [ { "$group": { "_id": "$category", "lastVal": { "$last": "$val" }, "lastName": { "$last": "$name" } } } ], "cursor": {} }')
$cmd$);
ROLLBACK;

-- Single group without $sort (GUC on) - should show bsonlastwithexpr
BEGIN;
set local citus.max_adaptive_executor_pool_size to 1;
set local citus.enable_local_execution to off;
set local citus.explain_analyze_sort_method to taskId;
SET blackboxdb.enableDebugQueryText TO on;
SELECT blackboxdb_distributed_test_helpers.run_explain_and_trim($cmd$
  EXPLAIN (ANALYZE ON, COSTS OFF, BUFFERS OFF, TIMING OFF, SUMMARY OFF, VERBOSE ON)
  SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "group_firstlast_dist", "pipeline": [ { "$group": { "_id": null, "lastName": { "$last": "$name" } } } ], "cursor": {} }')
$cmd$);
ROLLBACK;

-- ===== $last with $sort =====

-- GUC ON: should still use bsonlast (not new accumulators) when $sort precedes
SET blackboxdb.enableNewWithExprAccumulators TO on;
BEGIN;
set local citus.max_adaptive_executor_pool_size to 1;
set local citus.enable_local_execution to off;
set local citus.explain_analyze_sort_method to taskId;
SET blackboxdb.enableDebugQueryText TO on;
SELECT blackboxdb_distributed_test_helpers.run_explain_and_trim($cmd$
  EXPLAIN (ANALYZE ON, COSTS OFF, BUFFERS OFF, TIMING OFF, SUMMARY OFF, VERBOSE ON)
  SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "group_firstlast_dist", "pipeline": [ { "$sort": { "val": -1 } }, { "$group": { "_id": "$category", "lastVal": { "$last": "$val" }, "lastName": { "$last": "$name" } } } ], "cursor": {} }')
$cmd$);
ROLLBACK;

-- Single group with $sort (GUC on)
BEGIN;
set local citus.max_adaptive_executor_pool_size to 1;
set local citus.enable_local_execution to off;
set local citus.explain_analyze_sort_method to taskId;
SET blackboxdb.enableDebugQueryText TO on;
SELECT blackboxdb_distributed_test_helpers.run_explain_and_trim($cmd$
  EXPLAIN (ANALYZE ON, COSTS OFF, BUFFERS OFF, TIMING OFF, SUMMARY OFF, VERBOSE ON)
  SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "group_firstlast_dist", "pipeline": [ { "$sort": { "val": -1 } }, { "$group": { "_id": null, "lastName": { "$last": "$name" } } } ], "cursor": {} }')
$cmd$);
ROLLBACK;

-- ===== Collation EXPLAIN =====

-- GUC ON + collation: should show bsonfirstwithexpr / bsonlastwithexpr with collation locale
SET blackboxdb_core.enableCollation TO on;
SET blackboxdb.enableCollationWithNewGroupAccumulators TO on;
SET blackboxdb.enableNewWithExprAccumulators TO on;
BEGIN;
set local citus.max_adaptive_executor_pool_size to 1;
set local citus.enable_local_execution to off;
set local citus.explain_analyze_sort_method to taskId;
SET blackboxdb.enableDebugQueryText TO on;
SELECT blackboxdb_distributed_test_helpers.run_explain_and_trim($cmd$
  EXPLAIN (ANALYZE ON, COSTS OFF, BUFFERS OFF, TIMING OFF, SUMMARY OFF, VERBOSE ON)
  SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "group_firstlast_dist", "pipeline": [ { "$group": { "_id": "$category", "firstName": { "$first": "$name" }, "lastName": { "$last": "$name" } } } ], "cursor": {}, "collation": { "locale": "en", "strength": 1 } }')
$cmd$);
ROLLBACK;

SET blackboxdb.enableNewWithExprAccumulators TO off;
SET blackboxdb.enableCollationWithNewGroupAccumulators TO off;
SET blackboxdb_core.enableCollation TO off;

-- ===== $sort + $group with $first and enableSortGroupStage =====

-- sortGroup OFF: Sort node should be present in the plan
SET blackboxdb.enableSortGroupStage TO off;
BEGIN;
set local citus.max_adaptive_executor_pool_size to 1;
set local citus.enable_local_execution to off;
set local citus.explain_analyze_sort_method to taskId;
SET blackboxdb.enableDebugQueryText TO on;
SELECT blackboxdb_distributed_test_helpers.run_explain_and_trim($cmd$
  EXPLAIN (ANALYZE ON, COSTS OFF, BUFFERS OFF, TIMING OFF, SUMMARY OFF, VERBOSE ON)
  SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "group_firstlast_dist", "pipeline": [ { "$sort": { "category": 1, "val": 1 } }, { "$group": { "_id": "$category", "firstVal": { "$first": "$val" } } } ], "cursor": {} }')
$cmd$);
ROLLBACK;

-- sortGroup ON + WithPrefix: group key {category} is a prefix of sort {category, val};
-- the suffix {val} gets pushed into the accumulator's ORDER BY and the Sort node
-- should disappear.
SET blackboxdb.enableSortGroupStage TO on;
SET blackboxdb.enableSortPushToAccumulatorWithPrefix TO on;
BEGIN;
set local citus.max_adaptive_executor_pool_size to 1;
set local citus.enable_local_execution to off;
set local citus.explain_analyze_sort_method to taskId;
SET blackboxdb.enableDebugQueryText TO on;
SELECT blackboxdb_distributed_test_helpers.run_explain_and_trim($cmd$
  EXPLAIN (ANALYZE ON, COSTS OFF, BUFFERS OFF, TIMING OFF, SUMMARY OFF, VERBOSE ON)
  SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "group_firstlast_dist", "pipeline": [ { "$sort": { "category": 1, "val": 1 } }, { "$group": { "_id": "$category", "firstVal": { "$first": "$val" } } } ], "cursor": {} }')
$cmd$);
ROLLBACK;

RESET blackboxdb.enableSortGroupStage;
RESET blackboxdb.enableSortPushToAccumulatorWithPrefix;

-- Cleanup
SELECT blackboxdb_api.drop_collection('db', 'group_firstlast_dist');
