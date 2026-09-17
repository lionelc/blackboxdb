SET search_path TO blackboxdb_api,blackboxdb_core,blackboxdb_api_catalog;

SET blackboxdb.next_collection_id TO 100;
SET blackboxdb.next_collection_index_id TO 100;

-- create a collection
SELECT blackboxdb_api.insert_one('exrumdb','index_creation_tests', '{"_id": 1, "a": "hello world"}');

-- create a regular index
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('exrumdb', '{ "createIndexes": "index_creation_tests", "indexes": [ { "key": { "a": 1 }, "name": "a_1", "enableOrderedIndex": false } ] }', TRUE);
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('exrumdb', '{ "createIndexes": "index_creation_tests_ordered", "indexes": [ { "key": { "a": 1 }, "name": "a_1", "enableOrderedIndex": true } ] }', TRUE);

-- create a composite index
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('exrumdb', '{ "createIndexes": "index_creation_tests", "indexes": [ { "key": { "a": 1, "b": -1 }, "name": "a_1_b_-1", "enableOrderedIndex": false } ] }', TRUE);
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('exrumdb', '{ "createIndexes": "index_creation_tests_ordered", "indexes": [ { "key": { "a": 1, "b": -1 }, "name": "a_1_b_-1", "enableOrderedIndex": true } ] }', TRUE);

-- create a unique index
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('exrumdb', '{ "createIndexes": "index_creation_tests", "indexes": [ { "key": { "c": 1 }, "name": "c_1", "unique": true, "enableOrderedIndex": false } ] }', TRUE);
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('exrumdb', '{ "createIndexes": "index_creation_tests_ordered", "indexes": [ { "key": { "c": 1 }, "name": "c_1", "unique": true, "enableOrderedIndex": true } ] }', TRUE);

-- create a hashed index
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('exrumdb', '{ "createIndexes": "index_creation_tests", "indexes": [ { "key": { "e": "hashed" }, "name": "e_hashed", "enableOrderedIndex": false } ] }', TRUE);
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('exrumdb', '{ "createIndexes": "index_creation_tests_ordered", "indexes": [ { "key": { "e": "hashed" }, "name": "e_hashed", "enableOrderedIndex": false } ] }', TRUE);

-- create a wildcard index
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('exrumdb', '{ "createIndexes": "index_creation_tests", "indexes": [ { "key": { "b.$**": 1 }, "name": "b_wildcard", "enableOrderedIndex": false } ] }', TRUE);
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('exrumdb', '{ "createIndexes": "index_creation_tests_ordered", "indexes": [ { "key": { "b.$**": -1 }, "name": "b_wildcard", "enableOrderedIndex": true } ] }', TRUE);

-- validate they're all ordered indexes and using the appropriate index handler
\d blackboxdb_data.documents_101
\d blackboxdb_data.documents_102

-- validate they're used in queries
set enable_seqscan to off;
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('exrumdb', '{ "find": "index_creation_tests", "filter": { "a": "hello world" } }');
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('exrumdb', '{ "find": "index_creation_tests", "filter": { "c": "hello world" } }');
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('exrumdb', '{ "find": "index_creation_tests", "filter": { "a": "hello world", "b": "myfoo" } }');

EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('exrumdb', '{ "find": "index_creation_tests", "filter": { "e": "hello world" } }');
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('exrumdb', '{ "find": "index_creation_tests", "filter": { "b.c": "hello world" } }');

EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('exrumdb', '{ "find": "index_creation_tests_ordered", "filter": { "a": "hello world" } }');
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('exrumdb', '{ "find": "index_creation_tests_ordered", "filter": { "c": "hello world" } }');
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('exrumdb', '{ "find": "index_creation_tests_ordered", "filter": { "a": "hello world", "b": "myfoo" } }');

EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('exrumdb', '{ "find": "index_creation_tests_ordered", "filter": { "e": "hello world" } }');
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('exrumdb', '{ "find": "index_creation_tests_ordered", "filter": { "b.c": "hello world" } }');

-- ensure hints can push down to them too.
set enable_indexscan to off;
set enable_bitmapscan to off;
SELECT blackboxdb_test_helpers.run_explain_and_trim($cmd$
    EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('exrumdb', '{ "find": "index_creation_tests", "filter": { "a": "hello world" }, "hint": "a_1" }');
$cmd$);

SELECT blackboxdb_test_helpers.run_explain_and_trim($cmd$
    EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('exrumdb', '{ "find": "index_creation_tests", "filter": { "c": "hello world" }, "hint": "c_1" }');
$cmd$);

SELECT blackboxdb_test_helpers.run_explain_and_trim($cmd$
    EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('exrumdb', '{ "find": "index_creation_tests", "filter": { "a": "hello world", "b": "myfoo" }, "hint": "a_1_b_-1" }');
$cmd$);

SELECT blackboxdb_test_helpers.run_explain_and_trim($cmd$
    EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('exrumdb', '{ "find": "index_creation_tests", "filter": { "e": "hello world" }, "hint": "e_hashed" }');
$cmd$);

SELECT blackboxdb_test_helpers.run_explain_and_trim($cmd$
    EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('exrumdb', '{ "find": "index_creation_tests", "filter": { "b.c": "hello world" }, "hint": "b_wildcard" }');
$cmd$);

-- Re-enable index scans for the ordered-index hint-pushdown queries below.
-- Keep bitmap scans disabled so the hinted plan is deterministically an Index Scan.
set enable_indexscan to on;
set enable_bitmapscan to off;
SELECT blackboxdb_test_helpers.run_explain_and_trim($cmd$
    EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('exrumdb', '{ "find": "index_creation_tests_ordered", "filter": { "a": "hello world" }, "hint": "a_1" }');
$cmd$);

SELECT blackboxdb_test_helpers.run_explain_and_trim($cmd$
    EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('exrumdb', '{ "find": "index_creation_tests_ordered", "filter": { "c": "hello world" }, "hint": "c_1" }');
$cmd$);

SELECT blackboxdb_test_helpers.run_explain_and_trim($cmd$
    EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('exrumdb', '{ "find": "index_creation_tests_ordered", "filter": { "a": "hello world", "b": "myfoo" }, "hint": "a_1_b_-1" }');
$cmd$);

SELECT blackboxdb_test_helpers.run_explain_and_trim($cmd$
    EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('exrumdb', '{ "find": "index_creation_tests_ordered", "filter": { "e": "hello world" }, "hint": "e_hashed" }');
$cmd$);

SELECT blackboxdb_test_helpers.run_explain_and_trim($cmd$
    EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('exrumdb', '{ "find": "index_creation_tests_ordered", "filter": { "b.c": "hello world" }, "hint": "b_wildcard" }');
$cmd$);