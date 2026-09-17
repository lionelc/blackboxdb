SET search_path TO blackboxdb_api,blackboxdb_api_catalog,blackboxdb_api_internal,blackboxdb_core;

SET citus.next_shard_id TO 687000;
SET blackboxdb.next_collection_id TO 68700;
SET blackboxdb.next_collection_index_id TO 68700;

set blackboxdb.enableExtendedExplainPlans to on;

-- if blackboxdb_extended_rum exists, set alternate index handler
SELECT pg_catalog.set_config('blackboxdb.alternate_index_handler_name', 'extended_rum', false), extname FROM pg_extension WHERE extname = 'blackboxdb_extended_rum';


SELECT blackboxdb_api.drop_collection('comp_pfe', 'query_orderby_pfe') IS NOT NULL;
SELECT blackboxdb_api.create_collection('comp_pfe', 'query_orderby_pfe');

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('comp_pfe', 
    '{ "createIndexes": "query_orderby_pfe", "indexes": [ 
        { "key": { "b": 1 }, "storageEngine": { "enableCompositeTerm": true }, "name": "b_1", "partialFilterExpression": { "pfe_a": { "$gt": 10 } } },
        { "key": { "d": 1 }, "storageEngine": { "enableCompositeTerm": true }, "name": "d_1", "partialFilterExpression": { "pfe_a": { "$eq": 10 } } },
        { "key": { "e": 1 }, "storageEngine": { "enableCompositeTerm": true }, "name": "e_1", "partialFilterExpression": { "e": { "$eq": 10 } } },
        { "key": { "f": 1 }, "storageEngine": { "enableCompositeTerm": true }, "name": "f_1", "partialFilterExpression": { "f": { "$gt": 10 } } },
        { "key": { "g": 1, "h": 1, "i": 1 }, "storageEngine": { "enableCompositeTerm": true }, "name": "ghi_1", "partialFilterExpression": { "h": { "$eq": 10 } } }
    ] }', true);

\d blackboxdb_data.documents_68701

-- now insert some sample docs
SELECT COUNT(blackboxdb_api.insert_one('comp_pfe', 'query_orderby_pfe',
    bson_build_document('_id'::text, i, 'a'::text, i, 'b'::text, i, 'c'::text, i, 'd'::text, i,
                        'e'::text, i, 'f'::text, i, 'g'::text, i, 'h'::text, i, 'i'::text, i, 'pfe_a'::text, i, 'pfe_b'::text, i)))
        FROM generate_series(1, 100) i;


ANALYZE blackboxdb_data.documents_68701;

set enable_seqscan to off;

-- cannot push down
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('comp_pfe', '{ "find": "query_orderby_pfe", "filter": { "b": 1 } }');
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('comp_pfe', '{ "find": "query_orderby_pfe", "filter": { "b": 1, "pfe_a": 5 } }');
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('comp_pfe', '{ "find": "query_orderby_pfe", "filter": { "d": 1, "pfe_a": 15 } }');
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('comp_pfe', '{ "find": "query_orderby_pfe", "filter": { "e": 15 } }');
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('comp_pfe', '{ "find": "query_orderby_pfe", "filter": { "f": 10 } }');
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('comp_pfe', '{ "find": "query_orderby_pfe", "filter": { "g": { "$gt": 10 } } }');
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('comp_pfe', '{ "find": "query_orderby_pfe", "filter": { "g": { "$gt": 10 }, "h": 11 } }');
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('comp_pfe', '{ "find": "query_orderby_pfe", "filter": { "g": { "$gt": 10 }, "h": 11, "i": { "$gt": 15 } } }');

-- can push
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('comp_pfe', '{ "find": "query_orderby_pfe", "filter": { "b": 1, "pfe_a": 15 } }');
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('comp_pfe', '{ "find": "query_orderby_pfe", "filter": { "d": 10, "pfe_a": 10 } }');
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('comp_pfe', '{ "find": "query_orderby_pfe", "filter": { "e": 10 } }');
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('comp_pfe', '{ "find": "query_orderby_pfe", "filter": { "f": 20 } }');
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('comp_pfe', '{ "find": "query_orderby_pfe", "filter": { "f": { "$gt": 10 } } }');
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('comp_pfe', '{ "find": "query_orderby_pfe", "filter": { "g": { "$gt": 10 }, "h": 10 } }');
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('comp_pfe', '{ "find": "query_orderby_pfe", "filter": { "g": { "$gt": 10 }, "h": 10, "i": { "$gt": 15 } } }');

-- retry the same ones with order by on the index fields 
EXPLAIN (COSTS OFF, ANALYZE ON, TIMING OFF, SUMMARY OFF) SELECT document FROM bson_aggregation_find('comp_pfe', '{ "find": "query_orderby_pfe", "filter": { "b": 1, "pfe_a": 15 }, "sort": { "b": 1 } }');
EXPLAIN (COSTS OFF, ANALYZE ON, TIMING OFF, SUMMARY OFF) SELECT document FROM bson_aggregation_find('comp_pfe', '{ "find": "query_orderby_pfe", "filter": { "d": 10, "pfe_a": 10 }, "sort": { "d": 1 } }');
EXPLAIN (COSTS OFF, ANALYZE ON, TIMING OFF, SUMMARY OFF) SELECT document FROM bson_aggregation_find('comp_pfe', '{ "find": "query_orderby_pfe", "filter": { "f": 20 }, "sort": { "f": 1 } }');
EXPLAIN (COSTS OFF, ANALYZE ON, TIMING OFF, SUMMARY OFF) SELECT document FROM bson_aggregation_find('comp_pfe', '{ "find": "query_orderby_pfe", "filter": { "f": { "$gt": 10 } }, "sort": { "f": 1 } }');
EXPLAIN (COSTS OFF, ANALYZE ON, TIMING OFF, SUMMARY OFF) SELECT document FROM bson_aggregation_find('comp_pfe', '{ "find": "query_orderby_pfe", "filter": { "g": { "$gt": 10 }, "h": 10 }, "sort": { "g": 1 } }');
EXPLAIN (COSTS OFF, ANALYZE ON, TIMING OFF, SUMMARY OFF) SELECT document FROM bson_aggregation_find('comp_pfe', '{ "find": "query_orderby_pfe", "filter": { "g": { "$gt": 10 }, "h": 10, "i": { "$gt": 15 } }, "sort": { "g": 1 } }');

BEGIN;
set local enable_bitmapscan to off;
set local enable_seqscan to off;
EXPLAIN (COSTS OFF, ANALYZE ON, TIMING OFF, SUMMARY OFF) SELECT document FROM bson_aggregation_find('comp_pfe', '{ "find": "query_orderby_pfe", "filter": { "e": 10 }, "sort": { "e": 1 } }');
ROLLBACK;

BEGIN;
set local enable_bitmapscan to off;
set local enable_seqscan to off;
EXPLAIN (COSTS OFF, ANALYZE ON, TIMING OFF, SUMMARY OFF) SELECT document FROM bson_aggregation_find('comp_pfe', '{ "find": "query_orderby_pfe", "filter": { "f": { "$gt": 10 } }, "sort": { "f": 1 } }');
ROLLBACK;

-- this can be pushed since h is part of the PFE.
EXPLAIN (COSTS OFF, ANALYZE ON, TIMING OFF, SUMMARY OFF) SELECT document FROM bson_aggregation_find('comp_pfe', '{ "find": "query_orderby_pfe", "filter": { "g": 10, "h": 10, "i": { "$gt": 15 } }, "sort": { "i": 1 } }');