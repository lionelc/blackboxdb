SET search_path TO blackboxdb_api,blackboxdb_core,blackboxdb_api_catalog,blackboxdb_api_internal,public;

SET blackboxdb.next_collection_id TO 1800;
SET blackboxdb.next_collection_index_id TO 1800;
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;

-- 1. Setup test data.
set blackboxdb.defaultUseCompositeOpClass to on;
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "fl_grp_test", "indexes": [ { "key": { "g": 1 }, "name": "g_1" } ] }', true);
SELECT COUNT(blackboxdb_api.insert_one('db', 'fl_grp_test', bson_build_document('_id', i, 'g', chr(65 + (i % 3)), 'v', i * 10, 'seq', i, 'name', concat('name_', i)))) FROM generate_series(1, 1000) AS i;

BEGIN;
set LOCAL enable_seqscan to off;
set LOCAL enable_bitmapscan to off;
set LOCAL enable_hashagg to off;
ANALYZE blackboxdb_data.documents_1801;

-- 2. Without enableSortGroupStage
SET LOCAL blackboxdb.enableSortGroupStage TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "fl_grp_test", "pipeline": [ { "$sort": { "g": 1 } }, { "$group": { "_id": {"g" : "$g"}, "firstVal": { "$first": "$name" }, "total": { "$sum": "$seq" } } } ], "hint": "g_1" }');
EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "fl_grp_test", "pipeline": [ { "$sort": { "g": 1 } }, { "$group": { "_id": {"g" : "$g"}, "firstVal": { "$first": "$name" }, "total": { "$sum": "$seq" } } } ], "hint": "g_1" }');

-- 3. With enableSortGroupStage on
SET LOCAL blackboxdb.enableSortGroupStage TO on;
SET LOCAL blackboxdb.enableSortPushToAccumulatorWithPrefix TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "fl_grp_test", "pipeline": [ { "$sort": { "g": 1 } }, { "$group": { "_id": {"g" : "$g"}, "firstVal": { "$first": "$name" }, "total": { "$sum": "$seq" } } } ], "hint": "g_1" }');
EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "fl_grp_test", "pipeline": [ { "$sort": { "g": 1 } }, { "$group": { "_id": {"g" : "$g"}, "firstVal": { "$first": "$name" }, "total": { "$sum": "$seq" } } } ], "hint": "g_1" }');

-- 4. Sort on v (different from group key g), without enableSortGroupStage
SET LOCAL blackboxdb.enableSortGroupStage TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "fl_grp_test", "pipeline": [ { "$sort": { "v": 1 } }, { "$group": { "_id": {"g" : "$g"}, "firstVal": { "$first": "$name" }, "total": { "$sum": "$seq" } } } ], "hint": "g_1" }');
EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "fl_grp_test", "pipeline": [ { "$sort": { "v": 1 } }, { "$group": { "_id": {"g" : "$g"}, "firstVal": { "$first": "$name" }, "total": { "$sum": "$seq" } } } ], "hint": "g_1" }');

-- 5. Sort on v, with enableSortGroupStage on
SET LOCAL blackboxdb.enableSortGroupStage TO on;
SET LOCAL blackboxdb.enableSortPushToAccumulatorWithPrefix TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "fl_grp_test", "pipeline": [ { "$sort": { "v": 1 } }, { "$group": { "_id": {"g" : "$g"}, "firstVal": { "$first": "$name" }, "total": { "$sum": "$seq" } } } ], "hint": "g_1" }');
EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "fl_grp_test", "pipeline": [ { "$sort": { "v": 1 } }, { "$group": { "_id": {"g" : "$g"}, "firstVal": { "$first": "$name" }, "total": { "$sum": "$seq" } } } ], "hint": "g_1" }');
ROLLBACK;

SELECT blackboxdb_api.drop_collection('db', 'fl_grp_test');
