SET search_path TO blackboxdb_api,blackboxdb_core,blackboxdb_api_catalog;

SET blackboxdb.next_collection_id TO 26900000;
SET blackboxdb.next_collection_index_id TO 26900000;

-- 30 documents with string _ids (str_1..str_20, abc_1..abc_10), a field v and a field _idx.
DO $$
DECLARE i int;
BEGIN
FOR i IN 1..20 LOOP
PERFORM blackboxdb_api.insert_one('skfdb', 'items', FORMAT('{ "_id": "str_%s", "v": %s, "_idx": %s }', i, i, i % 7)::blackboxdb_core.bson);
END LOOP;
FOR i IN 1..10 LOOP
PERFORM blackboxdb_api.insert_one('skfdb', 'items', FORMAT('{ "_id": "abc_%s", "v": %s, "_idx": %s }', i, i, i % 7)::blackboxdb_core.bson);
END LOOP;
END;
$$;

-- With the shard key condition skipped on the base table, every filter on _id must keep the primary key index.
-- Sequential scans are disabled, so a lost index path raises an error. Each filter runs with the flag off, then on.
SET blackboxdb.forceDisableSeqScan TO on;
SET blackboxdb.enableAddShardKeyOnlyOnPrimaryKeyFilters TO off;
SELECT document FROM bson_aggregation_find('skfdb', '{ "find": "items", "filter": { "_id": { "$regex": "^str_1" } }, "sort": { "_id": 1 } }');
SET blackboxdb.enableAddShardKeyOnlyOnPrimaryKeyFilters TO on;
SELECT document FROM bson_aggregation_find('skfdb', '{ "find": "items", "filter": { "_id": { "$regex": "^str_1" } }, "sort": { "_id": 1 } }');
SET blackboxdb.enableAddShardKeyOnlyOnPrimaryKeyFilters TO off;
SELECT document FROM bson_aggregation_find('skfdb', '{ "find": "items", "filter": { "_id": { "$gte": "str_15", "$lt": "str_3" } }, "sort": { "_id": 1 } }');
SET blackboxdb.enableAddShardKeyOnlyOnPrimaryKeyFilters TO on;
SELECT document FROM bson_aggregation_find('skfdb', '{ "find": "items", "filter": { "_id": { "$gte": "str_15", "$lt": "str_3" } }, "sort": { "_id": 1 } }');
SET blackboxdb.enableAddShardKeyOnlyOnPrimaryKeyFilters TO off;
SELECT document FROM bson_aggregation_find('skfdb', '{ "find": "items", "filter": { "_id": "str_7" }, "sort": { "_id": 1 } }');
SET blackboxdb.enableAddShardKeyOnlyOnPrimaryKeyFilters TO on;
SELECT document FROM bson_aggregation_find('skfdb', '{ "find": "items", "filter": { "_id": "str_7" }, "sort": { "_id": 1 } }');
SET blackboxdb.enableAddShardKeyOnlyOnPrimaryKeyFilters TO off;
SELECT document FROM bson_aggregation_find('skfdb', '{ "find": "items", "filter": { "$or": [ { "_id": "abc_2" }, { "_id": { "$regex": "^str_2" } } ] }, "sort": { "_id": 1 } }');
SET blackboxdb.enableAddShardKeyOnlyOnPrimaryKeyFilters TO on;
SELECT document FROM bson_aggregation_find('skfdb', '{ "find": "items", "filter": { "$or": [ { "_id": "abc_2" }, { "_id": { "$regex": "^str_2" } } ] }, "sort": { "_id": 1 } }');
SET blackboxdb.enableAddShardKeyOnlyOnPrimaryKeyFilters TO off;
SELECT document FROM bson_aggregation_find('skfdb', '{ "find": "items", "filter": { "$and": [ { "_id": { "$regex": "^abc" } }, { "v": { "$gt": 3 } } ] }, "sort": { "_id": 1 } }');
SET blackboxdb.enableAddShardKeyOnlyOnPrimaryKeyFilters TO on;
SELECT document FROM bson_aggregation_find('skfdb', '{ "find": "items", "filter": { "$and": [ { "_id": { "$regex": "^abc" } }, { "v": { "$gt": 3 } } ] }, "sort": { "_id": 1 } }');
SET blackboxdb.enableAddShardKeyOnlyOnPrimaryKeyFilters TO off;
SELECT document FROM bson_aggregation_find('skfdb', '{ "find": "items", "filter": { "$and": [ { "_id": { "$regex": "^str_2" } } ] }, "sort": { "_id": 1 } }');
SET blackboxdb.enableAddShardKeyOnlyOnPrimaryKeyFilters TO on;
SELECT document FROM bson_aggregation_find('skfdb', '{ "find": "items", "filter": { "$and": [ { "_id": { "$regex": "^str_2" } } ] }, "sort": { "_id": 1 } }');
RESET blackboxdb.forceDisableSeqScan;

-- The plans (no sort on _id, which would add the condition back by itself): a prefix $regex, a $regex inside $and,
-- a range and a point read keep the shard key condition in the index scan; a filter that does not reference _id
-- (v, or a field merely starting with _id) drops it.
SET blackboxdb.enableAddShardKeyOnlyOnPrimaryKeyFilters TO on;
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('skfdb', '{ "find": "items", "filter": { "_id": { "$regex": "^str_1" } } }');
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('skfdb', '{ "find": "items", "filter": { "$and": [ { "_id": { "$regex": "^str_2" } } ] } }');
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('skfdb', '{ "find": "items", "filter": { "_id": { "$gte": "str_15", "$lt": "str_3" } } }');
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('skfdb', '{ "find": "items", "filter": { "_id": "str_7" } }');
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('skfdb', '{ "find": "items", "filter": { "v": { "$gt": 25 } } }');
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('skfdb', '{ "find": "items", "filter": { "_idx": 5 } }');
SET blackboxdb.enableAddShardKeyOnlyOnPrimaryKeyFilters TO off;
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('skfdb', '{ "find": "items", "filter": { "v": { "$gt": 25 } } }');
RESET blackboxdb.enableAddShardKeyOnlyOnPrimaryKeyFilters;
