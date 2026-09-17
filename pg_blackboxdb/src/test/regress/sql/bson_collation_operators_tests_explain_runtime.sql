SET citus.next_shard_id TO 9600000;
SET blackboxdb.next_collection_id TO 9600;
SET blackboxdb.next_collection_index_id TO 9600;

SET search_path TO blackboxdb_api,blackboxdb_core,blackboxdb_api_catalog;
SET blackboxdb_core.enableCollation TO on;
SET blackboxdb.enableExtendedExplainPlans TO on;

SELECT blackboxdb_api.insert_one('coll_operators_runtime_explain_db','single_field', '{"_id": 1, "a": "apple"}', NULL);
SELECT blackboxdb_api.insert_one('coll_operators_runtime_explain_db','single_field', '{"_id": 2, "a": "Apple"}', NULL);
SELECT blackboxdb_api.insert_one('coll_operators_runtime_explain_db','single_field', '{"_id": 3, "a": "BANANA"}', NULL);
SELECT blackboxdb_api.insert_one('coll_operators_runtime_explain_db','single_field', '{"_id": 4, "a": "banana"}', NULL);
SELECT blackboxdb_api.insert_one('coll_operators_runtime_explain_db','single_field', '{"_id": 5, "a": "cherry"}', NULL);
SELECT blackboxdb_api.insert_one('coll_operators_runtime_explain_db','single_field', '{"_id": 6, "a": 42}', NULL);

-- $eq with collation
SELECT blackboxdb_test_helpers.run_explain_and_trim($cmd$ EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('coll_operators_runtime_explain_db', '{ "find": "single_field", "filter": { "a": { "$eq": "Apple" } }, "collation": { "locale": "en", "strength": 1 } }') $cmd$);

-- $gt with collation
SELECT blackboxdb_test_helpers.run_explain_and_trim($cmd$ EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('coll_operators_runtime_explain_db', '{ "find": "single_field", "filter": { "a": { "$gt": "banana" } }, "collation": { "locale": "en", "strength": 1 } }') $cmd$);

-- $ne with collation
SELECT blackboxdb_test_helpers.run_explain_and_trim($cmd$ EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('coll_operators_runtime_explain_db', '{ "find": "single_field", "filter": { "a": { "$ne": "apple" } }, "collation": { "locale": "en", "strength": 1 } }') $cmd$);

-- $not on $gt with collation
SELECT blackboxdb_test_helpers.run_explain_and_trim($cmd$ EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('coll_operators_runtime_explain_db', '{ "find": "single_field", "filter": { "a": { "$not": { "$gt": "BANANA" } } }, "collation": { "locale": "en", "strength": 1 } }') $cmd$);

-- $not on $lte with collation
SELECT blackboxdb_test_helpers.run_explain_and_trim($cmd$ EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('coll_operators_runtime_explain_db', '{ "find": "single_field", "filter": { "a": { "$not": { "$lte": "banana" } } }, "collation": { "locale": "en", "strength": 1 } }') $cmd$);

-- $not $lt against numeric (non-string operand bypasses collation)
SELECT blackboxdb_test_helpers.run_explain_and_trim($cmd$ EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('coll_operators_runtime_explain_db', '{ "find": "single_field", "filter": { "a": { "$not": { "$lt": 100 } } }, "collation": { "locale": "en", "strength": 1 } }') $cmd$);
