SET search_path TO blackboxdb_api,blackboxdb_api_catalog,blackboxdb_core;
SET blackboxdb.next_collection_id TO 6700;
SET blackboxdb.next_collection_index_id TO 6700;
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;

SELECT blackboxdb_api.insert_one('db','agg_facet_group_exp','{ "_id": 1, "a": { "b": 1, "c": 1} }', NULL);
SELECT blackboxdb_api.insert_one('db','agg_facet_group_exp','{ "_id": 2, "a": { "b": 1, "c": 2} }', NULL);
SELECT blackboxdb_api.insert_one('db','agg_facet_group_exp','{ "_id": 3, "a": { "b": 1, "c": 3} }', NULL);
SELECT blackboxdb_api.insert_one('db','agg_facet_group_exp','{ "_id": 4, "a": { "b": 2, "c": 1} }', NULL);
SELECT blackboxdb_api.insert_one('db','agg_facet_group_exp','{ "_id": 5, "a": { "b": 2, "c": 2} }', NULL);
SELECT blackboxdb_api.insert_one('db','agg_facet_group_exp','{ "_id": 6, "a": { "b": 2, "c": 3} }', NULL);
SELECT blackboxdb_api.insert_one('db','agg_facet_group_exp','{ "_id": 7, "a": { "b": 3, "c": 1} }', NULL);
SELECT blackboxdb_api.insert_one('db','agg_facet_group_exp','{ "_id": 8, "a": { "b": 3, "c": 2} }', NULL);
SELECT blackboxdb_api.insert_one('db','agg_facet_group_exp','{ "_id": 9, "a": { "b": 3, "c": 3} }', NULL);

-- test non projection for const expressions
EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "agg_facet_group_exp", "pipeline": [ { "$group": { "_id": "1", "c": { "$count": {} }}}]}');
EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "agg_facet_group_exp", "pipeline": [ { "$group": { "_id": 1, "c": { "$sum": 10 }}}]}');
EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "agg_facet_group_exp", "pipeline": [ { "$group": { "_id": 1, "c": { "$max": 10 }}}]}');

SET blackboxdb.enableNewWithExprAccumulators TO on;
EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "agg_facet_group_exp", "pipeline": [ { "$group": { "_id": 1, "c": { "$sum": 10 }}}]}');
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;

SET blackboxdb.enableNewWithExprAccumulators TO on;
EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "agg_facet_group_exp", "pipeline": [ { "$group": { "_id": 1, "c": { "$max": 10 }}}]}');
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;

-- test where only some are non-const
EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "agg_facet_group_exp", "pipeline": [ { "$group": { "_id": 1, "c": { "$max": "$a" }}}]}');

SET blackboxdb.enableNewWithExprAccumulators TO on;
EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "agg_facet_group_exp", "pipeline": [ { "$group": { "_id": 1, "c": { "$max": "$a" }}}]}');
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;

EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "agg_facet_group_exp", "pipeline": [ { "$group": { "_id": "$a", "c": { "$count": {} }}}]}');

-- both are non const
EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "agg_facet_group_exp", "pipeline": [ { "$group": { "_id": "$a", "c": { "$max": "$b" }}}]}');

SET blackboxdb.enableNewWithExprAccumulators TO on;
EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "agg_facet_group_exp", "pipeline": [ { "$group": { "_id": "$a", "c": { "$max": "$b" }}}]}');
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;

-- $sum with non-const expression
EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "agg_facet_group_exp", "pipeline": [ { "$group": { "_id": "$a", "c": { "$sum": "$b" }}}]}');

SET blackboxdb.enableNewWithExprAccumulators TO on;
EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "agg_facet_group_exp", "pipeline": [ { "$group": { "_id": "$a", "c": { "$sum": "$b" }}}]}');
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;

-- $avg with non-const expression
EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "agg_facet_group_exp", "pipeline": [ { "$group": { "_id": "$a", "c": { "$avg": "$b" }}}]}');

SET blackboxdb.enableNewWithExprAccumulators TO on;
EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "agg_facet_group_exp", "pipeline": [ { "$group": { "_id": "$a", "c": { "$avg": "$b" }}}]}');
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;

-- Subquery elimination EXPLAIN tests (using $documents so no collection setup needed)

-- Non-constant _id: subquery eliminated (no Subquery Scan)
EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": 1, "pipeline": [ { "$documents": [ { "a": 1 }, { "a": 2 } ] }, { "$group": { "_id": "$a", "c": { "$count": {} } } } ], "cursor": {}}');

-- Constant _id: subquery eliminated
EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": 1, "pipeline": [ { "$documents": [ { "a": 1 }, { "a": 2 } ] }, { "$group": { "_id": "1", "c": { "$count": {} } } } ], "cursor": {}}');
