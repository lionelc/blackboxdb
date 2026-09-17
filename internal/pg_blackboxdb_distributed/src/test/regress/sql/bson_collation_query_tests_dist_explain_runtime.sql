SET search_path TO blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog,blackboxdb_api_internal;
SET citus.next_shard_id TO 95680000;
SET blackboxdb.next_collection_id TO 95680;
SET blackboxdb.next_collection_index_id TO 95680;

SELECT blackboxdb_api.insert_one('coll_q_runtime_dist_explain_db', 'coll_simple_d', '{ "_id": 1, "a": "cat" }');
SELECT blackboxdb_api.insert_one('coll_q_runtime_dist_explain_db', 'coll_simple_d', '{ "_id": 2, "a": "Cat" }');
SELECT blackboxdb_api.insert_one('coll_q_runtime_dist_explain_db', 'coll_simple_d', '{ "_id": 3, "a": "DOG" }');
SELECT blackboxdb_api.insert_one('coll_q_runtime_dist_explain_db', 'coll_simple_d', '{ "_id": 4, "a": "dog" }');

SELECT blackboxdb_api.shard_collection('coll_q_runtime_dist_explain_db', 'coll_simple_d', '{ "_id": "hashed" }', false);

-- find with collation on equality predicate
BEGIN;
SET LOCAL blackboxdb_core.enableCollation TO on;
SET LOCAL blackboxdb.enableExtendedExplainPlans TO on;
SELECT blackboxdb_distributed_test_helpers.run_explain_and_trim($cmd$ EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('coll_q_runtime_dist_explain_db', '{ "find": "coll_simple_d", "filter": { "a": "CAT" }, "sort": { "_id": 1 }, "collation": { "locale": "en", "strength": 1 } }') $cmd$);
END;

-- $expr equality with collation
BEGIN;
SET LOCAL blackboxdb_core.enableCollation TO on;
SET LOCAL blackboxdb.enableExtendedExplainPlans TO on;
SELECT blackboxdb_distributed_test_helpers.run_explain_and_trim($cmd$ EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('coll_q_runtime_dist_explain_db', '{ "find": "coll_simple_d", "filter": { "$expr": {"$eq": ["$a", "CAT"]} }, "sort": { "_id": 1 }, "collation": { "locale": "en", "strength": 1 } }') $cmd$);
END;

-- aggregation pipeline with $match and collation
BEGIN;
SET LOCAL blackboxdb_core.enableCollation TO on;
SET LOCAL blackboxdb.enableExtendedExplainPlans TO on;
SELECT blackboxdb_distributed_test_helpers.run_explain_and_trim($cmd$ EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_pipeline('coll_q_runtime_dist_explain_db', '{ "aggregate": "coll_simple_d", "pipeline": [ { "$match": { "a": "DOG" } }, { "$sort": { "_id": 1 } } ], "cursor": {}, "collation": { "locale": "en", "strength": 1 } }') $cmd$);
END;
