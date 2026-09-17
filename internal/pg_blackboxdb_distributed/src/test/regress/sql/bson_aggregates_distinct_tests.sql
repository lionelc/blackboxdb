SET search_path TO blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog,blackboxdb_api_internal;
SET citus.next_shard_id TO 6630000;
SET blackboxdb.next_collection_id TO 6630;
SET blackboxdb.next_collection_index_id TO 6630;

SELECT blackboxdb_api.insert_one('db', 'distinct1', '{ "a": 1, "b": { "c": "foo" } }');
SELECT blackboxdb_api.insert_one('db', 'distinct1', '{ "a": 2, "b": { "c": "bar" } }');
SELECT blackboxdb_api.insert_one('db', 'distinct1', '{ "a": 2, "b": { "c": "baz" } }');
SELECT blackboxdb_api.insert_one('db', 'distinct1', '{ "a": 2, "b": { "c": "foo" } }');
SELECT blackboxdb_api.insert_one('db', 'distinct1', '{ "a": 3, "b": { "c": "foo" } }');

-- this is what the query will look like from the GW. The distinct values have
-- no inherent order (the source collections are sharded, so array_agg receives
-- rows in an environment-dependent order); an ORDER BY inside array_agg makes the
-- assembled values array deterministic without changing the distinct value set.
PREPARE distinctQuery(text, text, text) AS (WITH r1 AS (SELECT DISTINCT 
    bson_distinct_unwind(document, $3) AS document FROM blackboxdb_api.collection($1, $2)) 
    SELECT bson_build_distinct_response(COALESCE(array_agg(document ORDER BY document), '{}'::bson[])) FROM r1);

PREPARE distinctQueryWithFilter(text, text, text, bson) AS (WITH r1 AS (SELECT DISTINCT 
    bson_distinct_unwind(document, $3) AS document FROM blackboxdb_api.collection($1, $2) WHERE document @@ $4 )
    SELECT bson_build_distinct_response(COALESCE(array_agg(document ORDER BY document), '{}'::bson[])) FROM r1);

-- Plan-shaped variant used only for EXPLAIN below: it mirrors the query the
-- client actually issues (no ORDER BY inside array_agg), so the demonstrated
-- plan stays representative and stable across PG versions. The ORDER BY in the
-- variants above is purely for deterministic value output and would otherwise
-- let newer planners fold the DISTINCT and the aggregate sort into a single
-- Sort+Unique, diverging from the HashAggregate plan on other versions.
PREPARE distinctQueryWithFilterPlan(text, text, text, bson) AS (WITH r1 AS (SELECT DISTINCT 
    bson_distinct_unwind(document, $3) AS document FROM blackboxdb_api.collection($1, $2) WHERE document @@ $4 )
    SELECT bson_build_distinct_response(COALESCE(array_agg(document), '{}'::bson[])) FROM r1);

EXECUTE distinctQuery('db', 'distinct1', 'a');
EXECUTE distinctQueryWithFilter('db', 'distinct1', 'a', '{ "a": { "$lt": 3 }}');

EXECUTE distinctQuery('db', 'distinct1', 'b.c');

SELECT blackboxdb_api.insert_one('db', 'distinct2', '{ "a": null }');
EXECUTE distinctQuery('db', 'distinct2', 'a.b');

SELECT blackboxdb_api.insert_one('db', 'distinct2', '{ "b": 1 }');
SELECT blackboxdb_api.insert_one('db', 'distinct2', '{ }');
EXECUTE distinctQuery('db', 'distinct2', 'b');


SELECT blackboxdb_api.insert_one('db', 'distinct3', '{ "a": [ 1, 2, 3 ] }');
SELECT blackboxdb_api.insert_one('db', 'distinct3', '{ "a": [ 2, 3, 4 ] }');
SELECT blackboxdb_api.insert_one('db', 'distinct3', '{ "a": [ 3, 4, 5 ] }');
SELECT blackboxdb_api.insert_one('db', 'distinct3', '{ "a": 9 }');

EXECUTE distinctQuery('db', 'distinct3', 'a');
EXECUTE distinctQuery('db', 'distinct3', 'a.0');
EXECUTE distinctQuery('db', 'distinct3', 'a.1');

SELECT blackboxdb_api.insert_one('db', 'distinct3', '{ "e": [ { "b": "a" }, { "b": "d"} ], "c": 12 }');
SELECT blackboxdb_api.insert_one('db', 'distinct3', '{ "e": [ { "b": "b" }, { "b": "d"} ], "c": 12 }');
SELECT blackboxdb_api.insert_one('db', 'distinct3', '{ "e": [ { "b": "c" }, { "b": "e"} ], "c": 12 }');
SELECT blackboxdb_api.insert_one('db', 'distinct3', '{ "e": [ { "b": "c" }, { "b": "f"} ], "c": 12 }');
SELECT blackboxdb_api.insert_one('db', 'distinct3', '{ "e": [  ], "c": 12 }');
SELECT blackboxdb_api.insert_one('db', 'distinct3', '{ "e": { "b": "z" }, "c": 12 }');

EXECUTE distinctQuery('db', 'distinct3', 'e.b');

EXECUTE distinctQuery('db', 'distinct3', 'e.0.b');
EXECUTE distinctQuery('db', 'distinct3', 'e.1.b');

EXECUTE distinctQuery('db', 'distinct3', 'e');

EXECUTE distinctQueryWithFilter('db', 'distinct3', 'e.b', '{ "e.b": { "$gt": "d" } }');


SELECT blackboxdb_api.insert_one('db', 'distinct4', '{ "a": { "b": { "c": 1 } } }');
SELECT blackboxdb_api.insert_one('db', 'distinct4', '{ "a": { "b": { "c": 2 } } }');
SELECT blackboxdb_api.insert_one('db', 'distinct4', '{ "a": { "b": { "c": 3 } } }');
SELECT blackboxdb_api.insert_one('db', 'distinct4', '{ "a": { "b": { "notRelevant": 3 } } }');
SELECT blackboxdb_api.insert_one('db', 'distinct4', '{ "a": { "notRelevant": 3 } }');

EXECUTE distinctQueryWithFilter('db', 'distinct4', 'a.b.c', '{ "a.b.c": { "$gt": 0 } }');
EXECUTE distinctQueryWithFilter('db', 'distinct4', 'a.b.c', '{ "a.b.c": { "$gt": 1 } }');

-- test for DBRef
SELECT blackboxdb_api.insert_one('db', 'distinct5', '{ "a": 1, "b": { "$ref" : "distinct6", "$id" : { "$oid" : "147f000000c1de008ec19ceb" }}}');
select blackboxdb_api.insert_one('db', 'distinct5', '{ "a": 2, "b": { "$ref" : "distinct6", "$id" : { "$oid" : "147f000000c1de008ec19cea" }}}');
select blackboxdb_api.insert_one('db', 'distinct5', '{ "a": 3, "b": { "$ref" : "distinct6", "$id" : { "$oid" : "147f000000c1de008ec19cea" }}}');
select blackboxdb_api.insert_one('db', 'distinct6', '{ "_id": { "$oid" : "147f000000c1de008ec19cea" }, "c": 1}');
select blackboxdb_api.insert_one('db', 'distinct6', '{ "_id": { "$oid" : "147f000000c1de008ec19ceb" }, "c": 2}');

EXECUTE distinctQueryWithFilter('db', 'distinct5', 'a', '{ "b": { "$ref": "distinct6", "$id": { "$oid" : "147f000000c1de008ec19ceb" } } }');
EXECUTE distinctQueryWithFilter('db', 'distinct5', 'a', '{ "b": { "$ref": "distinct6", "$id": { "$oid" : "147f000000c1de008ec19cea" } } }');

-- optional parameter - $db
SELECT blackboxdb_api.insert_one('db2', 'distinct7', '{ "d": 20, "b": { "$ref" : "distinct6", "$id" : { "$oid" : "147f000000c1de008ec19ceb" }, "$db": "db" }}');
SELECT blackboxdb_api.insert_one('db2', 'distinct7', '{ "d": 30, "b": { "$ref" : "distinct6", "$id" : { "$oid" : "147f000000c1de008ec19ceb" }}}');
-- expect to get 20
EXECUTE distinctQueryWithFilter('db2', 'distinct7', 'd', '{ "b": { "$ref": "distinct6", "$id": { "$oid" : "147f000000c1de008ec19ceb" }, "$db": "db" } }');
-- expect to get 30
EXECUTE distinctQueryWithFilter('db2', 'distinct7', 'd', '{ "b": { "$ref": "distinct6", "$id": { "$oid" : "147f000000c1de008ec19ceb" } } }');

SELECT blackboxdb_api.insert_one('db2', 'distinct7', '{ "d": 1, "b": { "$ref" : "distinct6", "$id" : { "$oid" : "147f000000c1de008ec19ce1" }}}');
SELECT blackboxdb_api.insert_one('db2', 'distinct7', '{ "d": 2, "b": { "$ref" : "distinct6", "$id" : { "$oid" : "147f000000c1de008ec19ce2" }}}');
SELECT blackboxdb_api.insert_one('db2', 'distinct7', '{ "d": 3, "b": { "$id" : { "$oid" : "147f000000c1de008ec19ce3" }, "$ref" : "distinct6" }}');
SELECT blackboxdb_api.insert_one('db2', 'distinct7', '{ "d": 4, "b": { "$ref" : "distinct6", "$id" : { "$oid" : "147f000000c1de008ec19ce4" }}}');
SELECT blackboxdb_api.insert_one('db2', 'distinct7', '{ "d": 5, "b": { "$ref" : "distinct6", "$id" : { "$oid" : "147f000000c1de008ec19ce5" }}}');
SELECT blackboxdb_api.insert_one('db2', 'distinct7', '{ "d": 6, "b": { "$ref" : "distinct6", "$id" : { "$oid" : "147f000000c1de008ec19ce6" }}}');
SELECT blackboxdb_api.insert_one('db2', 'distinct7', '{ "d": 7, "b": { "$ref" : "distinct6", "$id" : { "$oid" : "147f000000c1de008ec19ce6" }, "$db": "db", "tt":1}}');

-- expect to get 3
EXECUTE distinctQueryWithFilter('db2', 'distinct7', 'd', '{ "b": {"$id": { "$oid" : "147f000000c1de008ec19ce3" }, "$ref" : "distinct6"} }');

-- expect to get 7
EXECUTE distinctQueryWithFilter('db2', 'distinct7', 'd', '{ "b": { "$ref": "distinct6", "$id": { "$oid" : "147f000000c1de008ec19ce6" },"$db": "db", "tt":1 } }');

-- expect to get null
EXECUTE distinctQueryWithFilter('db2', 'distinct7', 'd', '{ "b": { "$ref": "distinct6", "$id": { "$oid" : "147f000000c1de008ec19ce6" },"$db": "db" } }');

-- expect to work in $in/$nin
EXECUTE distinctQueryWithFilter('db2', 'distinct7', 'd', '{ "b": { "$in": [ { "$ref": "distinct6", "$id": { "$oid" : "147f000000c1de008ec19ce6" },"$db": "db", "tt":1 }, { "$ref": "distinct6", "$id": { "$oid" : "147f000000c1de008ec19ce4" }} ] } }');
EXECUTE distinctQueryWithFilter('db2', 'distinct7', 'd', '{ "b": { "$nin": [ { "$ref": "distinct6", "$id": { "$oid" : "147f000000c1de008ec19ce6" },"$db": "db", "tt":1 }, { "$ref": "distinct6", "$id": { "$oid" : "147f000000c1de008ec19ce4" }} ] } }');

-- index
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db2', '{ "createIndexes": "distinct7", "indexes": [ { "key": { "b": 1 }, "name": "ref_idx" } ] }', true);
ANALYZE;
begin;
SET LOCAL enable_seqscan to off;
SELECT blackboxdb_distributed_test_helpers.run_explain_and_trim($cmd$ EXPLAIN (COSTS OFF, BUFFERS OFF, ANALYZE ON, TIMING OFF, SUMMARY OFF) EXECUTE distinctQueryWithFilterPlan('db2', 'distinct7', 'd', '{ "b": { "$ref": "distinct6", "$id": { "$oid" : "147f000000c1de008ec19ce4" } } }') $cmd$);
SELECT blackboxdb_distributed_test_helpers.run_explain_and_trim($cmd$ EXPLAIN (COSTS OFF, BUFFERS OFF, ANALYZE ON, TIMING OFF, SUMMARY OFF) EXECUTE distinctQueryWithFilterPlan('db2', 'distinct7', 'd', '{ "b": { "$ref": "distinct6", "$id": { "$oid" : "147f000000c1de008ec19ce6" },"$db": "db", "tt":1 } }') $cmd$);
SELECT blackboxdb_distributed_test_helpers.run_explain_and_trim($cmd$ EXPLAIN (COSTS OFF, BUFFERS OFF, ANALYZE ON, TIMING OFF, SUMMARY OFF) EXECUTE distinctQueryWithFilterPlan('db2', 'distinct7', 'd', '{ "b": {"$id": { "$oid" : "147f000000c1de008ec19ce6" }, "$ref" : "distinct6"}}') $cmd$);
SELECT blackboxdb_distributed_test_helpers.run_explain_and_trim($cmd$ EXPLAIN (COSTS OFF, BUFFERS OFF, ANALYZE ON, TIMING OFF, SUMMARY OFF) EXECUTE distinctQueryWithFilterPlan('db2', 'distinct7', 'd', '{ "b": { "$in": [ { "$ref": "distinct6", "$id": { "$oid" : "147f000000c1de008ec19ce6" },"$db": "db", "tt":1 }, { "$ref": "distinct6", "$id": { "$oid" : "147f000000c1de008ec19ce4" }} ] } }') $cmd$);
commit;
