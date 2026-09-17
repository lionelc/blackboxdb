SET search_path TO blackboxdb_api,blackboxdb_core,blackboxdb_api_catalog;
SET blackboxdb.next_collection_id TO 2500;
SET blackboxdb.next_collection_index_id TO 2500;

-- Call delete for a non existent collection.
-- Note that this should not report any logs related to collection catalog lookup.
SELECT blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{"$and":[{"a":5},{"a":{"$gt":0}}]},"limit":0}]}');

select 1 from blackboxdb_api.insert_one('db', 'removeme', '{"a":1,"_id":1}');
select 1 from blackboxdb_api.insert_one('db', 'removeme', '{"a":2,"_id":2}');
select 1 from blackboxdb_api.insert_one('db', 'removeme', '{"a":3,"_id":3}');
select 1 from blackboxdb_api.insert_one('db', 'removeme', '{"a":4,"_id":4}');
select 1 from blackboxdb_api.insert_one('db', 'removeme', '{"a":5,"_id":5}');
select 1 from blackboxdb_api.insert_one('db', 'removeme', '{"a":6,"_id":6}');
select 1 from blackboxdb_api.insert_one('db', 'removeme', '{"a":7,"_id":7}');
select 1 from blackboxdb_api.insert_one('db', 'removeme', '{"a":8,"_id":8}');
select 1 from blackboxdb_api.insert_one('db', 'removeme', '{"a":9,"_id":9}');
select 1 from blackboxdb_api.insert_one('db', 'removeme', '{"a":10,"_id":10}');

-- exercise invalid delete syntax errors
select blackboxdb_api.delete('db', NULL);
select blackboxdb_api.delete(NULL, '{"delete":"removeme", "deletes":[{"q":{},"limit":0}]}');
select blackboxdb_api.delete('db', '{"deletes":[{"q":{},"limit":0}]}');
select blackboxdb_api.delete('db', '{"delete":"removeme"}');
select blackboxdb_api.delete('db', '{"delete":["removeme"], "deletes":[{"q":{},"limit":0}]}');
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":{"q":{},"limit":0}}');
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{},"limit":0}], "extra":1}');
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{}}]}');
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"limit":0}]}');
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":[],"limit":0}]}');
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{},"limit":0,"extra":1}]}');
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{},"limit":0}],"ordered":1}');

-- Disallow writes to system.views
select blackboxdb_api.delete('db', '{"delete":"system.views", "deletes":[{"q":{},"limit":0}]}');

-- delete all
begin;
SET LOCAL search_path TO '';
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{},"limit":0}]}');
select count(*) from blackboxdb_api.collection('db', 'removeme');
rollback;

-- delete some
begin;
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{"a":{"$lte":3}},"limit":0}]}');
select count(*) from blackboxdb_api.collection('db', 'removeme');
rollback;

-- arbitrary limit type works in Mongo
begin;
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{"a":{"$lte":3}},"limit":{"hello":"world"}}]}');
select count(*) from blackboxdb_api.collection('db', 'removeme');
rollback;

-- delete all from non-existent collection
select blackboxdb_api.delete('db', '{"delete":"notexists", "deletes":[{"q":{},"limit":0}]}');

-- query syntax errors are added the response
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{"a":{"$ltr":5}},"limit":0}]}');

-- when ordered, expect only first delete to be executed
begin;
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{"a":1},"limit":0},{"q":{"$a":2},"limit":0},{"q":{"a":3},"limit":0}]}');
select count(*) from blackboxdb_api.collection('db', 'removeme');
rollback;

begin;
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{"a":1},"limit":0},{"q":{"$a":2},"limit":0},{"q":{"a":3},"limit":0}],"ordered":true}');
select count(*) from blackboxdb_api.collection('db', 'removeme');
rollback;

-- when not ordered, expect first and last delete to be executed
begin;
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{"a":1},"limit":0},{"q":{"$a":2},"limit":0},{"q":{"a":3},"limit":0}],"ordered":false}');
select count(*) from blackboxdb_api.collection('db', 'removeme');
rollback;

-- delete 1 without filters is supported for unsharded collections
begin;
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{},"limit":1}]}');
select count(*) from blackboxdb_api.collection('db', 'removeme');
rollback;

-- delete 1 is retryable on unsharded collection (second call is a noop)
begin;
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{},"limit":1}]}', NULL, 'xact-1');
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{},"limit":1}]}', NULL, 'xact-1');
select count(*) from blackboxdb_api.collection('db', 'removeme');
rollback;

-- delete 1 is supported in the _id case
begin;
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{"_id":6},"limit":1}]}');
select count(*) from blackboxdb_api.collection('db', 'removeme') where document @@ '{"_id":6}';
rollback;

-- delete 1 is supported in the multiple identical _id case
begin;
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{"$and":[{"_id":6},{"_id":6}]},"limit":1}]}');
select count(*) from blackboxdb_api.collection('db', 'removeme') where document @@ '{"_id":6}';
rollback;

-- delete 1 is supported in the multiple distinct _id case (but a noop)
begin;
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{"$and":[{"_id":6},{"_id":5}]},"limit":1}]}');
select count(*) from blackboxdb_api.collection('db', 'removeme') where document @@ '{"_id":6}';
rollback;

-- validate _id extraction
begin;
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{"_id":6},"limit":1}]}');
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{"$and":[{"_id":6},{"_id":5}]},"limit":1}]}');
rollback;

-- shard the collection
select blackboxdb_api.shard_collection('db', 'removeme', '{"a":"hashed"}', false);

-- make sure we get the expected results after sharding a collection
begin;
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{"a":{"$lte":5}},"limit":0}]}');
select count(*) from blackboxdb_api.collection('db', 'removeme') where document @@ '{"a":1}';
select count(*) from blackboxdb_api.collection('db', 'removeme') where document @@ '{"a":10}';
select count(*) from blackboxdb_api.collection('db', 'removeme');
rollback;

-- test pruning logic in delete
begin;
select count(*) from blackboxdb_api.collection('db', 'removeme');
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{"a":{"$eq":5}},"limit":0}]}');
select count(*) from blackboxdb_api.collection('db', 'removeme') where document @@ '{"a":5}';
select count(*) from blackboxdb_api.collection('db', 'removeme');
rollback;

begin;
select count(*) from blackboxdb_api.collection('db', 'removeme');
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{"$and":[{"a":5},{"a":{"$gt":0}}]},"limit":0}]}');
select count(*) from blackboxdb_api.collection('db', 'removeme') where document @@ '{"a":5}';
select count(*) from blackboxdb_api.collection('db', 'removeme');
rollback;

-- delete 1 without filters is unsupported for sharded collections
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{},"limit":1}]}');

-- delete 1 with shard key filters is supported for sharded collections
begin;
select count(*) from blackboxdb_api.collection('db', 'removeme');
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{"a":{"$eq":5}},"limit":1}]}');
select count(*) from blackboxdb_api.collection('db', 'removeme') where document @@ '{"a":5}';
select count(*) from blackboxdb_api.collection('db', 'removeme');
rollback;

-- delete 1 with shard key filters is retryable
begin;
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{"a":{"$eq":5}},"limit":1}]}', NULL, 'xact-2');
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{"a":{"$eq":5}},"limit":1}]}', NULL, 'xact-2');
select count(*) from blackboxdb_api.collection('db', 'removeme');
rollback;

-- delete 1 that does not match any rows is still retryable
begin;
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{"a":{"$eq":15}},"limit":1}]}', NULL, 'xact-3');
select 1 from blackboxdb_api.insert_one('db', 'removeme', '{"a":15,"_id":15}');
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{"a":{"$eq":15}},"limit":1}]}', NULL, 'xact-3');
rollback;

-- delete 1 is supported in the _id case even on sharded collections
begin;
-- add an additional _id 10
select 1 from blackboxdb_api.insert_one('db', 'removeme', '{"a":11,"_id":10}');
-- delete first row where _id = 10
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{"_id":10},"limit":1}]}');
select count(*) from blackboxdb_api.collection('db', 'removeme') where document @@ '{"_id":10}';
-- delete second row where _id = 10
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{"_id":10},"limit":1}]}');
select count(*) from blackboxdb_api.collection('db', 'removeme') where document @@ '{"_id":10}';
-- no more row where _id = 10
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{"_id":10},"limit":1}]}');
select count(*) from blackboxdb_api.collection('db', 'removeme') where document @@ '{"_id":10}';
select count(*) from blackboxdb_api.collection('db', 'removeme');
rollback;

-- delete 1 with with _id filter on a sharded collection is retryable
begin;
-- add an additional _id 10 (total to 11 rows)
select 1 from blackboxdb_api.insert_one('db', 'removeme', '{"a":11,"_id":10}');
-- delete first row where _id = 10
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{"_id":10},"limit":1}]}', NULL, 'xact-4');
-- second time is a noop
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{"_id":10},"limit":1}]}', NULL, 'xact-4');
select count(*) from blackboxdb_api.collection('db', 'removeme');
rollback;

-- delete 1 is supported in the multiple identical _id case
begin;
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{"$and":[{"_id":6},{"_id":6}]},"limit":1}]}');
select count(*) from blackboxdb_api.collection('db', 'removeme') where document @@ '{"_id":6}';
rollback;

-- delete 1 is unsupported in the multiple distinct _id case
begin;
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{"$and":[{"_id":6},{"_id":5}]},"limit":1}]}');
select count(*) from blackboxdb_api.collection('db', 'removeme') where document @@ '{"_id":6}';
rollback;

-- validate _id extraction
begin;
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{"a": 11, "_id":6},"limit":0}]}');
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{"$and":[{"a": 11},{"_id":6},{"_id":5}]},"limit":0}]}');
rollback;

-- delete with spec in special section
begin;
select count(*) from blackboxdb_api.collection('db', 'removeme');
select blackboxdb_api.delete('db', '{"delete":"removeme"}', '{ "":[{"q":{"a":{"$eq":5}},"limit":1}] }');
select count(*) from blackboxdb_api.collection('db', 'removeme') where document @@ '{"a":5}';
select count(*) from blackboxdb_api.collection('db', 'removeme');
rollback;

-- deletes with both specs specified 
begin;
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes": [{"q":{"a":{"$eq":5}},"limit":1}] }', '{ "":[{"q":{"a":{"$eq":5}},"limit":1}] }');
rollback;

SELECT 1 FROM blackboxdb_api.insert_one('delete', 'test_sort_returning', '{"_id": 1,"a":3,"b":7}');
SELECT 1 FROM blackboxdb_api.insert_one('delete', 'test_sort_returning', '{"_id": 2,"a":2,"b":5}');
SELECT 1 FROM blackboxdb_api.insert_one('delete', 'test_sort_returning', '{"_id": 3,"a":1,"b":6}');

-- sort in ascending order and project & return deleted document
SELECT collection_id AS test_sort_returning FROM blackboxdb_api_catalog.collections WHERE database_name = 'delete' AND collection_name = 'test_sort_returning' \gset
SELECT blackboxdb_api_internal.delete_worker(
    p_collection_id=>:test_sort_returning,
    p_shard_key_value=>:test_sort_returning,
    p_shard_oid => 0,
    p_update_internal_spec => '{ "deleteOne": { "query": { "a": {"$gte": 1} },  "sort": { "b": 1 }, "returnDocument": 1, "returnFields": { "a": 0} } }'::bson,
    p_update_internal_docs=>null::bsonsequence,
    p_transaction_id=>null::text
) FROM blackboxdb_api.collection('delete', 'test_sort_returning');



-- sort by multiple fields (i) and return deleted document
BEGIN;

SELECT collection_id AS test_sort_returning FROM blackboxdb_api_catalog.collections WHERE database_name = 'delete' AND collection_name = 'test_sort_returning' \gset
SELECT blackboxdb_api_internal.delete_worker(
    p_collection_id=>:test_sort_returning,
    p_shard_key_value=>:test_sort_returning,
    p_shard_oid => 0,
    p_update_internal_spec => '{ "deleteOne": { "query": { "a": {"$gte": 1} },  "sort": { "b": -1, "a" : 1 }, "returnDocument": 1, "returnFields": { "a": 0} } }'::bson,
    p_update_internal_docs=>null::bsonsequence,
    p_transaction_id=>null::text
) FROM blackboxdb_api.collection('delete', 'test_sort_returning');

ROLLBACK;

-- sort by multiple fields (ii) and return deleted document
SELECT collection_id AS test_sort_returning FROM blackboxdb_api_catalog.collections WHERE database_name = 'delete' AND collection_name = 'test_sort_returning' \gset
SELECT blackboxdb_api_internal.delete_worker(
    p_collection_id=>:test_sort_returning,
    p_shard_key_value=>:test_sort_returning,
    p_shard_oid => 0,
    p_update_internal_spec => '{ "deleteOne": { "query": { "a": {"$gte": 1} },  "sort": { "a": 1, "b" : -1 }, "returnDocument": 1, "returnFields": { "a": 0} } }'::bson,
    p_update_internal_docs=>null::bsonsequence,
    p_transaction_id=>null::text
) FROM blackboxdb_api.collection('delete', 'test_sort_returning');

SELECT document FROM blackboxdb_api.collection('delete', 'test_sort_returning') ORDER BY 1;

-- show that we validate "query" document even if collection doesn't exist
-- i) ordered=true
SELECT blackboxdb_api.delete(
    'delete',
    '{
        "delete": "dne",
        "deletes": [
            {"q": {"a": 1}, "limit": 0 },
            {"q": {"$b": 1}, "limit": 0 },
            {"q": {"c": 1}, "limit": 0 },
            {"q": {"$d": 1}, "limit": 0 },
            {"q": {"e": 1}, "limit": 0 }
        ],
        "ordered": true
     }'
);
-- ii) ordered=false
SELECT blackboxdb_api.delete(
    'delete',
    '{
        "delete": "dne",
        "deletes": [
            {"q": {"a": 1}, "limit": 0 },
            {"q": {"$b": 1}, "limit": 0 },
            {"q": {"c": 1}, "limit": 0 },
            {"q": {"$d": 1}, "limit": 0 },
            {"q": {"e": 1}, "limit": 0 }
        ],
        "ordered": false
     }'
);

SELECT blackboxdb_api.create_collection('delete', 'no_match');

-- show that we validate "query" document even if we can't match any documents
-- i) ordered=true
SELECT blackboxdb_api.delete(
    'delete',
    '{
        "delete": "no_match",
        "deletes": [
            {"q": {"a": 1}, "limit": 0 },
            {"q": {"$b": 1}, "limit": 0 },
            {"q": {"c": 1}, "limit": 0 },
            {"q": {"$d": 1}, "limit": 0 },
            {"q": {"e": 1}, "limit": 0 }
        ],
        "ordered": true
     }'
);
-- ii) ordered=false
SELECT blackboxdb_api.delete(
    'delete',
    '{
        "delete": "no_match",
        "deletes": [
            {"q": {"a": 1}, "limit": 0 },
            {"q": {"$b": 1}, "limit": 0 },
            {"q": {"c": 1}, "limit": 0 },
            {"q": {"$d": 1}, "limit": 0 },
            {"q": {"e": 1}, "limit": 0 }
        ],
        "ordered": false
     }'
);


-- Check for index pushdown
BEGIN;
select  blackboxdb_api.insert('datab', '{"insert":"deleteIndex", "documents":[{"_id":1}]}');
select  blackboxdb_api.insert('datab', '{"insert":"deleteIndex", "documents":[{"_id":2}]}');
SET LOCAL enable_seqscan TO OFF;
select  blackboxdb_api.insert('datab', '{"insert":"deleteIndex", "documents":[{"_id":3}]}');

select collection_id  from blackboxdb_api_catalog.collections where collection_name = 'deleteIndex';
-- explain plan should show index scan with delete pushdown
EXPLAIN (COSTS OFF, VERBOSE ON) DELETE FROM  blackboxdb_data.documents_2505 WHERE blackboxdb_api_internal.bson_query_match(document, '{"_id" : {"$in" : [1,2,3,4,5,6,7,8,9,10]}}', NULL, NULL::text) ;
EXPLAIN (COSTS OFF, VERBOSE ON) DELETE FROM  blackboxdb_data.documents_2505 WHERE blackboxdb_api_internal.bson_query_match(document, '{"_id" : {"$gt" : 10}}', NULL, NULL::text);
EXPLAIN (COSTS OFF, VERBOSE ON) DELETE FROM  blackboxdb_data.documents_2505 WHERE blackboxdb_api_internal.bson_query_match(document, '{"_id" : {"$lt" : 10}}', NULL, NULL::text);
EXPLAIN (COSTS OFF, VERBOSE ON) DELETE FROM  blackboxdb_data.documents_2505 WHERE blackboxdb_api_internal.bson_query_match(document, '{"_id" : {"$gte" : 10}}', NULL, NULL::text);
EXPLAIN (COSTS OFF, VERBOSE ON) DELETE FROM  blackboxdb_data.documents_2505 WHERE blackboxdb_api_internal.bson_query_match(document, '{"_id" : {"$lte" : 10}}', NULL, NULL::text);
COMMIT;

-- Test for deleteOne plan caching by enabling and disabling the config
-- validate _id-only delete_one correctness, should still delete only one document
begin;
set local blackboxdb.enableDeleteOnePlanCacheOptimization to true;
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{"_id":6},"limit":1}]}');
select count(*) from blackboxdb_api.collection('db', 'removeme') where document @@ '{"_id":6}';

set local blackboxdb.enableDeleteOnePlanCacheOptimization to false;
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{"_id":7},"limit":1}]}');
select count(*) from blackboxdb_api.collection('db', 'removeme') where document @@ '{"_id":7}';

select count(*) from blackboxdb_api.collection('db', 'removeme');
rollback;

-- _id with other filters: should use full query matching
begin;
set local blackboxdb.enableDeleteOnePlanCacheOptimization to true;
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{"_id":6, "a":6},"limit":1}]}');
select count(*) from blackboxdb_api.collection('db', 'removeme') where document @@ '{"_id":6}';

set local blackboxdb.enableDeleteOnePlanCacheOptimization to false;
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{"_id":7, "a":7},"limit":1}]}');
select count(*) from blackboxdb_api.collection('db', 'removeme') where document @@ '{"_id":7}';
select count(*) from blackboxdb_api.collection('db', 'removeme');
rollback;

begin;
set local blackboxdb.enableDeleteOnePlanCacheOptimization to true;
-- delete_one empty query
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{},"limit":1}]}');
select count(*) from blackboxdb_api.collection('db', 'removeme');
rollback;

begin;
set local blackboxdb.enableDeleteOnePlanCacheOptimization to false;
-- delete_one empty query
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{},"limit":1}]}');
select count(*) from blackboxdb_api.collection('db', 'removeme');
rollback;

begin;
select count(*) from blackboxdb_api.collection('db', 'removeme');
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{"_id":1},"limit":1}]}');

-- force the cached plan to be used for next deletes and verify that delete happens correctly with the generic plan
set local plan_cache_mode to 'force_generic_plan';

select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{"_id":2},"limit":1}]}');
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{"_id":3},"limit":1}]}');
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{"_id":4},"limit":1}]}');
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{"_id":5},"limit":1}]}');
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{"_id":6},"limit":1}]}');
select blackboxdb_api.delete('db', '{"delete":"removeme", "deletes":[{"q":{"_id":7},"limit":1}]}');

select count(*) from blackboxdb_api.collection('db', 'removeme') where document @@ '{"_id": { "$in" : [1, 2, 3, 4, 5, 6, 7]}}';
select count(*) from blackboxdb_api.collection('db', 'removeme');
rollback;

-- Test: planId collision when findAndModify (deleteOne with returnDeletedDocument)
-- uses _id filter (planId QUERY_DELETE_ONE_ID → remapped to QUERY_DELETE_ONE_ID_RETURN_DOCUMENT)
-- and then without _id filter (planId QUERY_DELETE_ONE → also remapped to the same
-- QUERY_DELETE_ONE_ID_RETURN_DOCUMENT). Different SQL/argCount sharing the same planId
-- causes a plan cache collision.
SELECT 1 FROM blackboxdb_api.insert_one('db', 'plan_collision_test', '{"_id": 1, "a": 1}');
SELECT 1 FROM blackboxdb_api.insert_one('db', 'plan_collision_test', '{"_id": 2, "a": 2}');
SELECT 1 FROM blackboxdb_api.insert_one('db', 'plan_collision_test', '{"_id": 3, "a": 3}');
SELECT 1 FROM blackboxdb_api.insert_one('db', 'plan_collision_test', '{"_id": 4, "a": 4}');
SELECT 1 FROM blackboxdb_api.insert_one('db', 'plan_collision_test', '{"_id": 5, "a": 5}');
SELECT 1 FROM blackboxdb_api.insert_one('db', 'plan_collision_test', '{"_id": 6, "a": 6}');
SELECT 1 FROM blackboxdb_api.insert_one('db', 'plan_collision_test', '{"_id": 7, "a": 7}');
SELECT 1 FROM blackboxdb_api.insert_one('db', 'plan_collision_test', '{"_id": 8, "a": 8}');

begin;
set local plan_cache_mode to 'force_generic_plan';

-- Cache the plan: findAndModify with _id filter + remove (returnDeletedDocument=true)
-- This caches plan with 3 args (shard_key, query, objectId) under planId 11
select blackboxdb_api.find_and_modify('db', '{"findAndModify":"plan_collision_test", "query":{"_id":1}, "remove":true}');
select blackboxdb_api.find_and_modify('db', '{"findAndModify":"plan_collision_test", "query":{"_id":2}, "remove":true}');
select blackboxdb_api.find_and_modify('db', '{"findAndModify":"plan_collision_test", "query":{"_id":3}, "remove":true}');
select blackboxdb_api.find_and_modify('db', '{"findAndModify":"plan_collision_test", "query":{"_id":4}, "remove":true}');
select blackboxdb_api.find_and_modify('db', '{"findAndModify":"plan_collision_test", "query":{"_id":5}, "remove":true}');

-- Now run findAndModify WITHOUT _id filter. Before the fix, this would reuse the cached
-- plan (planId 11) which expects 3 args but receives 2, causing a crash.
select blackboxdb_api.find_and_modify('db', '{"findAndModify":"plan_collision_test", "query":{"a":6}, "remove":true}');

select count(*) from blackboxdb_api.collection('db', 'plan_collision_test');
rollback;

select blackboxdb_api.drop_collection('db', 'plan_collision_test');

select blackboxdb_api.drop_collection('db','removeme');

-- delete 'limit' only accepts the integer 0 or 1
select 1 from blackboxdb_api.insert_one('db', 'del_limit', '{"_id":1,"r":"keep"}');
select 1 from blackboxdb_api.insert_one('db', 'del_limit', '{"_id":2,"r":"rm"}');
select 1 from blackboxdb_api.insert_one('db', 'del_limit', '{"_id":3,"r":"rm"}');
select 1 from blackboxdb_api.insert_one('db', 'del_limit', '{"_id":4,"r":"rm"}');

-- limit 1 deletes one
begin;
select blackboxdb_api.delete('db', '{"delete":"del_limit", "deletes":[{"q":{"r":"rm"},"limit":1}]}');
select count(*) from blackboxdb_api.collection('db', 'del_limit');
rollback;

-- limit 0 deletes all matches
begin;
select blackboxdb_api.delete('db', '{"delete":"del_limit", "deletes":[{"q":{"r":"rm"},"limit":0}]}');
select count(*) from blackboxdb_api.collection('db', 'del_limit');
rollback;

-- whole-number doubles are accepted
begin;
select blackboxdb_api.delete('db', '{"delete":"del_limit", "deletes":[{"q":{"r":"rm"},"limit":1.0}]}');
select count(*) from blackboxdb_api.collection('db', 'del_limit');
rollback;
begin;
select blackboxdb_api.delete('db', '{"delete":"del_limit", "deletes":[{"q":{"r":"rm"},"limit":0.0}]}');
select count(*) from blackboxdb_api.collection('db', 'del_limit');
rollback;

-- fractional limits are rejected
select blackboxdb_api.delete('db', '{"delete":"del_limit", "deletes":[{"q":{"r":"rm"},"limit":0.5}]}');
select blackboxdb_api.delete('db', '{"delete":"del_limit", "deletes":[{"q":{"r":"rm"},"limit":0.9}]}');
select blackboxdb_api.delete('db', '{"delete":"del_limit", "deletes":[{"q":{"r":"rm"},"limit":1.5}]}');
select blackboxdb_api.delete('db', '{"delete":"del_limit", "deletes":[{"q":{"r":"rm"},"limit":-0.5}]}');
select blackboxdb_api.delete('db', '{"delete":"del_limit", "deletes":[{"q":{"r":"rm"},"limit":2.5}]}');
select count(*) from blackboxdb_api.collection('db', 'del_limit');

-- decimal128 limit: 1 deletes one, fractional/out-of-range rejected
begin;
select blackboxdb_api.delete('db', '{"delete":"del_limit", "deletes":[{"q":{"r":"rm"},"limit":{"$numberDecimal":"1"}}]}');
select count(*) from blackboxdb_api.collection('db', 'del_limit');
rollback;
select blackboxdb_api.delete('db', '{"delete":"del_limit", "deletes":[{"q":{"r":"rm"},"limit":{"$numberDecimal":"0.5"}}]}');
select blackboxdb_api.delete('db', '{"delete":"del_limit", "deletes":[{"q":{"r":"rm"},"limit":{"$numberDecimal":"2"}}]}');

-- NaN/Infinity limits are rejected
select blackboxdb_api.delete('db', '{"delete":"del_limit", "deletes":[{"q":{"r":"rm"},"limit":{"$numberDouble":"NaN"}}]}');
select blackboxdb_api.delete('db', '{"delete":"del_limit", "deletes":[{"q":{"r":"rm"},"limit":{"$numberDouble":"Infinity"}}]}');
select count(*) from blackboxdb_api.collection('db', 'del_limit');

-- out-of-range whole numbers are rejected
select blackboxdb_api.delete('db', '{"delete":"del_limit", "deletes":[{"q":{"r":"rm"},"limit":2}]}');
select blackboxdb_api.delete('db', '{"delete":"del_limit", "deletes":[{"q":{"r":"rm"},"limit":-1}]}');

-- non-numeric limit is treated as 0
begin;
select blackboxdb_api.delete('db', '{"delete":"del_limit", "deletes":[{"q":{"r":"rm"},"limit":"x"}]}');
select count(*) from blackboxdb_api.collection('db', 'del_limit');
rollback;

select blackboxdb_api.drop_collection('db', 'del_limit');