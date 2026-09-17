SET search_path TO blackboxdb_api,blackboxdb_core;
SET blackboxdb.next_collection_id TO 100;
SET blackboxdb.next_collection_index_id TO 100;

-- test up the unique shard document generation 
SELECT blackboxdb_api_internal.generate_unique_shard_document('{ "key1": "a", "key2": "1" }', 1, '{ "key1" : 1, "key2" : 1 }'::bson, true);
SELECT blackboxdb_api_internal.generate_unique_shard_document('{ "key1": "a", "key2": "2" }', 2, '{ "key1" : 1, "key2" : 1 }'::bson, true);


SELECT blackboxdb_api_internal.generate_unique_shard_document('{ "key1": "a" }', 2, '{ "key1" : 1, "key2" : 1 }'::bson, true);
SELECT blackboxdb_api_internal.generate_unique_shard_document('{ "key2": "2" }', 2, '{ "key1" : 1, "key2" : 1 }'::bson, true);

SELECT blackboxdb_api_internal.generate_unique_shard_document('{ "key1": "a" }', 2, '{ "key1" : 1, "key2" : 1 }'::bson, false);
SELECT blackboxdb_api_internal.generate_unique_shard_document('{ "key2": "2" }', 2, '{ "key1" : 1, "key2" : 1 }'::bson, false);


SELECT blackboxdb_api_internal.generate_unique_shard_document('{ "key1": "a", "key2": [ "1", "2", "3" ] }', 2, '{ "key1" : 1, "key2" : 1 }'::bson, true);
SELECT blackboxdb_api_internal.generate_unique_shard_document('{ "key1": [ "a", "b", "c" ], "key2": "1" }', 2, '{ "key1" : 1, "key2" : 1 }'::bson, true);

SELECT blackboxdb_api_internal.generate_unique_shard_document('{ "key1": [ "a", "b", "c" ], "key2": [ "1", "2", "3" ] }', 2, '{ "key1" : 1, "key2" : 1 }'::bson, true);

-- test the equality operator for the unique equal
SELECT blackboxdb_api_internal.generate_unique_shard_document('{ "key1": "a", "key2": "1" }', 2, '{ "key1" : 1, "key2" : 1 }'::bson, true)
       OPERATOR(blackboxdb_api_internal.=#=) 
       blackboxdb_api_internal.generate_unique_shard_document('{ "key1": "a", "key2": "1" }', 2, '{ "key1" : 1, "key2" : 1 }'::bson, true);

-- with a different shard key becomes not equal
SELECT blackboxdb_api_internal.generate_unique_shard_document('{ "key1": "a", "key2": "1" }', 2, '{ "key1" : 1, "key2" : 1 }'::bson, true)
       OPERATOR(blackboxdb_api_internal.=#=) 
       blackboxdb_api_internal.generate_unique_shard_document('{ "key1": "a", "key2": "1" }', 3, '{ "key1" : 1, "key2" : 1 }'::bson, true);

-- Array paths handle uniqueness
SELECT blackboxdb_api_internal.generate_unique_shard_document('{ "key1": "a", "key2": "1" }', 2, '{ "key1" : 1, "key2" : 1 }'::bson, true)
       OPERATOR(blackboxdb_api_internal.=#=) 
       blackboxdb_api_internal.generate_unique_shard_document('{ "key1": "a", "key2": [ "1", "2" ] }', 2, '{ "key1" : 1, "key2" : 1 }'::bson, true);

SELECT blackboxdb_api_internal.generate_unique_shard_document('{ "key1": "a", "key2": "1" }', 2, '{ "key1" : 1, "key2" : 1 }'::bson, true)
       OPERATOR(blackboxdb_api_internal.=#=) 
       blackboxdb_api_internal.generate_unique_shard_document('{ "key1": [ "a", "b" ], "key2": "1" }', 2, '{ "key1" : 1, "key2" : 1 }'::bson, true);

SELECT blackboxdb_api_internal.generate_unique_shard_document('{ "key1": [ [ "a", "b" ] ], "key2": "1" }', 2, '{ "key1" : 1, "key2" : 1 }'::bson, true)
       OPERATOR(blackboxdb_api_internal.=#=) 
       blackboxdb_api_internal.generate_unique_shard_document('{ "key1": [ "a", "b" ], "key2": "1" }', 2, '{ "key1" : 1, "key2" : 1 }'::bson, true);

-- one key msimatch makes it not mismatched.
SELECT blackboxdb_api_internal.generate_unique_shard_document('{ "key1": "a", "key2": "1" }', 2, '{ "key1" : 1, "key2" : 1 }'::bson, true)
       OPERATOR(blackboxdb_api_internal.=#=) 
       blackboxdb_api_internal.generate_unique_shard_document('{ "key1": [ "a", "b" ], "key2": "2" }', 2, '{ "key1" : 1, "key2" : 1 }'::bson, true);