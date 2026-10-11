SET search_path TO blackboxdb_api,blackboxdb_core,blackboxdb_api_catalog;

SET blackboxdb.next_collection_id TO 26890000;
SET blackboxdb.next_collection_index_id TO 26890000;

-- 40 orders with a state, a territory and 0 to 3 items; every 10th order has no items field.
DO $$
DECLARE i int;
BEGIN
FOR i IN 1..40 LOOP
PERFORM blackboxdb_api.insert_one('unwinddb', 'orders', FORMAT('{ "_id": %s, "state": "%s", "territory": %s, %s }', i,
    (ARRAY['won', 'lost', 'open'])[1 + i % 3], i % 4,
    CASE WHEN i % 10 = 0 THEN '"note": "no items"'
         ELSE FORMAT('"items": [%s]', (SELECT string_agg(FORMAT('{ "p": %s, "q": %s }', (i * 7 + j) % 5, (i + j) % 9), ', ') FROM generate_series(1, i % 4) j)) END)::blackboxdb_core.bson);
END LOOP;
END;
$$;

-- Each query runs with the rewrite off and then on; the results must be identical.

-- An independent $match after $unwind, with a $group.
SET blackboxdb.enable_match_before_unwind TO off;
SELECT document FROM bson_aggregation_pipeline('unwinddb', '{ "aggregate": "orders", "pipeline": [ { "$unwind": "$items" }, { "$match": { "state": "won" } }, { "$group": { "_id": "$items.p", "n": { "$sum": 1 }, "q": { "$sum": "$items.q" } } }, { "$sort": { "_id": 1 } } ], "cursor": {} }');
SET blackboxdb.enable_match_before_unwind TO on;
SELECT document FROM bson_aggregation_pipeline('unwinddb', '{ "aggregate": "orders", "pipeline": [ { "$unwind": "$items" }, { "$match": { "state": "won" } }, { "$group": { "_id": "$items.p", "n": { "$sum": 1 }, "q": { "$sum": "$items.q" } } }, { "$sort": { "_id": 1 } } ], "cursor": {} }');

-- preserveNullAndEmptyArrays keeps documents with an empty or missing array.
SET blackboxdb.enable_match_before_unwind TO off;
SELECT document FROM bson_aggregation_pipeline('unwinddb', '{ "aggregate": "orders", "pipeline": [ { "$unwind": { "path": "$items", "preserveNullAndEmptyArrays": true } }, { "$match": { "territory": 2 } }, { "$project": { "_id": 1, "items": 1 } }, { "$sort": { "_id": 1, "items.p": 1 } } ], "cursor": {} }');
SET blackboxdb.enable_match_before_unwind TO on;
SELECT document FROM bson_aggregation_pipeline('unwinddb', '{ "aggregate": "orders", "pipeline": [ { "$unwind": { "path": "$items", "preserveNullAndEmptyArrays": true } }, { "$match": { "territory": 2 } }, { "$project": { "_id": 1, "items": 1 } }, { "$sort": { "_id": 1, "items.p": 1 } } ], "cursor": {} }');

-- Two independent $match stages in a row.
SET blackboxdb.enable_match_before_unwind TO off;
SELECT document FROM bson_aggregation_pipeline('unwinddb', '{ "aggregate": "orders", "pipeline": [ { "$unwind": "$items" }, { "$match": { "state": "won" } }, { "$match": { "territory": { "$gte": 1 } } }, { "$count": "rows" } ], "cursor": {} }');
SET blackboxdb.enable_match_before_unwind TO on;
SELECT document FROM bson_aggregation_pipeline('unwinddb', '{ "aggregate": "orders", "pipeline": [ { "$unwind": "$items" }, { "$match": { "state": "won" } }, { "$match": { "territory": { "$gte": 1 } } }, { "$count": "rows" } ], "cursor": {} }');

-- A $match on _id.
SET blackboxdb.enable_match_before_unwind TO off;
SELECT document FROM bson_aggregation_pipeline('unwinddb', '{ "aggregate": "orders", "pipeline": [ { "$unwind": "$items" }, { "$match": { "_id": { "$in": [ 1, 2, 3, 5 ] } } }, { "$sort": { "_id": 1, "items.p": 1 } } ], "cursor": {} }');
SET blackboxdb.enable_match_before_unwind TO on;
SELECT document FROM bson_aggregation_pipeline('unwinddb', '{ "aggregate": "orders", "pipeline": [ { "$unwind": "$items" }, { "$match": { "_id": { "$in": [ 1, 2, 3, 5 ] } } }, { "$sort": { "_id": 1, "items.p": 1 } } ], "cursor": {} }');

-- Not moved: a $match on the unwound field.
SET blackboxdb.enable_match_before_unwind TO off;
SELECT document FROM bson_aggregation_pipeline('unwinddb', '{ "aggregate": "orders", "pipeline": [ { "$unwind": "$items" }, { "$match": { "items.q": { "$gte": 5 } } }, { "$sort": { "_id": 1, "items.p": 1 } } ], "cursor": {} }');
SET blackboxdb.enable_match_before_unwind TO on;
SELECT document FROM bson_aggregation_pipeline('unwinddb', '{ "aggregate": "orders", "pipeline": [ { "$unwind": "$items" }, { "$match": { "items.q": { "$gte": 5 } } }, { "$sort": { "_id": 1, "items.p": 1 } } ], "cursor": {} }');

-- Not moved: a $match on the includeArrayIndex field.
SET blackboxdb.enable_match_before_unwind TO off;
SELECT document FROM bson_aggregation_pipeline('unwinddb', '{ "aggregate": "orders", "pipeline": [ { "$unwind": { "path": "$items", "includeArrayIndex": "pos" } }, { "$match": { "pos": 0 } }, { "$project": { "_id": 1, "pos": 1, "items.p": 1 } }, { "$sort": { "_id": 1 } } ], "cursor": {} }');
SET blackboxdb.enable_match_before_unwind TO on;
SELECT document FROM bson_aggregation_pipeline('unwinddb', '{ "aggregate": "orders", "pipeline": [ { "$unwind": { "path": "$items", "includeArrayIndex": "pos" } }, { "$match": { "pos": 0 } }, { "$project": { "_id": 1, "pos": 1, "items.p": 1 } }, { "$sort": { "_id": 1 } } ], "cursor": {} }');

-- Not moved: $expr on the unwound field.
SET blackboxdb.enable_match_before_unwind TO off;
SELECT document FROM bson_aggregation_pipeline('unwinddb', '{ "aggregate": "orders", "pipeline": [ { "$unwind": "$items" }, { "$match": { "$expr": { "$gte": [ "$items.q", 5 ] } } }, { "$sort": { "_id": 1, "items.p": 1 } } ], "cursor": {} }');
SET blackboxdb.enable_match_before_unwind TO on;
SELECT document FROM bson_aggregation_pipeline('unwinddb', '{ "aggregate": "orders", "pipeline": [ { "$unwind": "$items" }, { "$match": { "$expr": { "$gte": [ "$items.q", 5 ] } } }, { "$sort": { "_id": 1, "items.p": 1 } } ], "cursor": {} }');

-- Not moved: a top-level $or.
SET blackboxdb.enable_match_before_unwind TO off;
SELECT document FROM bson_aggregation_pipeline('unwinddb', '{ "aggregate": "orders", "pipeline": [ { "$unwind": "$items" }, { "$match": { "$or": [ { "state": "won" }, { "territory": 3 } ] } }, { "$count": "rows" } ], "cursor": {} }');
SET blackboxdb.enable_match_before_unwind TO on;
SELECT document FROM bson_aggregation_pipeline('unwinddb', '{ "aggregate": "orders", "pipeline": [ { "$unwind": "$items" }, { "$match": { "$or": [ { "state": "won" }, { "territory": 3 } ] } }, { "$count": "rows" } ], "cursor": {} }');

-- An independent $match followed by a dependent one: only the first moves.
SET blackboxdb.enable_match_before_unwind TO off;
SELECT document FROM bson_aggregation_pipeline('unwinddb', '{ "aggregate": "orders", "pipeline": [ { "$unwind": "$items" }, { "$match": { "state": "lost" } }, { "$match": { "items.q": { "$lt": 3 } } }, { "$sort": { "_id": 1, "items.p": 1 } } ], "cursor": {} }');
SET blackboxdb.enable_match_before_unwind TO on;
SELECT document FROM bson_aggregation_pipeline('unwinddb', '{ "aggregate": "orders", "pipeline": [ { "$unwind": "$items" }, { "$match": { "state": "lost" } }, { "$match": { "items.q": { "$lt": 3 } } }, { "$sort": { "_id": 1, "items.p": 1 } } ], "cursor": {} }');

-- Sub-pipelines in $facet and $lookup.
SET blackboxdb.enable_match_before_unwind TO off;
SELECT document FROM bson_aggregation_pipeline('unwinddb', '{ "aggregate": "orders", "pipeline": [ { "$facet": { "won": [ { "$unwind": "$items" }, { "$match": { "state": "won" } }, { "$count": "rows" } ] } } ], "cursor": {} }');
SET blackboxdb.enable_match_before_unwind TO on;
SELECT document FROM bson_aggregation_pipeline('unwinddb', '{ "aggregate": "orders", "pipeline": [ { "$facet": { "won": [ { "$unwind": "$items" }, { "$match": { "state": "won" } }, { "$count": "rows" } ] } } ], "cursor": {} }');

SET blackboxdb.enable_match_before_unwind TO off;
SELECT document FROM bson_aggregation_pipeline('unwinddb', '{ "aggregate": "orders", "pipeline": [ { "$match": { "_id": 1 } }, { "$lookup": { "from": "orders", "pipeline": [ { "$unwind": "$items" }, { "$match": { "territory": 1 } }, { "$count": "rows" } ], "as": "t1" } }, { "$project": { "_id": 1, "t1": 1 } } ], "cursor": {} }');
SET blackboxdb.enable_match_before_unwind TO on;
SELECT document FROM bson_aggregation_pipeline('unwinddb', '{ "aggregate": "orders", "pipeline": [ { "$match": { "_id": 1 } }, { "$lookup": { "from": "orders", "pipeline": [ { "$unwind": "$items" }, { "$match": { "territory": 1 } }, { "$count": "rows" } ], "as": "t1" } }, { "$project": { "_id": 1, "t1": 1 } } ], "cursor": {} }');

-- An invalid $match keeps its error.
SET blackboxdb.enable_match_before_unwind TO off;
SELECT document FROM bson_aggregation_pipeline('unwinddb', '{ "aggregate": "orders", "pipeline": [ { "$unwind": "$items" }, { "$match": { "state": { "$bogus": 1 } } } ], "cursor": {} }');
SET blackboxdb.enable_match_before_unwind TO on;
SELECT document FROM bson_aggregation_pipeline('unwinddb', '{ "aggregate": "orders", "pipeline": [ { "$unwind": "$items" }, { "$match": { "state": { "$bogus": 1 } } } ], "cursor": {} }');

-- With the rewrite the $unwind only expands the documents that pass the filter.
CREATE FUNCTION match_before_unwind_rows(pipeline text) RETURNS bigint AS $$
DECLARE line text; m text[];
BEGIN
    FOR line IN EXECUTE 'EXPLAIN (ANALYZE ON, COSTS OFF, TIMING OFF, SUMMARY OFF) SELECT document FROM bson_aggregation_pipeline(''unwinddb'', ' || quote_literal(pipeline) || '::bson)'
    LOOP
        m := regexp_match(line, 'ProjectSet \(actual rows=(\d+)');
        IF m IS NOT NULL THEN
            RETURN m[1]::bigint;
        END IF;
    END LOOP;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

SET blackboxdb.enable_match_before_unwind TO off;
SELECT match_before_unwind_rows('{ "aggregate": "orders", "pipeline": [ { "$unwind": "$items" }, { "$match": { "state": "won" } }, { "$count": "rows" } ], "cursor": {} }') AS unwound_rows_off;
SET blackboxdb.enable_match_before_unwind TO on;
SELECT match_before_unwind_rows('{ "aggregate": "orders", "pipeline": [ { "$unwind": "$items" }, { "$match": { "state": "won" } }, { "$count": "rows" } ], "cursor": {} }') AS unwound_rows_on;

DROP FUNCTION match_before_unwind_rows(text);
RESET blackboxdb.enable_match_before_unwind;
