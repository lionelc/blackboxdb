SET search_path TO blackboxdb_api,blackboxdb_api_catalog,blackboxdb_api_internal,blackboxdb_core;

SET citus.next_shard_id TO 6920000;
SET blackboxdb.next_collection_id TO 69200;
SET blackboxdb.next_collection_index_id TO 69200;

set blackboxdb.enableOrderByIndexTerm to on;
\i sql/bson_composite_order_by_index_tests_core.sql


-- test the appearance of order pushdown
SELECT COUNT(blackboxdb_api.insert_one('comp_ordind_db', 'test_order_pushdown_explain', '{ "_id": 1, "a": 1, "b": 2 }')) FROM generate_series(1, 1000);

-- test asc/desc combos for each runtime type pair (with hruntime, the function always gets asc sort spec but with forward or reverse) since we have DESC/ASC in the sort itself.
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('comp_ordind_db', '{ "find": "test_order_pushdown_explain", "sort": { "a": 1 } }');
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('comp_ordind_db', '{ "find": "test_order_pushdown_explain", "sort": { "a": -1 } }');

EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('comp_ordind_db', '{ "find": "test_order_pushdown_explain", "sort": { "a": 1, "b": -1 } }');
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('comp_ordind_db', '{ "find": "test_order_pushdown_explain", "sort": { "a": -1, "b": 1 } }');

-- when pushing to the index, we want to make sure the index term reflects the sort order of the query
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('comp_ordind_db', '{ "createIndexes": "test_order_pushdown_explain", "indexes": [ { "key": { "a": 1 }, "name": "a_1", "storageEngine": { "enableCompositeTerm": true } }, { "key": { "b": -1 }, "name": "b_-1", "storageEngine": { "enableCompositeTerm": true } } ] }', TRUE);

SELECT collection_id FROM blackboxdb_api_catalog.collections WHERE collection_name = 'test_order_pushdown_explain' AND database_name = 'comp_ordind_db' \gset
ANALYZE blackboxdb_data.documents_:collection_id;

EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('comp_ordind_db', '{ "find": "test_order_pushdown_explain", "sort": { "a": 1 } }');
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('comp_ordind_db', '{ "find": "test_order_pushdown_explain", "sort": { "a": -1 } }');

EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('comp_ordind_db', '{ "find": "test_order_pushdown_explain", "sort": { "b": 1 } }');
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('comp_ordind_db', '{ "find": "test_order_pushdown_explain", "sort": { "b": -1 } }');