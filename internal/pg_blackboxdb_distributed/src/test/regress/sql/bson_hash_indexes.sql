
SET search_path TO blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog;

SET citus.next_shard_id TO 530000;
SET blackboxdb.next_collection_id TO 5300;
SET blackboxdb.next_collection_index_id TO 5300;

-- insert a document
SELECT blackboxdb_api.create_collection('db', 'queryhashindex');

SELECT blackboxdb_distributed_test_helpers.drop_primary_key('db','queryhashindex');

-- Create a hash index on the collection.
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "queryhashindex", "indexes": [ { "key" : { "a.b": "hashed" }, "name": "hashIndex" }] }', true);
SELECT * FROM blackboxdb_distributed_test_helpers.get_collection_indexes('db', 'queryhashindex') ORDER BY collection_id, index_id;

SELECT blackboxdb_api.list_indexes_cursor_first_page('db','{ "listIndexes": "queryhashindex" }') ORDER BY 1;

-- Explain various hash index scenarios.
BEGIN;
set local enable_seqscan to off;
EXPLAIN (COSTS OFF) SELECT object_id, document FROM blackboxdb_api.collection('db', 'queryhashindex') WHERE bson_dollar_eq(document, '{ "a.b": 1 }');
EXPLAIN (COSTS OFF) SELECT object_id, document FROM blackboxdb_api.collection('db', 'queryhashindex') WHERE bson_dollar_in(document, '{ "a.b": [ 1, 2, true ]}'::bson);

-- these should not use the index.
EXPLAIN (COSTS OFF) SELECT object_id, document FROM blackboxdb_api.collection('db', 'queryhashindex') WHERE bson_dollar_ne(document, '{ "a.b": 1 }');
EXPLAIN (COSTS OFF) SELECT object_id, document FROM blackboxdb_api.collection('db', 'queryhashindex') WHERE bson_dollar_gt(document, '{ "a.b": 1 }');
EXPLAIN (COSTS OFF) SELECT object_id, document FROM blackboxdb_api.collection('db', 'queryhashindex') WHERE bson_dollar_gte(document, '{ "a.b": 1 }');
EXPLAIN (COSTS OFF) SELECT object_id, document FROM blackboxdb_api.collection('db', 'queryhashindex') WHERE bson_dollar_lt(document, '{ "a.b": 1 }');
EXPLAIN (COSTS OFF) SELECT object_id, document FROM blackboxdb_api.collection('db', 'queryhashindex') WHERE bson_dollar_lte(document, '{ "a.b": 1 }');

-- null can be pushed down.
EXPLAIN (COSTS OFF) SELECT object_id, document FROM blackboxdb_api.collection('db', 'queryhashindex') WHERE bson_dollar_eq(document, '{ "a.b": null }');
EXPLAIN (COSTS OFF) SELECT object_id, document FROM blackboxdb_api.collection('db', 'queryhashindex') WHERE bson_dollar_in(document, '{ "a.b": [ 1, 2, null ]}'::bson);

-- now insert some documents and run the queries above.
SELECT blackboxdb_api.insert_one('db', 'queryhashindex', '{ "a": { "b": 1 } }');
SELECT blackboxdb_api.insert_one('db', 'queryhashindex', '{ "a": { "b": 2 } }');
SELECT blackboxdb_api.insert_one('db', 'queryhashindex', '{ "a": { "b": 3 } }');
SELECT blackboxdb_api.insert_one('db', 'queryhashindex', '{ "a": { "b": "string" } }');
SELECT blackboxdb_api.insert_one('db', 'queryhashindex', '{ "a": { "b": null } }');
SELECT blackboxdb_api.insert_one('db', 'queryhashindex', '{ "a": { "b": false } }');
SELECT blackboxdb_api.insert_one('db', 'queryhashindex', '{ "c": 1, "a": "c only field" }');
SELECT blackboxdb_api.insert_one('db', 'queryhashindex', '{ "a": { "b": {"$undefined" : true } } }'); -- null should also get undefined values

SELECT document -> 'a' FROM blackboxdb_api.collection('db', 'queryhashindex') WHERE bson_dollar_eq(document, '{ "a.b": 1 }');
SELECT document -> 'a' FROM blackboxdb_api.collection('db', 'queryhashindex') WHERE bson_dollar_in(document, '{ "a.b": [ 1, 2, true ]}'::bson);

SELECT document -> 'a' FROM blackboxdb_api.collection('db', 'queryhashindex') WHERE bson_dollar_eq(document, '{ "a.b": null }');
SELECT document -> 'a' FROM blackboxdb_api.collection('db', 'queryhashindex') WHERE bson_dollar_in(document, '{ "a.b": [ 1, 2, null ]}'::bson);

ROLLBACK;

