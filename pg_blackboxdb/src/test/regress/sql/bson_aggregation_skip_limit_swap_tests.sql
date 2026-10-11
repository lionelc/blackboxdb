SET search_path TO blackboxdb_api,blackboxdb_core,blackboxdb_api_catalog;

SET blackboxdb.next_collection_id TO 25880000;
SET blackboxdb.next_collection_index_id TO 25880000;

-- 100 documents: k is a unique sort key (a permutation of 0..99), g a group key.
DO $$
DECLARE i int;
BEGIN
FOR i IN 0..99 LOOP
PERFORM blackboxdb_api.insert_one('skiplimitdb', 'pages', FORMAT('{ "_id": %s, "k": %s, "g": %s }', i, (i * 37) % 100, i % 4)::blackboxdb_core.bson);
END LOOP;
END;
$$;

-- Each query runs with the rewrite off and then on; the results must be identical.
SET blackboxdb.enable_skip_limit_swap TO off;
SELECT document FROM bson_aggregation_pipeline('skiplimitdb', '{ "aggregate": "pages", "pipeline": [ { "$sort": { "k": 1 } }, { "$skip": 10 }, { "$limit": 5 }, { "$project": { "_id": 0, "k": 1 } } ], "cursor": {} }');
SET blackboxdb.enable_skip_limit_swap TO on;
SELECT document FROM bson_aggregation_pipeline('skiplimitdb', '{ "aggregate": "pages", "pipeline": [ { "$sort": { "k": 1 } }, { "$skip": 10 }, { "$limit": 5 }, { "$project": { "_id": 0, "k": 1 } } ], "cursor": {} }');

-- Descending, compound sort key, and a filter before the sort.
SET blackboxdb.enable_skip_limit_swap TO off;
SELECT document FROM bson_aggregation_pipeline('skiplimitdb', '{ "aggregate": "pages", "pipeline": [ { "$sort": { "k": -1 } }, { "$skip": 3 }, { "$limit": 4 } ], "cursor": {} }');
SELECT document FROM bson_aggregation_pipeline('skiplimitdb', '{ "aggregate": "pages", "pipeline": [ { "$sort": { "g": 1, "k": 1 } }, { "$skip": 23 }, { "$limit": 4 } ], "cursor": {} }');
SELECT document FROM bson_aggregation_pipeline('skiplimitdb', '{ "aggregate": "pages", "pipeline": [ { "$match": { "g": { "$gte": 2 } } }, { "$sort": { "k": 1 } }, { "$skip": 7 }, { "$limit": 3 } ], "cursor": {} }');
SET blackboxdb.enable_skip_limit_swap TO on;
SELECT document FROM bson_aggregation_pipeline('skiplimitdb', '{ "aggregate": "pages", "pipeline": [ { "$sort": { "k": -1 } }, { "$skip": 3 }, { "$limit": 4 } ], "cursor": {} }');
SELECT document FROM bson_aggregation_pipeline('skiplimitdb', '{ "aggregate": "pages", "pipeline": [ { "$sort": { "g": 1, "k": 1 } }, { "$skip": 23 }, { "$limit": 4 } ], "cursor": {} }');
SELECT document FROM bson_aggregation_pipeline('skiplimitdb', '{ "aggregate": "pages", "pipeline": [ { "$match": { "g": { "$gte": 2 } } }, { "$sort": { "k": 1 } }, { "$skip": 7 }, { "$limit": 3 } ], "cursor": {} }');

-- Chains: $skip, $limit, $limit; $skip, $skip, $limit; $limit before $skip (not rewritten); numeric types.
SET blackboxdb.enable_skip_limit_swap TO off;
SELECT document FROM bson_aggregation_pipeline('skiplimitdb', '{ "aggregate": "pages", "pipeline": [ { "$sort": { "k": 1 } }, { "$skip": 3 }, { "$limit": 10 }, { "$limit": 4 }, { "$project": { "_id": 0, "k": 1 } } ], "cursor": {} }');
SELECT document FROM bson_aggregation_pipeline('skiplimitdb', '{ "aggregate": "pages", "pipeline": [ { "$sort": { "k": 1 } }, { "$skip": 2 }, { "$skip": 3 }, { "$limit": 4 }, { "$project": { "_id": 0, "k": 1 } } ], "cursor": {} }');
SELECT document FROM bson_aggregation_pipeline('skiplimitdb', '{ "aggregate": "pages", "pipeline": [ { "$sort": { "k": 1 } }, { "$limit": 10 }, { "$skip": 8 }, { "$project": { "_id": 0, "k": 1 } } ], "cursor": {} }');
SELECT document FROM bson_aggregation_pipeline('skiplimitdb', '{ "aggregate": "pages", "pipeline": [ { "$sort": { "k": 1 } }, { "$skip": { "$numberLong": "95" } }, { "$limit": 10.0 }, { "$project": { "_id": 0, "k": 1 } } ], "cursor": {} }');
SET blackboxdb.enable_skip_limit_swap TO on;
SELECT document FROM bson_aggregation_pipeline('skiplimitdb', '{ "aggregate": "pages", "pipeline": [ { "$sort": { "k": 1 } }, { "$skip": 3 }, { "$limit": 10 }, { "$limit": 4 }, { "$project": { "_id": 0, "k": 1 } } ], "cursor": {} }');
SELECT document FROM bson_aggregation_pipeline('skiplimitdb', '{ "aggregate": "pages", "pipeline": [ { "$sort": { "k": 1 } }, { "$skip": 2 }, { "$skip": 3 }, { "$limit": 4 }, { "$project": { "_id": 0, "k": 1 } } ], "cursor": {} }');
SELECT document FROM bson_aggregation_pipeline('skiplimitdb', '{ "aggregate": "pages", "pipeline": [ { "$sort": { "k": 1 } }, { "$limit": 10 }, { "$skip": 8 }, { "$project": { "_id": 0, "k": 1 } } ], "cursor": {} }');
SELECT document FROM bson_aggregation_pipeline('skiplimitdb', '{ "aggregate": "pages", "pipeline": [ { "$sort": { "k": 1 } }, { "$skip": { "$numberLong": "95" } }, { "$limit": 10.0 }, { "$project": { "_id": 0, "k": 1 } } ], "cursor": {} }');

-- Sub-pipelines in $facet and $lookup.
SET blackboxdb.enable_skip_limit_swap TO off;
SELECT document FROM bson_aggregation_pipeline('skiplimitdb', '{ "aggregate": "pages", "pipeline": [ { "$facet": { "page": [ { "$sort": { "k": 1 } }, { "$skip": 50 }, { "$limit": 2 }, { "$project": { "_id": 0, "k": 1 } } ] } } ], "cursor": {} }');
SELECT document FROM bson_aggregation_pipeline('skiplimitdb', '{ "aggregate": "pages", "pipeline": [ { "$match": { "_id": 0 } }, { "$lookup": { "from": "pages", "pipeline": [ { "$sort": { "k": -1 } }, { "$skip": 1 }, { "$limit": 2 }, { "$project": { "_id": 0, "k": 1 } } ], "as": "top" } }, { "$project": { "_id": 1, "top": 1 } } ], "cursor": {} }');
SET blackboxdb.enable_skip_limit_swap TO on;
SELECT document FROM bson_aggregation_pipeline('skiplimitdb', '{ "aggregate": "pages", "pipeline": [ { "$facet": { "page": [ { "$sort": { "k": 1 } }, { "$skip": 50 }, { "$limit": 2 }, { "$project": { "_id": 0, "k": 1 } } ] } } ], "cursor": {} }');
SELECT document FROM bson_aggregation_pipeline('skiplimitdb', '{ "aggregate": "pages", "pipeline": [ { "$match": { "_id": 0 } }, { "$lookup": { "from": "pages", "pipeline": [ { "$sort": { "k": -1 } }, { "$skip": 1 }, { "$limit": 2 }, { "$project": { "_id": 0, "k": 1 } } ], "as": "top" } }, { "$project": { "_id": 1, "top": 1 } } ], "cursor": {} }');

-- Values that are not rewritten keep their original behavior and errors.
SET blackboxdb.enable_skip_limit_swap TO on;
SELECT document FROM bson_aggregation_pipeline('skiplimitdb', '{ "aggregate": "pages", "pipeline": [ { "$sort": { "k": 1 } }, { "$skip": 9223372036854775807 }, { "$limit": 10 } ], "cursor": {} }');
SELECT document FROM bson_aggregation_pipeline('skiplimitdb', '{ "aggregate": "pages", "pipeline": [ { "$sort": { "k": 1 } }, { "$skip": -1 }, { "$limit": 10 } ], "cursor": {} }');
SELECT document FROM bson_aggregation_pipeline('skiplimitdb', '{ "aggregate": "pages", "pipeline": [ { "$sort": { "k": 1 } }, { "$skip": 1.5 }, { "$limit": 10 } ], "cursor": {} }');
SELECT document FROM bson_aggregation_pipeline('skiplimitdb', '{ "aggregate": "pages", "pipeline": [ { "$sort": { "k": 1 } }, { "$skip": 5 }, { "$limit": 0 } ], "cursor": {} }');
SELECT document FROM bson_aggregation_pipeline('skiplimitdb', '{ "aggregate": "pages", "pipeline": [ { "$sort": { "k": 1 } }, { "$skip": 5 }, { "$limit": -2 } ], "cursor": {} }');
SELECT document FROM bson_aggregation_pipeline('skiplimitdb', '{ "aggregate": "pages", "pipeline": [ { "$sort": { "k": 1 } }, { "$skip": 5 }, { "$limit": "a" } ], "cursor": {} }');
SELECT document FROM bson_aggregation_pipeline('skiplimitdb', '{ "aggregate": "pages", "pipeline": [ { "$sort": { "k": 1 } }, { "$skip": 0 }, { "$limit": 2 }, { "$project": { "_id": 0, "k": 1 } } ], "cursor": {} }');
SELECT document FROM bson_aggregation_pipeline('skiplimitdb', '{ "aggregate": "pages", "pipeline": [ { "$sort": { "k": 1 } }, { "$skip": 5 }, { "$limit": 2.5 } ], "cursor": {} }');
SELECT document FROM bson_aggregation_pipeline('skiplimitdb', '{ "aggregate": "pages", "pipeline": [ { "$sort": { "k": 1 } }, { "$skip": "a" }, { "$limit": 10 } ], "cursor": {} }');

-- The sort is bounded with the rewrite: top-N heapsort instead of a full sort.
CREATE FUNCTION skip_limit_swap_plan_lines(pipeline text) RETURNS SETOF text AS $$
DECLARE line text;
BEGIN
    FOR line IN EXECUTE 'EXPLAIN (ANALYZE ON, COSTS OFF, TIMING OFF, SUMMARY OFF) SELECT document FROM bson_aggregation_pipeline(''skiplimitdb'', ' || quote_literal(pipeline) || '::bson)'
    LOOP
        RETURN NEXT line;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

SET blackboxdb.enable_skip_limit_swap TO off;
SELECT bool_or(l LIKE '%Sort Method: top-N heapsort%') AS bounded_sort FROM skip_limit_swap_plan_lines('{ "aggregate": "pages", "pipeline": [ { "$sort": { "k": 1 } }, { "$skip": 10 }, { "$limit": 5 } ], "cursor": {} }') l;
SET blackboxdb.enable_skip_limit_swap TO on;
SELECT bool_or(l LIKE '%Sort Method: top-N heapsort%') AS bounded_sort FROM skip_limit_swap_plan_lines('{ "aggregate": "pages", "pipeline": [ { "$sort": { "k": 1 } }, { "$skip": 10 }, { "$limit": 5 } ], "cursor": {} }') l;

DROP FUNCTION skip_limit_swap_plan_lines(text);
RESET blackboxdb.enable_skip_limit_swap;
