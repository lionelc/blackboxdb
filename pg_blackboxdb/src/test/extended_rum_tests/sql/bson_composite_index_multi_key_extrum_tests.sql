SET search_path TO blackboxdb_api,blackboxdb_core,blackboxdb_api_catalog;

SET blackboxdb.next_collection_id TO 1000;
SET blackboxdb.next_collection_index_id TO 1000;

-- now test query path pushdown
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('mkey_db', '{ "createIndexes": "mkey_coll", "indexes": [ { "key": { "a.b": 1, "a.c": 1 }, "name": "a_b_c_1", "enableOrderedIndex": 1 } ] }');

-- multikey path on "a" - query on a.c can't be pushed
SELECT blackboxdb_api.insert_one('mkey_db', 'mkey_coll', '{ "_id": 1, "a": [ { "b": 1, "c": 1 }, { "b": 2, "c": 2 }] }');

set blackboxdb.enableExtendedExplainPlans to on;
SELECT blackboxdb_test_helpers.run_explain_and_trim( $cmd$
    EXPLAIN (COSTS OFF, ANALYZE ON, SUMMARY OFF, TIMING OFF, BUFFERS OFF) SELECT document FROM bson_aggregation_find('mkey_db', '{ "find": "mkey_coll", "filter": { "a.b": { "$gt": 0 }, "a.c": 2 }}') $cmd$);

SELECT blackboxdb_test_helpers.run_explain_and_trim( $cmd$
    EXPLAIN (COSTS OFF, ANALYZE ON, SUMMARY OFF, TIMING OFF, BUFFERS OFF) SELECT document FROM bson_aggregation_find('mkey_db', '{ "find": "mkey_coll", "filter": { "a.b": 1, "a.c": 2 }}') $cmd$);

-- order by doesn't work on secondary path (but works on the first one)
SELECT blackboxdb_test_helpers.run_explain_and_trim($cmd$
    EXPLAIN (COSTS OFF, ANALYZE ON, SUMMARY OFF, TIMING OFF, BUFFERS OFF) SELECT document FROM bson_aggregation_find('mkey_db', '{ "find": "mkey_coll", "filter": { "a.b": { "$exists": true } }, "sort": { "a.b": 1, "a.c": 1 }, "hint": "a_b_c_1" }') $cmd$);

SELECT blackboxdb_test_helpers.run_explain_and_trim( $cmd$
    EXPLAIN (COSTS OFF, ANALYZE ON, SUMMARY OFF, TIMING OFF, BUFFERS OFF) SELECT document FROM bson_aggregation_find('mkey_db', '{ "find": "mkey_coll", "filter": { "a.b": { "$exists": true } }, "sort": { "a.b": -1 }, "hint": "a_b_c_1" }') $cmd$);

-- multikey on a.b - query on a.c can be pushed
TRUNCATE blackboxdb_data.documents_801;

SELECT blackboxdb_api.insert_one('mkey_db', 'mkey_coll', '{ "_id": 1, "a": { "b": [ 1, 2 ], "c": 2 } }');
SELECT blackboxdb_test_helpers.run_explain_and_trim( $cmd$
    EXPLAIN (COSTS OFF, ANALYZE ON, SUMMARY OFF, TIMING OFF, BUFFERS OFF) SELECT document FROM bson_aggregation_find('mkey_db', '{ "find": "mkey_coll", "filter": { "a.b": { "$gt": 0 }, "a.c": 2 }}') $cmd$);

SELECT blackboxdb_test_helpers.run_explain_and_trim( $cmd$
    EXPLAIN (COSTS OFF, ANALYZE ON, SUMMARY OFF, TIMING OFF, BUFFERS OFF) SELECT document FROM bson_aggregation_find('mkey_db', '{ "find": "mkey_coll", "filter": { "a.b": 1, "a.c": 2 }}') $cmd$);

-- same behavior for order by.
SELECT blackboxdb_test_helpers.run_explain_and_trim($cmd$
    EXPLAIN (COSTS OFF, ANALYZE ON, SUMMARY OFF, TIMING OFF, BUFFERS OFF) SELECT document FROM bson_aggregation_find('mkey_db', '{ "find": "mkey_coll", "filter": { "a.b": { "$exists": true } }, "sort": { "a.b": 1, "a.c": 1 }, "hint": "a_b_c_1" }') $cmd$);

SELECT blackboxdb_test_helpers.run_explain_and_trim( $cmd$
    EXPLAIN (COSTS OFF, ANALYZE ON, SUMMARY OFF, TIMING OFF, BUFFERS OFF) SELECT document FROM bson_aggregation_find('mkey_db', '{ "find": "mkey_coll", "filter": { "a.b": { "$exists": true } }, "sort": { "a.b": -1 }, "hint": "a_b_c_1" }') $cmd$);
