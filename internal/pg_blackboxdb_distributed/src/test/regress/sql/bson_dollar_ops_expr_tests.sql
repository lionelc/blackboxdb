set search_path to blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog,pg_catalog;
SET citus.next_shard_id TO 7500000;
SET blackboxdb.next_collection_id TO 7500;
SET blackboxdb.next_collection_index_id TO 7500;

SELECT blackboxdb_api.insert_one('db', 'bsonexprtests', '{ "_id": 1, "a": [ 1, 2, 3 ] }');
SELECT blackboxdb_api.insert_one('db', 'bsonexprtests', '{ "_id": 2, "a": 5 }');
SELECT blackboxdb_api.insert_one('db', 'bsonexprtests', '{ "_id": 3, "a": "someValue" }');
SELECT blackboxdb_api.insert_one('db', 'bsonexprtests', '{ "_id": 4, "a": 2 }');

SELECT document FROM blackboxdb_api.collection('db', 'bsonexprtests') WHERE document @@ '{ "$expr": { "$in": [ "$a", [ 2, "someValue" ] ] } }';
SELECT document FROM blackboxdb_api.collection('db', 'bsonexprtests') WHERE document @@ '{ "$expr": { "$gte": [ "$a", 3 ] } }';
SELECT document FROM blackboxdb_api.collection('db', 'bsonexprtests') WHERE document @@ '{ "$expr": { "$isArray": "$a" } }';
SELECT document FROM blackboxdb_api.collection('db', 'bsonexprtests') WHERE document @@ '{ "$expr": "$a.0" }';

-- invalid scenarios
SELECT document FROM blackboxdb_api.collection('db', 'bsonexprtests') WHERE document @@ '{ "a": { "$elemMatch": { "$expr": { "$isArray": "$a" } } } }';
SELECT blackboxdb_api_internal.update_bson_document('{"_id": 1, "a": [1,2,3,4,5]}', '{ "": { "$pull": { "a": {"$expr": "$a" } } } }', '{}', NULL::blackboxdb_core.bson, NULL::blackboxdb_core.bson,NULL::TEXT);
SELECT document FROM blackboxdb_api.collection('db', 'bsonexprtests') WHERE document @@ '{ "$expr": "$$a" }';