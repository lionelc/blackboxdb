SET search_path TO blackboxdb_api, blackboxdb_api_catalog, blackboxdb_api_internal, blackboxdb_core, public;
SET blackboxdb.next_collection_id TO 1400;
SET blackboxdb.next_collection_index_id TO 1400;


SELECT COUNT(blackboxdb_api.insert_one('pinsert_db', 'pbuild',  FORMAT('{ "_id": %s, "a": %s }', i, i)::bson)) FROM generate_series(1, 1000) AS i;

set blackboxdb_rum.parallel_index_workers_override to 2;
set blackboxdb_rum.enable_parallel_index_build to on;

set client_min_messages to DEBUG1;
SELECT blackboxdb_api_internal.create_indexes_non_concurrently(
    'pinsert_db',
    '{ "createIndexes": "pbuild", "indexes": [ { "key": { "a": 1 }, "name": "a_1", "enableCompositeTerm": true } ] }', TRUE);

RESET client_min_messages;

-- recreate to test with int64
CALL blackboxdb_api.drop_indexes('pinsert_db', '{ "dropIndexes": "pbuild", "index": "a_1" }');

-- insert the same value as Int64
SELECT COUNT(blackboxdb_api.insert_one('pinsert_db', 'pbuild',  FORMAT('{ "_id": %s, "a": { "$numberLong": "%s" } }', i + 1000, i)::bson)) FROM generate_series(1, 1000) AS i;

-- insert the same as double
SELECT COUNT(blackboxdb_api.insert_one('pinsert_db', 'pbuild',  FORMAT('{ "_id": %s, "a": { "$numberDouble": "%s" } }', i + 2000, i)::bson)) FROM generate_series(1, 1000) AS i;

SELECT blackboxdb_api_internal.create_indexes_non_concurrently(
    'pinsert_db',
    '{ "createIndexes": "pbuild", "indexes": [ { "key": { "a": 1 }, "name": "a_1", "enableCompositeTerm": true } ] }', TRUE);

-- use the index.
set blackboxdb.enableExtendedExplainPlans to on;
SELECT blackboxdb_test_helpers.run_explain_and_trim($$
    EXPLAIN (COSTS OFF, ANALYZE ON, VERBOSE OFF, BUFFERS OFF, SUMMARY OFF, TIMING OFF) SELECT document FROM bson_aggregation_count('pinsert_db', '{ "count": "pbuild", "query": { "a": { "$gt": 500 } } }');
$$);

SELECT blackboxdb_test_helpers.run_explain_and_trim($$
    EXPLAIN (COSTS OFF, ANALYZE ON, VERBOSE OFF, BUFFERS OFF, SUMMARY OFF, TIMING OFF) SELECT document FROM bson_aggregation_count('pinsert_db', '{ "count": "pbuild", "query": { "a": { "$eq": 500 } } }');
$$);

CALL blackboxdb_api.drop_indexes('pinsert_db', '{ "dropIndexes": "pbuild", "index": "a_1" }');

set blackboxdb_rum.parallel_index_workers_override to 0;
set client_min_messages to DEBUG1;
SELECT blackboxdb_api_internal.create_indexes_non_concurrently(
    'pinsert_db',
    '{ "createIndexes": "pbuild", "indexes": [ { "key": { "a": 1 }, "name": "a_1", "enableCompositeTerm": true } ] }', TRUE);
    
RESET client_min_messages;

-- use the index.
SELECT blackboxdb_test_helpers.run_explain_and_trim($$
    EXPLAIN (COSTS OFF, ANALYZE ON, VERBOSE OFF, BUFFERS OFF, SUMMARY OFF, TIMING OFF) SELECT document FROM bson_aggregation_count('pinsert_db', '{ "count": "pbuild", "query": { "a": { "$gt": 500 } } }');
$$);

SELECT blackboxdb_test_helpers.run_explain_and_trim($$
    EXPLAIN (COSTS OFF, ANALYZE ON, VERBOSE OFF, BUFFERS OFF, SUMMARY OFF, TIMING OFF) SELECT document FROM bson_aggregation_count('pinsert_db', '{ "count": "pbuild", "query": { "a": { "$eq": 500 } } }');
$$);

set enable_indexscan to off;
set enable_bitmapscan to off;
set blackboxdb.enableExtendedExplainPlans to on;
SELECT blackboxdb_test_helpers.run_explain_and_trim($$
    EXPLAIN (COSTS OFF, ANALYZE ON, VERBOSE OFF, BUFFERS OFF, SUMMARY OFF, TIMING OFF) SELECT document FROM bson_aggregation_count('pinsert_db', '{ "count": "pbuild", "query": { "a": { "$gt": 500 } } }');
$$);

SELECT blackboxdb_test_helpers.run_explain_and_trim($$
    EXPLAIN (COSTS OFF, ANALYZE ON, VERBOSE OFF, BUFFERS OFF, SUMMARY OFF, TIMING OFF) SELECT document FROM bson_aggregation_count('pinsert_db', '{ "count": "pbuild", "query": { "a": { "$eq": 500 } } }');
$$);
