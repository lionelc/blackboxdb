SET search_path TO blackboxdb_api,blackboxdb_core;

SET blackboxdb.next_collection_id TO 7000;
SET blackboxdb.next_collection_index_id TO 7000;


-- default commands on config database
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('config', '{ "find": "version", "projection": { } }');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('config', '{ "find": "databases", "projection": { }, "sort": { "name": 1 } }');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('config', '{ "find": "collections", "projection": { }, "sort": { "name": 1 } }');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('config', '{ "find": "chunks", "projection": { } }');

-- create 1 db 2 colls.
SELECT blackboxdb_api.create_collection('test', 'my_coll1');
SELECT blackboxdb_api.create_collection('test', 'my_coll2');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('config', '{ "find": "databases", "projection": { }, "sort": { "name": 1 } }');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('config', '{ "find": "collections", "projection": { }, "sort": { "name": 1 } }');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('config', '{ "find": "chunks", "projection": { } }');

-- add second db
SELECT blackboxdb_api.create_collection('test2', 'my_coll1');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('config', '{ "find": "databases", "projection": { }, "sort": { "name": 1 } }');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('config', '{ "find": "collections", "projection": { }, "sort": { "name": 1 } }');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('config', '{ "find": "chunks", "projection": { } }');

-- now shard mycoll1
SELECT blackboxdb_api.shard_collection('test2', 'my_coll1', '{ "nameValue": "hashed" }', false);
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('config', '{ "find": "databases", "projection": { }, "sort": { "name": 1 } }');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('config', '{ "find": "collections", "projection": { }, "sort": { "name": 1 } }');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('config', '{ "find": "chunks", "projection": { } }');
