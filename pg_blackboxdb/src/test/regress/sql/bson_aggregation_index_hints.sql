SET search_path TO blackboxdb_api,blackboxdb_api_catalog,blackboxdb_api_internal,blackboxdb_core;

SET blackboxdb.next_collection_id TO 69500;
SET blackboxdb.next_collection_index_id TO 69500;

SELECT blackboxdb_api.drop_collection('hint_db', 'query_index_hints') IS NOT NULL;
SELECT blackboxdb_api.create_collection('hint_db', 'query_index_hints');

-- create various kinds of indexes.
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('hint_db', '{ "createIndexes": "query_index_hints", "indexes": [ { "key": { "a": 1, "b": 1 }, "name": "a_b_1" }] }', true);
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('hint_db', '{ "createIndexes": "query_index_hints", "indexes": [ { "key": { "a": 1, "c": 1 }, "name": "a_1_c_1" }] }', true);

SELECT blackboxdb_api.insert_one('hint_db', 'query_index_hints', '{ "_id": 1, "a": 1, "b": 1, "c": 1 }');

SELECT blackboxdb_test_helpers.run_explain_and_trim( $cmd$
    EXPLAIN (COSTS OFF, VERBOSE OFF, TIMING OFF, SUMMARY OFF, BUFFERS OFF, ANALYZE ON) SELECT document from bson_aggregation_find('hint_db', '{ "find": "query_index_hints", "sort": { "a": 1 }, "hint": { "a": 1, "c": 1 } }') $cmd$);
SELECT blackboxdb_test_helpers.run_explain_and_trim( $cmd$
    EXPLAIN (COSTS OFF, VERBOSE OFF, TIMING OFF, SUMMARY OFF, BUFFERS OFF, ANALYZE ON) SELECT document from bson_aggregation_find('hint_db', '{ "find": "query_index_hints", "sort": { "a": 1 }, "hint": { "a": 1, "b": 1 } }') $cmd$);

-- redo with ordered indexes off
SELECT blackboxdb_api.drop_collection('hint_db', 'query_index_hints') IS NOT NULL;
SELECT blackboxdb_api.create_collection('hint_db', 'query_index_hints');

-- create various kinds of indexes.
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('hint_db', '{ "createIndexes": "query_index_hints", "indexes": [ { "key": { "a": 1, "b": 1 }, "name": "a_b_1", "enableOrderedIndex": false }] }', true);
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('hint_db', '{ "createIndexes": "query_index_hints", "indexes": [ { "key": { "a": 1, "c": 1 }, "name": "a_1_c_1", "enableOrderedIndex": false }] }', true);

SELECT blackboxdb_api.insert_one('hint_db', 'query_index_hints', '{ "_id": 1, "a": 1, "b": 1, "c": 1 }');

SELECT blackboxdb_test_helpers.run_explain_and_trim( $cmd$
    EXPLAIN (COSTS OFF, VERBOSE OFF, TIMING OFF, SUMMARY OFF, BUFFERS OFF, ANALYZE ON) SELECT document from bson_aggregation_find('hint_db', '{ "find": "query_index_hints", "sort": { "a": 1 }, "hint": { "a": 1, "c": 1 } }') $cmd$);
SELECT blackboxdb_test_helpers.run_explain_and_trim( $cmd$
    EXPLAIN (COSTS OFF, VERBOSE OFF, TIMING OFF, SUMMARY OFF, BUFFERS OFF, ANALYZE ON) SELECT document from bson_aggregation_find('hint_db', '{ "find": "query_index_hints", "sort": { "a": 1 }, "hint": { "a": 1, "b": 1 } }') $cmd$);
