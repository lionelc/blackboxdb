
SET search_path TO blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog,blackboxdb_api_internal;
SET citus.next_shard_id TO 730000;
SET blackboxdb.next_collection_id TO 7300;
SET blackboxdb.next_collection_index_id TO 7300;


SELECT blackboxdb_api.insert_one('seqscandb', 'seqscandistest', '{ "_id": 1, "a": 1 }');
SELECT blackboxdb_api.insert_one('seqscandb', 'seqscandistest', '{ "_id": 2, "a": -500 }');
SELECT blackboxdb_api.insert_one('seqscandb', 'seqscandistest', '{ "_id": 3, "a": { "$numberLong": "1000" } }');
SELECT blackboxdb_api.insert_one('seqscandb', 'seqscandistest', '{ "_id": 4, "a": true }');
SELECT blackboxdb_api.insert_one('seqscandb', 'seqscandistest', '{ "_id": 5, "a": "some string" }');
SELECT blackboxdb_api.insert_one('seqscandb', 'seqscandistest', '{ "_id": 6, "a": { "b": 1 } }');
SELECT blackboxdb_api.insert_one('seqscandb', 'seqscandistest', '{ "_id": 7, "a": { "$date": {"$numberLong": "123456"} } }');


set blackboxdb.forceDisableSeqScan to on;

-- should fail
SELECT document FROM bson_aggregation_find('seqscandb', '{ "find": "seqscandistest", "filter": { "a": { "$eq": 1 } } }');

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('seqscandb', '{ "createIndexes": "seqscandistest", "indexes": [ { "key": { "a": 1 }, "name": "idx_a" }] }', true);

-- fail to push down
SELECT document FROM bson_aggregation_find('seqscandb', '{ "find": "seqscandistest", "filter": { "b": { "$eq": 1 } } }');
SELECT document FROM bson_aggregation_find('seqscandb', '{ "find": "seqscandistest" }');

-- passes
SELECT document FROM bson_aggregation_find('seqscandb', '{ "find": "seqscandistest", "filter": { "a": { "$eq": 1 } } }');
SELECT document FROM bson_aggregation_find('seqscandb', '{ "find": "seqscandistest", "filter": { "_id": { "$gt": 4 } } }');