SET search_path TO blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog,pg_catalog;

SET citus.next_shard_id TO 1125000;
SET blackboxdb.next_collection_id TO 11250;
SET blackboxdb.next_collection_index_id TO 11250;

-- =============================================================================
-- Test 1: Different type values across shards (type coercion)
-- =============================================================================

SELECT blackboxdb_api.insert_one('db','sumavg_shard_types_test','{ "_id": 1, "group": "mixed", "val": 42 }');
SELECT blackboxdb_api.insert_one('db','sumavg_shard_types_test','{ "_id": 2, "group": "mixed", "val": "100" }');
SELECT blackboxdb_api.insert_one('db','sumavg_shard_types_test','{ "_id": 3, "group": "mixed", "val": { "$numberDouble": "42.0" } }');
SELECT blackboxdb_api.insert_one('db','sumavg_shard_types_test','{ "_id": 4, "group": "mixed", "val": true }');
SELECT blackboxdb_api.insert_one('db','sumavg_shard_types_test','{ "_id": 5, "group": "mixed", "val": [50] }');
SELECT blackboxdb_api.insert_one('db','sumavg_shard_types_test','{ "_id": 6, "group": "mixed", "val": { "$numberLong": "99" } }');
SELECT blackboxdb_api.insert_one('db','sumavg_shard_types_test','{ "_id": 7, "group": "nums", "val": 10 }');
SELECT blackboxdb_api.insert_one('db','sumavg_shard_types_test','{ "_id": 8, "group": "nums", "val": { "$numberDouble": "25.5" } }');
SELECT blackboxdb_api.insert_one('db','sumavg_shard_types_test','{ "_id": 9, "group": "nums", "val": { "$numberLong": "50" } }');
SELECT blackboxdb_api.insert_one('db','sumavg_shard_types_test','{ "_id": 10, "group": "nums", "val": { "$numberDecimal": "75.25" } }');

SET citus.enable_local_execution TO off;

-- Pre-sharding results
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "sumavg_shard_types_test", "pipeline": [ { "$group": { "_id": "$group", "total": { "$sum": "$val" }, "average": { "$avg": "$val" } } }, { "$sort": { "_id": 1 } } ] }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "sumavg_shard_types_test", "pipeline": [ { "$group": { "_id": "$group", "total": { "$sum": "$val" }, "average": { "$avg": "$val" } } }, { "$sort": { "_id": 1 } } ] }');
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "sumavg_shard_types_test", "pipeline": [ { "$group": { "_id": "$group", "total": { "$sum": "$val" }, "average": { "$avg": "$val" } } }, { "$sort": { "_id": 1 } } ] }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "sumavg_shard_types_test", "pipeline": [ { "$group": { "_id": "$group", "total": { "$sum": "$val" }, "average": { "$avg": "$val" } } }, { "$sort": { "_id": 1 } } ] }');

-- Shard the collection
SELECT blackboxdb_api.shard_collection('db', 'sumavg_shard_types_test', '{ "_id": "hashed" }', false);

-- Post-sharding results (should be same as pre-sharding)
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "sumavg_shard_types_test", "pipeline": [ { "$group": { "_id": "$group", "total": { "$sum": "$val" }, "average": { "$avg": "$val" } } }, { "$sort": { "_id": 1 } } ] }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "sumavg_shard_types_test", "pipeline": [ { "$group": { "_id": "$group", "total": { "$sum": "$val" }, "average": { "$avg": "$val" } } }, { "$sort": { "_id": 1 } } ] }');
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "sumavg_shard_types_test", "pipeline": [ { "$group": { "_id": "$group", "total": { "$sum": "$val" }, "average": { "$avg": "$val" } } }, { "$sort": { "_id": 1 } } ] }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "sumavg_shard_types_test", "pipeline": [ { "$group": { "_id": "$group", "total": { "$sum": "$val" }, "average": { "$avg": "$val" } } }, { "$sort": { "_id": 1 } } ] }');

RESET citus.enable_local_execution;

-- =============================================================================
-- Test 2: Sharded collection with collation on $sum/$avg
-- =============================================================================

SET blackboxdb_core.enableCollation TO on;
SET blackboxdb.enableNewWithExprAccumulators TO on;
SET blackboxdb.enableCollationWithNewGroupAccumulators TO on;

SELECT blackboxdb_api.insert_one('db','sumavg_collation_test','{ "_id": 1, "group": "A", "name": "cherry", "val": 10 }');
SELECT blackboxdb_api.insert_one('db','sumavg_collation_test','{ "_id": 2, "group": "A", "name": "BANANA", "val": 20 }');
SELECT blackboxdb_api.insert_one('db','sumavg_collation_test','{ "_id": 3, "group": "A", "name": "Apple", "val": 30 }');
SELECT blackboxdb_api.insert_one('db','sumavg_collation_test','{ "_id": 4, "group": "a", "name": "date", "val": 40 }');
SELECT blackboxdb_api.insert_one('db','sumavg_collation_test','{ "_id": 5, "group": "a", "name": "FIG", "val": 50 }');

SELECT blackboxdb_api.shard_collection('db', 'sumavg_collation_test', '{ "_id": "hashed" }', false);

-- Post-sharding $sum counting with collation (should match pre-sharding results)
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "sumavg_collation_test", "pipeline": [ { "$group": { "_id": "$group", "matchCount": { "$sum": { "$cond": { "if": { "$eq": ["$name", "CHERRY"] }, "then": 1, "else": 0 } } } } }, { "$sort": { "_id": 1 } } ], "collation": { "locale": "en", "strength": 1 } }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "sumavg_collation_test", "pipeline": [ { "$group": { "_id": "$group", "matchCount": { "$sum": { "$cond": { "if": { "$eq": ["$name", "CHERRY"] }, "then": 1, "else": 0 } } } } }, { "$sort": { "_id": 1 } } ], "collation": { "locale": "en", "strength": 1 } }');

-- Post-sharding constant group with collation
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "sumavg_collation_test", "pipeline": [ { "$group": { "_id": null, "matchCount": { "$sum": { "$cond": { "if": { "$eq": ["$name", "CHERRY"] }, "then": 1, "else": 0 } } }, "matchedAvg": { "$avg": { "$cond": { "if": { "$eq": ["$name", "CHERRY"] }, "then": "$val", "else": null } } } } } ], "collation": { "locale": "en", "strength": 1 } }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "sumavg_collation_test", "pipeline": [ { "$group": { "_id": null, "matchCount": { "$sum": { "$cond": { "if": { "$eq": ["$name", "CHERRY"] }, "then": 1, "else": 0 } } }, "matchedAvg": { "$avg": { "$cond": { "if": { "$eq": ["$name", "CHERRY"] }, "then": "$val", "else": null } } } } } ], "collation": { "locale": "en", "strength": 1 } }');

SET citus.enable_local_execution TO off;

-- Post-sharding remote execution with collation
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "sumavg_collation_test", "pipeline": [ { "$group": { "_id": "$group", "matchCount": { "$sum": { "$cond": { "if": { "$eq": ["$name", "CHERRY"] }, "then": 1, "else": 0 } } } } }, { "$sort": { "_id": 1 } } ], "collation": { "locale": "en", "strength": 1 } }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "sumavg_collation_test", "pipeline": [ { "$group": { "_id": "$group", "matchCount": { "$sum": { "$cond": { "if": { "$eq": ["$name", "CHERRY"] }, "then": 1, "else": 0 } } } } }, { "$sort": { "_id": 1 } } ], "collation": { "locale": "en", "strength": 1 } }');

-- Post-sharding remote constant group with collation
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "sumavg_collation_test", "pipeline": [ { "$group": { "_id": null, "matchCount": { "$sum": { "$cond": { "if": { "$eq": ["$name", "CHERRY"] }, "then": 1, "else": 0 } } }, "matchedAvg": { "$avg": { "$cond": { "if": { "$eq": ["$name", "CHERRY"] }, "then": "$val", "else": null } } } } } ], "collation": { "locale": "en", "strength": 1 } }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "sumavg_collation_test", "pipeline": [ { "$group": { "_id": null, "matchCount": { "$sum": { "$cond": { "if": { "$eq": ["$name", "CHERRY"] }, "then": 1, "else": 0 } } }, "matchedAvg": { "$avg": { "$cond": { "if": { "$eq": ["$name", "CHERRY"] }, "then": "$val", "else": null } } } } } ], "collation": { "locale": "en", "strength": 1 } }');

RESET citus.enable_local_execution;

-- =============================================================================
-- Test 3: $sum/$avg numericOrdering collation with remote/sharded execution
-- Verifies that collation-aware expression evaluation works correctly in the
-- transition function on worker nodes during distributed aggregation.
-- =============================================================================

SELECT blackboxdb_api.insert_one('db','sumavg_numord_dist_test','{ "_id": 1,  "grp": "x", "val": "10" }');
SELECT blackboxdb_api.insert_one('db','sumavg_numord_dist_test','{ "_id": 2,  "grp": "x", "val": "2" }');
SELECT blackboxdb_api.insert_one('db','sumavg_numord_dist_test','{ "_id": 3,  "grp": "x", "val": "20" }');
SELECT blackboxdb_api.insert_one('db','sumavg_numord_dist_test','{ "_id": 4,  "grp": "x", "val": "3" }');
SELECT blackboxdb_api.insert_one('db','sumavg_numord_dist_test','{ "_id": 5,  "grp": "x", "val": "9" }');
SELECT blackboxdb_api.insert_one('db','sumavg_numord_dist_test','{ "_id": 6,  "grp": "x", "val": "100" }');
SELECT blackboxdb_api.insert_one('db','sumavg_numord_dist_test','{ "_id": 7,  "grp": "x", "val": "1" }');
SELECT blackboxdb_api.insert_one('db','sumavg_numord_dist_test','{ "_id": 8,  "grp": "x", "val": "50" }');
SELECT blackboxdb_api.insert_one('db','sumavg_numord_dist_test','{ "_id": 9,  "grp": "x", "val": "5" }');
SELECT blackboxdb_api.insert_one('db','sumavg_numord_dist_test','{ "_id": 10, "grp": "x", "val": "200" }');

SELECT blackboxdb_api.insert_one('db','sumavg_numord_dist_test','{ "_id": 11, "grp": "y", "val": "8" }');
SELECT blackboxdb_api.insert_one('db','sumavg_numord_dist_test','{ "_id": 12, "grp": "y", "val": "80" }');
SELECT blackboxdb_api.insert_one('db','sumavg_numord_dist_test','{ "_id": 13, "grp": "y", "val": "800" }');
SELECT blackboxdb_api.insert_one('db','sumavg_numord_dist_test','{ "_id": 14, "grp": "y", "val": "4" }');
SELECT blackboxdb_api.insert_one('db','sumavg_numord_dist_test','{ "_id": 15, "grp": "y", "val": "40" }');
SELECT blackboxdb_api.insert_one('db','sumavg_numord_dist_test','{ "_id": 16, "grp": "y", "val": "400" }');
SELECT blackboxdb_api.insert_one('db','sumavg_numord_dist_test','{ "_id": 17, "grp": "y", "val": "6" }');
SELECT blackboxdb_api.insert_one('db','sumavg_numord_dist_test','{ "_id": 18, "grp": "y", "val": "60" }');
SELECT blackboxdb_api.insert_one('db','sumavg_numord_dist_test','{ "_id": 19, "grp": "y", "val": "600" }');
SELECT blackboxdb_api.insert_one('db','sumavg_numord_dist_test','{ "_id": 20, "grp": "y", "val": "7" }');

SELECT blackboxdb_api.shard_collection('db', 'sumavg_numord_dist_test', '{ "_id": "hashed" }', false);

SET citus.enable_local_execution TO off;

-- Post-shard remote execution: count items > "5" with numericOrdering
-- numericOrdering=true: x has 6 items > 5 (9,10,20,50,100,200), y has 7 items > 5 (6,7,8,40,60,80,400,600,800)
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "sumavg_numord_dist_test", "pipeline": [ { "$group": { "_id": "$grp", "countAbove": { "$sum": { "$cond": { "if": { "$gt": ["$val", "5"] }, "then": 1, "else": 0 } } } } }, { "$sort": { "_id": 1 } } ], "collation": { "locale": "en", "numericOrdering": true } }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "sumavg_numord_dist_test", "pipeline": [ { "$group": { "_id": "$grp", "countAbove": { "$sum": { "$cond": { "if": { "$gt": ["$val", "5"] }, "then": 1, "else": 0 } } } } }, { "$sort": { "_id": 1 } } ], "collation": { "locale": "en", "numericOrdering": true } }');

-- Post-shard remote execution: constant group
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "sumavg_numord_dist_test", "pipeline": [ { "$group": { "_id": null, "countAbove": { "$sum": { "$cond": { "if": { "$gt": ["$val", "5"] }, "then": 1, "else": 0 } } } } } ], "collation": { "locale": "en", "numericOrdering": true } }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "sumavg_numord_dist_test", "pipeline": [ { "$group": { "_id": null, "countAbove": { "$sum": { "$cond": { "if": { "$gt": ["$val", "5"] }, "then": 1, "else": 0 } } } } } ], "collation": { "locale": "en", "numericOrdering": true } }');

RESET citus.enable_local_execution;
SET blackboxdb.enableCollationWithNewGroupAccumulators TO off;
SET blackboxdb_core.enableCollation TO off;
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;

-- =============================================================================
-- Test: enableSortGroupStage drops dead outer $sort for order-insensitive
--       $group accumulators on sharded collections while preserving results
-- =============================================================================

SELECT blackboxdb_api.insert_one('db','sortgroup_shard_test','{ "_id": 1, "g": "A", "seq": 30, "v": 10, "bonus": 2 }');
SELECT blackboxdb_api.insert_one('db','sortgroup_shard_test','{ "_id": 2, "g": "A", "seq": 10, "v": 6, "bonus": 4 }');
SELECT blackboxdb_api.insert_one('db','sortgroup_shard_test','{ "_id": 3, "g": "B", "seq": 20, "v": 5, "bonus": 1 }');
SELECT blackboxdb_api.insert_one('db','sortgroup_shard_test','{ "_id": 4, "g": "B", "seq": 40, "v": 9, "bonus": 3 }');

SELECT blackboxdb_api.shard_collection('db', 'sortgroup_shard_test', '{ "_id": "hashed" }', false);

SET citus.enable_local_execution TO off;

-- With sortGroup disabled, the user $sort on seq should remain in the plan.
SET blackboxdb.enableSortGroupStage TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "sortgroup_shard_test", "pipeline": [ { "$sort": { "seq": 1 } }, { "$group": { "_id": "$g", "total": { "$sum": "$v" }, "adjustedAverage": { "$avg": { "$add": ["$v", "$bonus"] } }, "lo": { "$min": "$v" }, "hi": { "$max": "$v" }, "count": { "$count": {} } } }, { "$sort": { "_id": 1 } } ] }');
SELECT COUNT(*) AS worker_seq_sort_count
FROM blackboxdb_distributed_test_helpers.run_explain_and_trim($cmd$
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "sortgroup_shard_test", "pipeline": [ { "$sort": { "seq": 1 } }, { "$group": { "_id": "$g", "total": { "$sum": "$v" }, "adjustedAverage": { "$avg": { "$add": ["$v", "$bonus"] } }, "lo": { "$min": "$v" }, "hi": { "$max": "$v" }, "count": { "$count": {} } } }, { "$sort": { "_id": 1 } } ] }')
$cmd$) AS plan(query_plan)
WHERE query_plan LIKE '%Sort Key:%'
  AND query_plan LIKE '%{ "seq" : { "$numberInt" : "1" } }%';

-- With sortGroup enabled, the dead outer $sort on seq should disappear, but
-- the grouped results should stay identical.
SET blackboxdb.enableSortGroupStage TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "sortgroup_shard_test", "pipeline": [ { "$sort": { "seq": 1 } }, { "$group": { "_id": "$g", "total": { "$sum": "$v" }, "adjustedAverage": { "$avg": { "$add": ["$v", "$bonus"] } }, "lo": { "$min": "$v" }, "hi": { "$max": "$v" }, "count": { "$count": {} } } }, { "$sort": { "_id": 1 } } ] }');
SELECT COUNT(*) AS worker_seq_sort_count
FROM blackboxdb_distributed_test_helpers.run_explain_and_trim($cmd$
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "sortgroup_shard_test", "pipeline": [ { "$sort": { "seq": 1 } }, { "$group": { "_id": "$g", "total": { "$sum": "$v" }, "adjustedAverage": { "$avg": { "$add": ["$v", "$bonus"] } }, "lo": { "$min": "$v" }, "hi": { "$max": "$v" }, "count": { "$count": {} } } }, { "$sort": { "_id": 1 } } ] }')
$cmd$) AS plan(query_plan)
WHERE query_plan LIKE '%Sort Key:%'
  AND query_plan LIKE '%{ "seq" : { "$numberInt" : "1" } }%';

-- $first/$last should NOT be optimized (sort must be preserved)
SET blackboxdb.enableSortGroupStage TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "sortgroup_shard_test", "pipeline": [ { "$sort": { "seq": 1 } }, { "$group": { "_id": "$g", "firstV": { "$first": "$v" }, "lastV": { "$last": "$v" } } }, { "$sort": { "_id": 1 } } ] }');
SELECT COUNT(*) AS worker_seq_sort_count
FROM blackboxdb_distributed_test_helpers.run_explain_and_trim($cmd$
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "sortgroup_shard_test", "pipeline": [ { "$sort": { "seq": 1 } }, { "$group": { "_id": "$g", "firstV": { "$first": "$v" }, "lastV": { "$last": "$v" } } }, { "$sort": { "_id": 1 } } ] }')
$cmd$) AS plan(query_plan)
WHERE query_plan LIKE '%Sort Key:%'
  AND query_plan LIKE '%{ "seq" : { "$numberInt" : "1" } }%';

RESET blackboxdb.enableSortGroupStage;
RESET citus.enable_local_execution;
SELECT blackboxdb_api.drop_collection('db', 'sortgroup_shard_test');

-- =============================================================================
-- Test: reshaping ($project) stage before $group on a sharded collection.
-- The $project makes the accumulator's document argument a computed expression
-- (not the raw stored column), and sharding forces two-phase distributed
-- aggregation (partial aggregate on the shards, combined on the coordinator).
-- The document argument must present a type that exactly matches the WithExpr
-- aggregate signature or the distributed partial aggregation aborts.
-- =============================================================================

SELECT blackboxdb_api.insert_one('db','sumavg_project_group_test','{ "_id": 1, "g": "A", "a": 5, "b": 1 }');
SELECT blackboxdb_api.insert_one('db','sumavg_project_group_test','{ "_id": 2, "g": "A", "a": 7, "b": 2 }');
SELECT blackboxdb_api.insert_one('db','sumavg_project_group_test','{ "_id": 3, "g": "B", "a": 3, "b": 3 }');
SELECT blackboxdb_api.insert_one('db','sumavg_project_group_test','{ "_id": 4, "g": "B", "a": 9, "b": 4 }');

SELECT blackboxdb_api.shard_collection('db', 'sumavg_project_group_test', '{ "_id": "hashed" }', false);

SET blackboxdb.enableNewWithExprAccumulators TO on;
SET citus.enable_local_execution TO off;

-- Global group after a $project: $sum/$avg on a projected field.
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "sumavg_project_group_test", "pipeline": [ { "$project": { "_id": 0, "a": 1, "b": 1 } }, { "$group": { "_id": null, "total": { "$sum": "$a" }, "average": { "$avg": "$a" } } } ] }');

-- Grouped by a non shard-key field after a $project, with a following $sort.
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "sumavg_project_group_test", "pipeline": [ { "$project": { "_id": 0, "g": 1, "a": 1 } }, { "$group": { "_id": "$g", "total": { "$sum": "$a" }, "average": { "$avg": "$a" } } }, { "$sort": { "_id": 1 } } ] }');

-- Accumulator taking an expression argument after a $project.
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "sumavg_project_group_test", "pipeline": [ { "$project": { "_id": 0, "a": 1, "b": 1 } }, { "$group": { "_id": null, "combined": { "$sum": { "$add": ["$a", "$b"] } } } } ] }');

RESET citus.enable_local_execution;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SELECT blackboxdb_api.drop_collection('db', 'sumavg_project_group_test');
