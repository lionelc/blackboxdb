SET citus.next_shard_id TO 11000;
SET blackboxdb.next_collection_id TO 110;
SET blackboxdb.next_collection_index_id TO 110;

SET search_path TO blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog,blackboxdb_api_internal,public;

SELECT blackboxdb_api.create_collection('testdb', 'test_collection_node_1');

SELECT blackboxdb_api.insert_one('testdb', 'test_collection_node_1', '{"_id": 1, "test": "value1"}');
SELECT blackboxdb_api.insert_one('testdb', 'test_collection_node_1', '{"_id": 2, "test": "value2"}');
SELECT blackboxdb_api.insert_one('testdb', 'test_collection_node_1', '{"_id": 3, "test": "value3"}');
SELECT blackboxdb_api.insert_one('testdb', 'test_collection_node_1', '{"_id": 4, "test": "value4"}');
SELECT blackboxdb_api.insert_one('testdb', 'test_collection_node_1', '{"_id": 5, "test": "value5"}');

-- Try to place it on a node that doesn't exist
SELECT blackboxdb_distributed_test_helpers.place_collection_on_node('testdb', 'test_collection_node_1', 10);

-- Place it on node 1
SELECT blackboxdb_distributed_test_helpers.place_collection_on_node('testdb', 'test_collection_node_1', 1);

SELECT object_id, document FROM blackboxdb_api.collection('testdb', 'test_collection_node_1') WHERE document @@ '{ "_id": { "$lte" : 5 }}' ORDER BY object_id;

EXPLAIN (VERBOSE ON, COSTS OFF, TIMING OFF) SELECT object_id, document FROM blackboxdb_api.collection('testdb', 'test_collection_node_1') WHERE document @@ '{ "_id": { "$lte" : 5 }}' ORDER BY object_id;
