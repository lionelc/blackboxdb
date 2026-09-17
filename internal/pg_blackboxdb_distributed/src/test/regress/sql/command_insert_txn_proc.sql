SET search_path TO blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog,blackboxdb_api_internal;
SET citus.next_shard_id TO 139000;
SET blackboxdb.next_collection_id TO 1390;
SET blackboxdb.next_collection_index_id TO 1390;

-- Run inside transaction
BEGIN;
CALL blackboxdb_api.insert_txn_proc('db', '{"insert":"salaries", "documents":[{ "_id" : 1 }]}');
END;

-- exercise invalid insert syntax errors
CALL blackboxdb_api.insert_txn_proc('db', NULL);
CALL blackboxdb_api.insert_txn_proc(NULL, '{"insert":"collection", "documents":[{"a":1}]}');
CALL blackboxdb_api.insert_txn_proc('db', '{"documents":[{"a":1}]}');
CALL blackboxdb_api.insert_txn_proc('db', '{"insert":"collection"}');
CALL blackboxdb_api.insert_txn_proc('db', '{"insert":["collection"], "documents":[{"a":1}]}');
CALL blackboxdb_api.insert_txn_proc('db', '{"insert":"collection", "documents":{"a":1}}');
CALL blackboxdb_api.insert_txn_proc('db', '{"insert":"collection", "documents":[{"a":1}], "extra":1}');
CALL blackboxdb_api.insert_txn_proc('db', '{"insert":"collection", "documents":[4]}');
CALL blackboxdb_api.insert_txn_proc('db', '{"insert":"collection", "documents":[{"a":1}],"ordered":1}');

-- Disallow system.views, system.profile writes
CALL blackboxdb_api.insert_txn_proc('db', '{"insert":"system.views", "documents":[{"a":1}],"ordered":true}');
CALL blackboxdb_api.insert_txn_proc('db', '{"insert":"system.profile", "documents":[{"a":1}],"ordered":true}');

-- regular single-row insert
CALL blackboxdb_api.insert_txn_proc('db', '{"insert":"collection0", "documents":[{"_id":99,"a":99}]}');
select document from blackboxdb_api.collection('db','collection0') where document @@ '{}';

-- batch scenario
set blackboxdb.batchWriteSubTransactionCount TO 5;

-- when single batch has no issue
CALL blackboxdb_api.insert_txn_proc('batchSprocDB', '{"insert":"batchColl0", "documents":[{"_id":1}, {"_id":2}, {"_id":3},  {"_id":4},  {"_id":5}]}');
select document from blackboxdb_api.collection('batchSprocDB','batchColl0') where document @@ '{}';

-- when multiple batches have no issue
CALL blackboxdb_api.insert_txn_proc('batchSprocDB', '{"insert":"batchColl1", "documents":[{"_id":1}, {"_id":2}, {"_id":3},  {"_id":4},  {"_id":5}, {"_id":6}, {"_id":7}]}');
select document from blackboxdb_api.collection('batchSprocDB','batchColl1') where document @@ '{}';

-- when single batch has issue _id 2 is duplicated
CALL blackboxdb_api.insert_txn_proc('batchSprocDB', '{"insert":"batchColl2", "documents":[{"_id":1}, {"_id":2}, {"_id":2},  {"_id":4},  {"_id":5}]}');
select document from blackboxdb_api.collection('batchSprocDB','batchColl2') where document @@ '{}';

-- when multiple batches have no _id 2 is duplicated and _id 6 is duplicated
CALL blackboxdb_api.insert_txn_proc('batchSprocDB', '{"insert":"batchColl3", "documents":[{"_id":1}, {"_id":2}, {"_id":2},  {"_id":4},  {"_id":5}, {"_id":6}, {"_id":6}]}');
select document from blackboxdb_api.collection('batchSprocDB','batchColl3') where document @@ '{}';

-- when single batch has issue _id 2 is duplicated and ordered false
CALL blackboxdb_api.insert_txn_proc('batchSprocDB', '{"insert":"batchColl4", "documents":[{"_id":1}, {"_id":2}, {"_id":2},  {"_id":4},  {"_id":5}], "ordered":false}');
select document from blackboxdb_api.collection('batchSprocDB','batchColl4') where document @@ '{}';

-- when multiple batches have no _id 2 is duplicated and _id 6 is duplicated and ordered false
CALL blackboxdb_api.insert_txn_proc('batchSprocDB', '{"insert":"batchColl5", "documents":[{"_id":1}, {"_id":2}, {"_id":2},  {"_id":4},  {"_id":5}, {"_id":6}, {"_id":6}], "ordered":false}');
select document from blackboxdb_api.collection('batchSprocDB','batchColl5') where document @@ '{}';

-- end batch test rest GUC
set blackboxdb.batchWriteSubTransactionCount TO 512;

-- Insert collection a db with same name and different case and collection being same. Expect to error
CALL blackboxdb_api.insert_txn_proc('dB', '{"insert":"collection0", "documents":[{"_id":99,"a":99}]}');

-- Insert collection a db with same name and different case and collection being different. Expect to error
CALL blackboxdb_api.insert_txn_proc('dB', '{"insert":"collection9", "documents":[{"_id":99,"a":99}]}');

-- Insert collection same db and new collection.
CALL blackboxdb_api.insert_txn_proc('db', '{"insert":"collection8", "documents":[{"_id":99,"a":99}]}');


CALL blackboxdb_api.insert_txn_proc('db', '{"insert":"collection0", "documents":[{"_id":1,"a":1}]}',NULL,'insert-1');
CALL blackboxdb_api.insert_txn_proc('db', '{"insert":"collection0", "documents":[{"_id":1,"a":1}]}',NULL,'insert-1');
select document from blackboxdb_api.collection('db','collection0') where document @@ '{}';


CALL blackboxdb_api.insert_txn_proc('db', '{"insert":"collection1", "documents":[{"_id":1,"a":1},{"_id":2,"a":2}]}');
select document from blackboxdb_api.collection('db','collection1') where document @@ '{}' order by document-> '_id';


CALL blackboxdb_api.insert_txn_proc('db', '{"insert":"collection2", "documents":[{"_id":1,"$a":1},{"_id":2,"a":2}]}');
select document from blackboxdb_api.collection('db','collection2') where document @@ '{}' order by document-> '_id';


CALL blackboxdb_api.insert_txn_proc('db', '{"insert":"collection3", "documents":[{"_id":1,"$a":1},{"_id":2,"a":2}],"ordered":false}');
select document from blackboxdb_api.collection('db','collection3') where document @@ '{}' order by document-> '_id';


-- shard the collection by _id
select blackboxdb_api.shard_collection('db', 'collection4', '{"_id":"hashed"}', false);

CALL blackboxdb_api.insert_txn_proc('db', '{"insert":"collection4", "documents":[{"_id":1,"a":1}]}',NULL,'insert-2');
CALL blackboxdb_api.insert_txn_proc('db', '{"insert":"collection4", "documents":[{"_id":1,"a":1}]}',NULL,'insert-2');
select document from blackboxdb_api.collection('db','collection4') where document @@ '{}';


-- single-row insert with retry and auto-generated _id

CALL blackboxdb_api.insert_txn_proc('db', '{"insert":"collection5", "documents":[{"a":1}]}',NULL,'insert-2');
CALL blackboxdb_api.insert_txn_proc('db', '{"insert":"collection5", "documents":[{"a":1}]}',NULL,'insert-2');
select count(*) from blackboxdb_api.collection('db','collection5') where document @@ '{}';

-- multi-row insert collection different shards
CALL blackboxdb_api.insert_txn_proc('db', '{"insert":"collection6", "documents":[{"_id":1,"a":1},{"_id":2,"a":2}]}');
select document from blackboxdb_api.collection('db','collection6') where document @@ '{}' order by document-> '_id';
select document from blackboxdb_api.collection('db','collection6') where document @@ '{"a":1}' order by document-> '_id';
select document from blackboxdb_api.collection('db','collection6') where document @@ '{"a":2}' order by document-> '_id';

-- insert with documents in special section
CALL blackboxdb_api.insert_txn_proc('db', '{"insert":"collection7"}', '{ "": [{"_id":1,"a":1},{"_id":2,"a":2}] }');
select document from blackboxdb_api.collection('db','collection7') where document @@ '{}' order by document-> '_id';

-- insert with both docs specified.
CALL blackboxdb_api.insert_txn_proc('db', '{"insert":"collection9", "documents":[{"_id":1,"a":1},{"_id":2,"a":2}]}', '{ "": [{"_id":1,"a":1},{"_id":2,"a":2}] }');

-- insert with id undefined skips
CALL blackboxdb_api.insert_txn_proc('db', '{"insert":"collection9", "documents":[{"_id":{ "$undefined": true } }]}');
CALL blackboxdb_api.insert_txn_proc('db', '{"insert":"collection9"}', '{ "": [ {"_id":{ "$undefined": true } } ]}');


-- insert with invalid database
CALL blackboxdb_api.insert_txn_proc('Invalid Database Name', '{"insert":"notexists", "documents":[{"_id":1,"a":1}]}');
CALL blackboxdb_api.insert_txn_proc('db', '{"insert":"system.othercoll", "documents":[{"_id":1,"a":1}]}');
CALL blackboxdb_api.insert_txn_proc('db', '{"insert":"random$name", "documents":[{"_id":1,"a":1}]}');
CALL blackboxdb_api.insert_txn_proc('db', '{"insert":".randomname", "documents":[{"_id":1,"a":1}]}');
CALL blackboxdb_api.insert_txn_proc('verylongdatabasenameformeasuringthelimitsofdatabasenamesinmongodb', '{"insert":"coll", "documents":[{"_id":1,"a":1}]}');
CALL blackboxdb_api.insert_txn_proc('verylongdatabasenameformeasuringlimitsofdatabasenamesinmongoda1', '{"insert":"verylongcollectionnameformeasuringthelimitsofcollectionnamesinmongodb", "documents":[{"_id":1,"a":1}]}');

-- when multiple batches and after multiple intermidate commits also things are fine
SET blackboxdb.batchWriteSubTransactionCount TO 2;
SELECT  blackboxdb_api.create_collection('commitDb1', 'commitColl');

-- insert 10 documents
CALL blackboxdb_api.insert_txn_proc('commitDb1', '{"insert":"commitColl", "documents":[{"_id":1}, {"_id":2}, {"_id":3},  {"_id":4},  {"_id":5}, {"_id":6}, {"_id":7}, {"_id":8}, {"_id":9}, {"_id":10}]}');

-- first one is duplicate and rest 9 are inserted
CALL blackboxdb_api.insert_txn_proc('commitDb1', '{"insert":"commitColl", "documents":[{"_id":1}, {"_id":12}, {"_id":13},  {"_id":14},  {"_id":15}, {"_id":16}, {"_id":17}, {"_id":18}, {"_id":19}, {"_id":20}], "ordered":false}');

-- total doc count should be 10+9 
SELECT count(document) FROM blackboxdb_api.collection('commitDb1','commitColl');

-- single insert but with transaction id uses subtransactions
SET  client_min_messages TO 'DEBUG1';
CALL blackboxdb_api.insert_txn_proc('db', '{"insert":"collection0", "documents":[{"_id":40,"a":99}]}',NULL, '1');

-- Single insert without transaction id not uses subtransactions
CALL blackboxdb_api.insert_txn_proc('db', '{"insert":"collection0", "documents":[{"_id":123}]}');

-- test failed insert with non subtransactional path 
CALL blackboxdb_api.insert_txn_proc('db', '{"insert":"collection0", "documents":[{"_id":123}]}');

RESET client_min_messages;

---- clean the collections
SELECT blackboxdb_api.drop_collection('db', 'collection0');
SELECT blackboxdb_api.drop_collection('db', 'collection1');
SELECT blackboxdb_api.drop_collection('db', 'collection2');
SELECT blackboxdb_api.drop_collection('db', 'collection3');
SELECT blackboxdb_api.drop_collection('db', 'collection4');
SELECT blackboxdb_api.drop_collection('db', 'collection5');
SELECT blackboxdb_api.drop_collection('db', 'collection6');
SELECT blackboxdb_api.drop_collection('db', 'collection7');
SELECT blackboxdb_api.drop_collection('db', 'collection8');