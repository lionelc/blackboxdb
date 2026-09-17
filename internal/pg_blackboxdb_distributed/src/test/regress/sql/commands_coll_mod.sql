SET citus.next_shard_id TO 2500000;
SET blackboxdb.next_collection_id TO 25000;
SET blackboxdb.next_collection_index_id TO 25000;
SET search_path TO blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog,blackboxdb_api_internal;

-- Create a collection
SELECT blackboxdb_api.create_collection('commands','collModTest');
SELECT blackboxdb_api.insert_one('commands','collModTest','{"_id":"1", "a": 1 }');

-- Creating a regular and ttl index
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('commands', blackboxdb_distributed_test_helpers.generate_create_index_arg('collModTest', 'a_1', '{"a": 1}'), true);
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('commands', '{"createIndexes": "collModTest", "indexes": [{"key": {"b": 1}, "name": "b_ttl", "v" : 2, "expireAfterSeconds": 10000}]}', true);
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('commands', '{"createIndexes": "collModTest", "indexes": [{"key": {"z": 1}, "name": "z_ttl_should_be_dropped_parallely", "v" : 2, "expireAfterSeconds": 1000}]}', true);

-- Top level validations for collMod index options
SELECT blackboxdb_api.coll_mod(NULL, 'collModTest', '{"collMod": "collModTest", "index": {}}');
SELECT blackboxdb_api.coll_mod('commands', NULL, '{"collMod": "collModTest", "index": {}}');
SELECT blackboxdb_api.coll_mod('commands', 'collModTest', '{"collMod": "collModTest", "hello": 1}'); -- Unknown field
SELECT blackboxdb_api.coll_mod('commands', 'collModTest', '{"collMod": "collModTest", "index": 1}'); -- Type mismatch
SELECT blackboxdb_api.coll_mod('commands', 'collModTest', '{"collMod": "collModTest", "index": {}}');
SELECT blackboxdb_api.coll_mod('commands', 'collModTest', '{"collMod": "collModTest", "index": []}');
SELECT blackboxdb_api.coll_mod('commands', 'collModTest', '{"collMod": "collModTest", "index": {"name": "c_1"}}');
SELECT blackboxdb_api.coll_mod('commands', 'collModTest', '{"collMod": "collModTest", "index": {"name": 1}}');
SELECT blackboxdb_api.coll_mod('commands', 'collModTest', '{"collMod": "collModTest", "index": {"keyPattern": 1}}');
SELECT blackboxdb_api.coll_mod('commands', 'collModTest', '{"collMod": "collModTest", "index": {"keyPattern": {"c": 1}, "name": 1}}');
SELECT blackboxdb_api.coll_mod('commands', 'collModTest', '{"collMod": "collModTest", "index": {"keyPattern": 1, "name": "c_1"}}');
SELECT blackboxdb_api.coll_mod('commands', 'collModTest', '{"collMod": "collModTest", "index": {"keyPattern": {"c": 1}, "name": "c_1"}}');
SELECT blackboxdb_api.coll_mod('commands', 'collModTest', '{"collMod": "collModTest", "index": {"keyPattern": {"c": 1}}}');
SELECT blackboxdb_api.coll_mod('commands', 'collModTest', '{"collMod": "collModTest", "index": {"name": 1, "expireAfterSeconds": true}}');
SELECT blackboxdb_api.coll_mod('commands', 'collModTest', '{"collMod": "collModTest", "index": {"name": 1, "expireAfterSeconds": {}}}');
SELECT blackboxdb_api.coll_mod('commands', 'collModTest', '{"collMod": "collModTest", "index": {"name": 1, "expireAfterSeconds": "expire"}}');

-- Inserting some documents
SELECT blackboxdb_api.insert_one('commands','collModTest', '{ "_id" : 0, "b": { "$date": { "$numberLong": "-1000" } } }', NULL);
SELECT blackboxdb_api.insert_one('commands','collModTest', '{ "_id" : 1, "b": { "$date": { "$numberLong": "0" } } }', NULL);
SELECT blackboxdb_api.insert_one('commands','collModTest', '{ "_id" : 2, "b": { "$date": { "$numberLong": "100" } } }', NULL);
SELECT blackboxdb_api.insert_one('commands','collModTest', '{ "_id" : 3, "b": { "$date": { "$numberLong": "1657900030774" } } }', NULL);
SELECT blackboxdb_api.insert_one('commands','collModTest', '{ "_id" : 4, "b": { "$date": { "$numberLong": "2657899731608" } } }', NULL);
SELECT blackboxdb_api.insert_one('commands','collModTest', '{ "_id" : 5, "b": [{ "$date": { "$numberLong": "100" }}] }', NULL);
SELECT blackboxdb_api.insert_one('commands','collModTest', '{ "_id" : 6, "b": [{ "$date": { "$numberLong": "100" }}, { "$date": { "$numberLong": "2657899731608" }}] }', NULL);
SELECT blackboxdb_api.insert_one('commands','collModTest', '{ "_id" : 7, "b": [true, { "$date": { "$numberLong": "100" }}, { "$date": { "$numberLong": "2657899731608" }}] }', NULL);
SELECT blackboxdb_api.insert_one('commands','collModTest', '{ "_id" : 8, "b": true }', NULL);
SELECT blackboxdb_api.insert_one('commands','collModTest', '{ "_id" : 9, "b": "would not expire" }', NULL);
-- Insert a doc with current time when the test is running

-- Function to insert a doc in collection with current time and given id
CREATE OR REPLACE FUNCTION insert_doc_with_current_time(id numeric)
RETURNS void
AS $fn$
DECLARE
    epoch_bgn       text;
    bgn_epoch_sec   numeric;
    bgn_usec        numeric;
    bgn_epoch_msec  numeric;
BEGIN
    SELECT extract(epoch from clock_timestamp()) into epoch_bgn;
    SELECT split_part(epoch_bgn, '.', 1)::numeric into bgn_epoch_sec;
    SELECT split_part(epoch_bgn, '.', 2)::numeric into bgn_usec;
    bgn_epoch_msec := bgn_epoch_sec * 1000 + ROUND(bgn_usec / 1000);
    EXECUTE format($$
        SELECT blackboxdb_api.insert_one('commands','collModTest', '{ "_id": %s, "b": { "$date": { "$numberLong": "%s" } } }', NULL)$$,
    id, bgn_epoch_msec);
    
END    
$fn$
LANGUAGE plpgsql;
SELECT insert_doc_with_current_time(100);

-- Test TTL deletion with current setting it should not delete the current timestamp doc with _id: 100
CALL blackboxdb_api_internal.delete_expired_rows();
SELECT object_id from blackboxdb_api.collection('commands', 'collModTest');

-- Updating ttl expiration time to 2 secs
SELECT * FROM blackboxdb_api_catalog.collection_indexes
    WHERE (index_spec).index_name = 'b_ttl' AND
    (index_spec).index_expire_after_seconds = 2; -- Before update
SELECT blackboxdb_api.coll_mod('commands', 'collModTest',
                             '{"collMod": "collModTest", "index": {"name": "b_ttl", "expireAfterSeconds": 2}}');
SELECT * FROM blackboxdb_api_catalog.collection_indexes
    WHERE (index_spec).index_name = 'b_ttl' AND
    (index_spec).index_expire_after_seconds = 2; -- After update

SELECT pg_sleep(2);

-- Now even _id: 100 should get deleted
CALL blackboxdb_api_internal.delete_expired_rows();
SELECT object_id from blackboxdb_api.collection('commands', 'collModTest');

-- Errors
SELECT blackboxdb_api.coll_mod('commands', 'collModTest', '{"collMod": "collModTest", "index": {"name": "a_1", "expireAfterSeconds": 2000}}'); -- Not a TTL index to be modified
SELECT blackboxdb_api.coll_mod('commands', 'collModTest', '{"collMod": "collModTest", "index": {"name": "a_1", "hidden": true}}'); -- Hidden is not supported yet
SELECT blackboxdb_api.coll_mod('commands', 'collModTest',
                             '{"collMod": "collModTest", "index": {"name": "c_1", "expireAfterSeconds": 1000}}'); -- index not found
SELECT blackboxdb_api.coll_mod('commands', 'collModTest',
                             '{"collMod": "collModTest", "index": {"keyPattern": {"c": 1}, "expireAfterSeconds": 1000}}'); -- index not found
