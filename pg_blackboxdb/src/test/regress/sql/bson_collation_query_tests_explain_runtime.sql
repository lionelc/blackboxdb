SET citus.next_shard_id TO 8900000;
SET blackboxdb.next_collection_id TO 8900;
SET blackboxdb.next_collection_index_id TO 8900;

SET search_path TO blackboxdb_api,blackboxdb_core,blackboxdb_api_catalog;
SET blackboxdb_core.enableCollation TO on;
SET blackboxdb.enableExtendedExplainPlans TO on;

SELECT blackboxdb_api.insert_one('coll_q_runtime_explain_db', 'coll_simple', '{ "_id": 1, "a": "cat" }');
SELECT blackboxdb_api.insert_one('coll_q_runtime_explain_db', 'coll_simple', '{ "_id": 2, "a": "Cat" }');
SELECT blackboxdb_api.insert_one('coll_q_runtime_explain_db', 'coll_simple', '{ "_id": 3, "a": "DOG" }');
SELECT blackboxdb_api.insert_one('coll_q_runtime_explain_db', 'coll_simple', '{ "_id": 4, "a": "dog" }');
SELECT blackboxdb_api.insert_one('coll_q_runtime_explain_db', 'coll_simple', '{ "_id": 5, "a": "rabbit" }');

-- find with collation on equality predicate
SELECT blackboxdb_test_helpers.run_explain_and_trim($cmd$ EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('coll_q_runtime_explain_db', '{ "find": "coll_simple", "filter": { "a": "CAT" }, "sort": { "_id": 1 }, "collation": { "locale": "en", "strength": 1 } }') $cmd$);

-- find with $expr equality on collation
SELECT blackboxdb_test_helpers.run_explain_and_trim($cmd$ EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('coll_q_runtime_explain_db', '{ "find": "coll_simple", "filter": { "$expr": {"$eq": ["$a", "CAT"]} }, "sort": { "_id": 1 }, "collation": { "locale": "en", "strength": 1 } }') $cmd$);

-- find with $expr inequality on collation (different locale)
SELECT blackboxdb_test_helpers.run_explain_and_trim($cmd$ EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('coll_q_runtime_explain_db', '{ "find": "coll_simple", "filter": { "$expr": {"$gte": ["$a", "CAT"]} }, "sort": { "_id": 1 }, "collation": { "locale": "fr", "strength": 1 } }') $cmd$);

-- aggregation pipeline with $match and collation
SELECT blackboxdb_test_helpers.run_explain_and_trim($cmd$ EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_pipeline('coll_q_runtime_explain_db', '{ "aggregate": "coll_simple", "pipeline": [ { "$match": { "a": "DOG" } }, { "$sort": { "_id": 1 } } ], "cursor": {}, "collation": { "locale": "en", "strength": 1 } }') $cmd$);
