SET search_path TO blackboxdb_api,blackboxdb_core,blackboxdb_api_catalog;
SET blackboxdb.next_collection_id TO 2100;
SET blackboxdb.next_collection_index_id TO 2100;

SELECT blackboxdb_api.create_collection_view('db', '{ "create": "test" }');
SELECT blackboxdb_api.insert_one('db', 'test', '{ "_id": 1, "a": 1, "ttl": 0 }');

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "test", "indexes": [ { "key": { "ttl": 1 }, "name": "ttlIndex", "expireAfterSeconds": 300 } ] }', TRUE);

-- set the default transaction mode.
set default_transaction_read_only = on;

-- should fail gracefully.
SELECT blackboxdb_api.create_collection_view('db', '{ "create": "collection" }');
SELECT blackboxdb_api.insert('db', '{ "insert": "test", "documents": [ { "a": 1 }] }');
SELECT blackboxdb_api.update('db', '{ "update": "test", "updates": [ { "q": { "a": 1 }, "u": { "$set": { "b": 1 }} }] }');
SELECT blackboxdb_api.delete('db', '{ "delete": "test", "deletes": [ { "q": { "a": 1 } }] }');

SELECT document FROM  blackboxdb_api_catalog.bson_aggregation_pipeline('db', '{ "aggregate": "test", "pipeline": [ { "$merge": { "into": "test" } } ] }');
SELECT blackboxdb_api.drop_collection('db', 'collection');

-- same command works when transaction explicitly read-write.
BEGIN;
SET TRANSACTION READ WRITE;
SELECT blackboxdb_api.create_collection_view('db', '{ "create": "collection" }');
SELECT blackboxdb_api.insert('db', '{ "insert": "collection", "documents": [ { "a": 1 }] }');
SELECT blackboxdb_api.update('db', '{ "update": "collection", "updates": [ { "q": { "a": 1 }, "u": { "$set": { "b": 1 }} }] }');
SELECT blackboxdb_api.delete('db', '{ "delete": "collection", "deletes": [ { "q": { "a": 1 }, "limit": 1 }] }');
SELECT blackboxdb_api.drop_collection('db', 'collection');
ROLLBACK;

-- fails gracefully when transaction is read-only.
CALL blackboxdb_api_internal.delete_expired_rows();

set blackboxdb.enableTTLJobsOnReadOnly to on;
CALL blackboxdb_api_internal.delete_expired_rows();