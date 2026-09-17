SET citus.next_shard_id TO 111000;
SET blackboxdb.next_collection_id TO 11100;
SET blackboxdb.next_collection_index_id TO 11100;

SET search_path TO blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog,blackboxdb_api_internal;

-- first create a collection (invalid)
SELECT blackboxdb_api.create_collection_view('db', '{ "create": "create_view_tests", "capped": true }');
SELECT blackboxdb_api.create_collection_view('db', '{ "create": "create_view_tests", "capped": 1}');
SELECT blackboxdb_api.create_collection_view('db', '{ "create": "create_view_tests", "capped": 2.3}');
SELECT blackboxdb_api.create_collection_view('db', '{ "create": "create_view_tests", "capped": "true"}');
SELECT blackboxdb_api.create_collection_view('db', '{ "create": "create_view_tests", "capped": "false"}');
SELECT blackboxdb_api.create_collection_view('db', '{ "create": "create_view_tests", "timeseries": { "timeField": "a" } }');
SELECT blackboxdb_api.create_collection_view('db', '{ "create": "create_view_tests", "clusteredIndex": { } }');
SELECT blackboxdb_api.create_collection_view('db', '{ "create": 2 }');
SELECT blackboxdb_api.create_collection_view('db', '{ "create": false }');
SELECT blackboxdb_api.create_collection_view('db', '{ "create": null }');
SELECT blackboxdb_api.create_collection_view('db', '{ "create": {"$undefined": true} }');
SELECT blackboxdb_api.create_collection_view('db', '{ "create": "" }');   -- empty string not allowed

-- create valid collections
SELECT blackboxdb_api.create_collection_view('db', '{ "create": "create_view_tests_not_capped1", "capped": false}');
SELECT blackboxdb_api.create_collection_view('db', '{ "create": "create_view_tests_not_capped2", "capped": 0}');
SELECT blackboxdb_api.create_collection_view('db', '{ "create": "create_view_tests_emoji_👽" }');
SELECT blackboxdb_api.create_collection_view('db', '{ "create": "create_view_tests" }');

-- noops
SELECT blackboxdb_api.create_collection_view('db', '{ "create": "create_view_tests" }');

-- Views error out if the viewOn is not a string, or empty string
SELECT blackboxdb_api.create_collection_view('db', '{ "create": "create_view_tests_view", "viewOn": 2 }');
SELECT blackboxdb_api.create_collection_view('db', '{ "create": "create_view_tests_view", "viewOn": false }');
SELECT blackboxdb_api.create_collection_view('db', '{ "create": "create_view_tests_view", "viewOn": "" }');   -- empty string not allowed

-- viewOn can be null or undefined. It is treated as if it was not specified
SELECT blackboxdb_api.create_collection_view('db', '{ "create": "create_view_tests_view_n",  "viewOn": null }');
SELECT blackboxdb_api.create_collection_view('db', '{ "create": "create_view_tests_view_np", "viewOn": null, "pipeline": [] }');
SELECT blackboxdb_api.create_collection_view('db', '{ "create": "create_view_tests_view_u",  "viewOn": {"$undefined": true} }');
SELECT blackboxdb_api.create_collection_view('db', '{ "create": "create_view_tests_view_up", "viewOn": {"$undefined": true}, "pipeline": [] }');


-- create a view against it (no pipeline): succeeds
SELECT blackboxdb_api.create_collection_view('db', '{ "create": "create_view_tests_view_1", "viewOn": "create_view_tests" }');
SELECT blackboxdb_api.create_collection_view('db', '{ "create": "create_view_tests_view_emoji_👺", "viewOn": "create_view_tests_emoji_👽" }');

-- chain the view
SELECT blackboxdb_api.create_collection_view('db', '{ "create": "create_view_tests_view_2", "viewOn": "create_view_tests_view_1", "pipeline": [ { "$match": { "a": { "$gt": 5 } } } ] }');

-- chain one more view
SELECT blackboxdb_api.create_collection_view('db', '{ "create": "create_view_tests_view_3", "viewOn": "create_view_tests_view_2", "pipeline": [ { "$sort": { "a": 1 } } ] }');

-- query all 4
SELECT document FROM bson_aggregation_find('db', '{ "find": "create_view_tests_view_3" }');
SELECT document FROM bson_aggregation_find('db', '{ "find": "create_view_tests_view_2" }');
SELECT document FROM bson_aggregation_find('db', '{ "find": "create_view_tests_view_1" }');
SELECT document FROM bson_aggregation_find('db', '{ "find": "create_view_tests" }');

-- now insert 3 docs in the table 
SELECT blackboxdb_api.insert_one('db', 'create_view_tests', '{ "_id": 1, "a": 4 }');
SELECT blackboxdb_api.insert_one('db', 'create_view_tests', '{ "_id": 2, "a": 1 }');
SELECT blackboxdb_api.insert_one('db', 'create_view_tests', '{ "_id": 3, "a": 140 }');
SELECT blackboxdb_api.insert_one('db', 'create_view_tests', '{ "_id": 4, "a": 40 }');

SELECT document FROM bson_aggregation_find('db', '{ "find": "create_view_tests_view_3" }');
SELECT document FROM bson_aggregation_find('db', '{ "find": "create_view_tests_view_2" }');
SELECT document FROM bson_aggregation_find('db', '{ "find": "create_view_tests_view_1" }');
SELECT document FROM bson_aggregation_find('db', '{ "find": "create_view_tests" }');


-- create views with different options
SELECT blackboxdb_api.create_collection_view('db', '{ "create": "create_view_tests", "viewOn": "create_view_tests_view_5", "pipeline": [ { "$sort": { "a": 1 } } ] }');


-- Can't write to views
SELECT blackboxdb_api.insert_one('db', 'create_view_tests_view_1', '{ "_id": 5, "a": 60 }');
SELECT blackboxdb_api.update('db', '{ "update": "create_view_tests_view_1", "updates": [ { "q": {}, "u": {} } ] }');
SELECT blackboxdb_api.delete('db', '{ "delete": "create_view_tests_view_1", "deletes": [ { "q": {}, "limit": 1 } ] }');

SELECT blackboxdb_api.shard_collection('db', 'create_view_tests_view_1', '{ "_id": "hashed" }', false);
SELECT blackboxdb_api.shard_collection('db', 'create_view_tests_view_1', '{ "_id": "hashed" }', true);

-- can drop/rename a view
SELECT blackboxdb_api.rename_collection('db', 'create_view_tests_view_1', 'create_view_tests_view_4');
SELECT document FROM bson_aggregation_find('db', '{ "find": "create_view_tests_view_1" }');
SELECT blackboxdb_api.drop_collection('db', 'create_view_tests_view_3');

-- drop the collection (view still works)
SELECT blackboxdb_api.drop_collection('db', 'create_view_tests');
SELECT document FROM bson_aggregation_find('db', '{ "find": "create_view_tests_view_1" }');

-- create a view cycle (fails)
SELECT blackboxdb_api.create_collection_view('db', '{ "create": "create_view_tests", "viewOn": "create_view_tests_view_1" }');

-- recreate a collection
SELECT blackboxdb_api.insert_one('db', 'create_view_tests', '{ "_id": 3, "a": 140 }');

-- view works again
SELECT document FROM bson_aggregation_find('db', '{ "find": "create_view_tests_view_1" }');


-- do a coll_mod
SELECT database_name, collection_name, view_definition FROM blackboxdb_api_catalog.collections WHERE collection_name = 'create_view_tests_view_1';
SELECT blackboxdb_api.coll_mod('db', 'create_view_tests_view_1', '{ "collMod": "create_view_tests_view_1", "viewOn": "create_view_tests_view_4", "pipeline": [] }');
SELECT database_name, collection_name, view_definition FROM blackboxdb_api_catalog.collections WHERE collection_name = 'create_view_tests_view_1';


-- create a much longer cycle
SELECT blackboxdb_api.create_collection_view('db', '{ "create": "create_view_cycle_1", "viewOn": "create_view_cycle_2" }');
SELECT blackboxdb_api.create_collection_view('db', '{ "create": "create_view_cycle_2", "viewOn": "create_view_cycle_3" }');
SELECT blackboxdb_api.create_collection_view('db', '{ "create": "create_view_cycle_3", "viewOn": "create_view_cycle_4" }');
SELECT blackboxdb_api.create_collection_view('db', '{ "create": "create_view_cycle_4", "viewOn": "create_view_cycle_1" }');


-- create with long name
SELECT blackboxdb_api.create_collection_view('db', FORMAT('{ "create": "create_view_cycle_4_%s", "viewOn": "create_view_cycle_1" }', repeat('1bc', 80))::blackboxdb_core.bson);
