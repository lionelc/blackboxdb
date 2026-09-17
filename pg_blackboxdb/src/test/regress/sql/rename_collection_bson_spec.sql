-- Tests for rename_collection BSON signature: rename_collection(bson)
-- This is the new signature used by the Gateway
SET search_path TO blackboxdb_api_catalog;
SET blackboxdb.next_collection_id TO 1400;
SET blackboxdb.next_collection_index_id TO 1400;

-- Setup: create collections for testing
SELECT blackboxdb_api.create_collection('rename_bson_db','source_coll');
SELECT blackboxdb_api.insert_one('rename_bson_db','source_coll','{"_id":"1", "a":1}');

-- Test 1: basic rename via BSON
SELECT blackboxdb_api.rename_collection('{"renameCollection": "rename_bson_db.source_coll", "to": "rename_bson_db.target_coll"}'::blackboxdb_core.bson);
-- verify old name gone, new name has data
SELECT count(*) FROM blackboxdb_api.collection('rename_bson_db','source_coll');
SELECT count(*) FROM blackboxdb_api.collection('rename_bson_db','target_coll');

-- Test 2: rename to existing name without dropTarget → ERROR
SELECT blackboxdb_api.create_collection('rename_bson_db','existing_coll');
SELECT blackboxdb_api.rename_collection('{"renameCollection": "rename_bson_db.target_coll", "to": "rename_bson_db.existing_coll"}'::blackboxdb_core.bson);

-- Test 3: rename with dropTarget=true → succeeds
SELECT blackboxdb_api.rename_collection('{"renameCollection": "rename_bson_db.target_coll", "to": "rename_bson_db.existing_coll", "dropTarget": true}'::blackboxdb_core.bson);
-- verify data moved
SELECT count(*) FROM blackboxdb_api.collection('rename_bson_db','target_coll');
SELECT count(*) FROM blackboxdb_api.collection('rename_bson_db','existing_coll');

-- Test 4: rename non-existent collection → ERROR
SELECT blackboxdb_api.rename_collection('{"renameCollection": "rename_bson_db.no_such_coll", "to": "rename_bson_db.something"}'::blackboxdb_core.bson);

-- Test 5: NULL BSON → ERROR
SELECT blackboxdb_api.rename_collection(NULL::blackboxdb_core.bson);

-- Test 6: missing "to" field → ERROR
SELECT blackboxdb_api.rename_collection('{"renameCollection": "rename_bson_db.existing_coll"}'::blackboxdb_core.bson);

-- Test 7: missing "renameCollection" field → ERROR
SELECT blackboxdb_api.rename_collection('{"to": "rename_bson_db.something"}'::blackboxdb_core.bson);

-- Test 8: extra fields (lsid, $db, writeConcern) are ignored
SELECT blackboxdb_api.create_collection('rename_bson_db','extra_fields_coll');
SELECT blackboxdb_api.rename_collection('{"renameCollection": "rename_bson_db.extra_fields_coll", "to": "rename_bson_db.extra_fields_renamed", "lsid": {"id": "abc"}, "$db": "admin", "writeConcern": {"w": 1}}'::blackboxdb_core.bson);
SELECT count(*) FROM blackboxdb_api.collection('rename_bson_db','extra_fields_renamed');

-- Test 9: invalid namespace format (no dot) → ERROR
SELECT blackboxdb_api.rename_collection('{"renameCollection": "noDotHere", "to": "alsoNoDot"}'::blackboxdb_core.bson);

-- Test 10: cross-database rename → ERROR
SELECT blackboxdb_api.rename_collection('{"renameCollection": "rename_bson_db.existing_coll", "to": "otherdb.existing_coll"}'::blackboxdb_core.bson);

-- Test 11: rename collection to itself → ERROR
SELECT blackboxdb_api.rename_collection('{"renameCollection": "rename_bson_db.existing_coll", "to": "rename_bson_db.existing_coll"}'::blackboxdb_core.bson);

-- Test 12: unknown field → ERROR
SELECT blackboxdb_api.rename_collection('{"renameCollection": "rename_bson_db.existing_coll", "to": "rename_bson_db.new_coll", "unknownField": true}'::blackboxdb_core.bson);

-- Cleanup
SELECT blackboxdb_api.drop_database('rename_bson_db');
