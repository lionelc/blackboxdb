SET search_path TO blackboxdb_api_catalog, blackboxdb_api, blackboxdb_api_internal, blackboxdb_core, public;
SET blackboxdb.next_collection_id TO 1984000;
SET blackboxdb.next_collection_index_id TO 1984000;

-- Insert test data
SELECT blackboxdb_api.insert_one('db', 'rewrite_sql_test', '{ "_id": 1, "country": "Mexico", "city": "CDMX" }');
SELECT blackboxdb_api.insert_one('db', 'rewrite_sql_test', '{ "_id": 2, "country": "USA", "city": "NYC" }');

-- Test aggregate with $match
SELECT blackboxdb_api_internal.bson_get_rewritten_sql('db',
  '{ "aggregate": "rewrite_sql_test", "pipeline": [{ "$match": { "country": "Mexico" } }], "cursor": {} }'::blackboxdb_core.bson);

-- Test aggregate with $project and $limit
SELECT blackboxdb_api_internal.bson_get_rewritten_sql('db',
  '{ "aggregate": "rewrite_sql_test", "pipeline": [{ "$project": { "country": 1 } }, { "$limit": 10 }], "cursor": {} }'::blackboxdb_core.bson);

-- Test find with filter
SELECT blackboxdb_api_internal.bson_get_rewritten_sql('db',
  '{ "find": "rewrite_sql_test", "filter": { "country": "Mexico" } }'::blackboxdb_core.bson);

-- Test find with filter, projection, sort, skip, limit
SELECT blackboxdb_api_internal.bson_get_rewritten_sql('db',
  '{ "find": "rewrite_sql_test", "filter": { "_id": { "$gt": 0 } }, "projection": { "country": 1 }, "sort": { "_id": 1 }, "skip": 0, "limit": 5 }'::blackboxdb_core.bson);

-- Test count
SELECT blackboxdb_api_internal.bson_get_rewritten_sql('db',
  '{ "count": "rewrite_sql_test" }'::blackboxdb_core.bson);

-- Test count with query filter
SELECT blackboxdb_api_internal.bson_get_rewritten_sql('db',
  '{ "count": "rewrite_sql_test", "query": { "country": "Mexico" } }'::blackboxdb_core.bson);

-- Test distinct
SELECT blackboxdb_api_internal.bson_get_rewritten_sql('db',
  '{ "distinct": "rewrite_sql_test", "key": "country" }'::blackboxdb_core.bson);

-- Test error on unsupported command type
SELECT blackboxdb_api_internal.bson_get_rewritten_sql('db',
  '{ "unsupported": "rewrite_sql_test" }'::blackboxdb_core.bson);

-- Test error on empty spec
SELECT blackboxdb_api_internal.bson_get_rewritten_sql('db',
  '{ }'::blackboxdb_core.bson);
