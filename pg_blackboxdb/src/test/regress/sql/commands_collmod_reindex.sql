SET search_path TO blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog;
SET blackboxdb.next_collection_id TO 25703000;
SET blackboxdb.next_collection_index_id TO 25703000;

-- Delete all old create index requests from other tests
DELETE from blackboxdb_api_catalog.blackboxdb_index_queue;

SET blackboxdb.enableUniqueReindex TO true;

------------------------------------------------------------
-- Setup: Create a collection with data and a unique index
------------------------------------------------------------
SELECT blackboxdb_api.create_collection('reindex_db', 'reindex_unique_coll');
SELECT COUNT(blackboxdb_api.insert_one('reindex_db', 'reindex_unique_coll', FORMAT('{"_id": %s, "a": %s, "b": %s}', i, i, i)::blackboxdb_core.bson)) FROM generate_series(1, 20) i;

-- Create a unique index
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('reindex_db',
  '{ "createIndexes": "reindex_unique_coll", "indexes": [ { "key": { "a": 1 }, "name": "a_1_unique", "unique": true } ] }', true);

-- Create a non-unique index for comparison
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('reindex_db',
  '{ "createIndexes": "reindex_unique_coll", "indexes": [ { "key": { "b": 1 }, "name": "b_1" } ] }', true);

-- Verify indexes before reindex
SELECT blackboxdb_api_catalog.bson_dollar_unwind(cursorpage, '$cursor.firstBatch') FROM blackboxdb_api.list_indexes_cursor_first_page('reindex_db', '{ "listIndexes": "reindex_unique_coll" }');

------------------------------------------------------------
-- Error case: reindex must be true
------------------------------------------------------------
SELECT blackboxdb_api.coll_mod('reindex_db', 'reindex_unique_coll', '{ "collMod": "reindex_unique_coll", "index": { "name": "a_1_unique", "reindex": false } }');

------------------------------------------------------------
-- Error case: index not found
------------------------------------------------------------
SELECT blackboxdb_api.coll_mod('reindex_db', 'reindex_unique_coll', '{ "collMod": "reindex_unique_coll", "index": { "name": "nonexistent_idx", "reindex": true } }');

------------------------------------------------------------
-- Error case: reindex of unique index when feature is disabled
------------------------------------------------------------
SET blackboxdb.enableUniqueReindex TO false;
SELECT blackboxdb_api.coll_mod('reindex_db', 'reindex_unique_coll', '{ "collMod": "reindex_unique_coll", "index": { "name": "a_1_unique", "reindex": true } }');
SET blackboxdb.enableUniqueReindex TO true;

------------------------------------------------------------
-- Error case: reindex combined with other options
------------------------------------------------------------
SELECT blackboxdb_api.coll_mod('reindex_db', 'reindex_unique_coll', '{ "collMod": "reindex_unique_coll", "index": { "name": "a_1_unique", "reindex": true, "hidden": true } }');

------------------------------------------------------------
-- Error case: updateOptions requires reindex
------------------------------------------------------------
SELECT blackboxdb_api.coll_mod('reindex_db', 'reindex_unique_coll', '{ "collMod": "reindex_unique_coll", "index": { "name": "a_1_unique", "updateOptions": true } }');

-- Capture collection_id for \d checks
SELECT collection_id as unique_coll_id FROM blackboxdb_api_catalog.collections WHERE database_name = 'reindex_db' AND collection_name = 'reindex_unique_coll' \gset

-- Show table state before any reindex
\d blackboxdb_data.documents_:unique_coll_id

-- Show constraints before any reindex (only stable fields, no OIDs)
SELECT conname, contype, convalidated
FROM pg_constraint
WHERE conrelid = ('blackboxdb_data.documents_' || :unique_coll_id)::regclass
  AND contype IN ('p', 'x')
ORDER BY conname;

------------------------------------------------------------
-- Reindex a unique index via collMod
------------------------------------------------------------
SELECT blackboxdb_api.coll_mod('reindex_db', 'reindex_unique_coll', '{ "collMod": "reindex_unique_coll", "index": { "name": "a_1_unique", "reindex": true } }');

-- Verify the reindex request is in the queue
SELECT cmd_type, index_cmd FROM blackboxdb_api_catalog.blackboxdb_index_queue WHERE index_id >= 25703000 AND index_id <= 25703100 ORDER BY index_id;

-- Process the reindex queue
CALL blackboxdb_api_internal.build_index_concurrently(1);
CALL blackboxdb_api_internal.build_index_background(1);

-- Verify the queue is empty after processing
SELECT cmd_type, index_cmd FROM blackboxdb_api_catalog.blackboxdb_index_queue WHERE index_id >= 25703000 AND index_id <= 25703100 ORDER BY index_id;

-- Verify no _ccold/_ccnew artifacts remain and constraint is intact
\d blackboxdb_data.documents_:unique_coll_id

-- Verify only expected constraints exist (no _ccold/_ccnew constraint artifacts)
SELECT conname, contype, convalidated
FROM pg_constraint
WHERE conrelid = ('blackboxdb_data.documents_' || :unique_coll_id)::regclass
  AND contype IN ('p', 'x')
ORDER BY conname;

-- Verify the unique index still exists and is valid
SELECT blackboxdb_api_catalog.bson_dollar_unwind(cursorpage, '$cursor.firstBatch') FROM blackboxdb_api.list_indexes_cursor_first_page('reindex_db', '{ "listIndexes": "reindex_unique_coll" }');

-- Verify uniqueness constraint still works after reindex (duplicate should fail)
SELECT blackboxdb_api.insert_one('reindex_db', 'reindex_unique_coll', '{"_id": 100, "a": 1}');

-- Verify the reindexed unique index is used for queries
SET enable_seqscan TO off;
EXPLAIN (COSTS OFF) SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('reindex_db', '{ "find": "reindex_unique_coll", "filter": { "a": 5 } }');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('reindex_db', '{ "find": "reindex_unique_coll", "filter": { "a": 5 } }');
RESET enable_seqscan;

------------------------------------------------------------
-- Reindex a non-unique index via collMod (for comparison)
------------------------------------------------------------
SELECT blackboxdb_api.coll_mod('reindex_db', 'reindex_unique_coll', '{ "collMod": "reindex_unique_coll", "index": { "name": "b_1", "reindex": true } }');
SELECT cmd_type, index_cmd FROM blackboxdb_api_catalog.blackboxdb_index_queue WHERE index_id >= 25703000 AND index_id <= 25703100 ORDER BY index_id;
CALL blackboxdb_api_internal.build_index_concurrently(1);
CALL blackboxdb_api_internal.build_index_background(1);
SELECT cmd_type, index_cmd FROM blackboxdb_api_catalog.blackboxdb_index_queue WHERE index_id >= 25703000 AND index_id <= 25703100 ORDER BY index_id;

------------------------------------------------------------
-- Reindex _id_ unique index via keyPattern
------------------------------------------------------------
SELECT blackboxdb_api.coll_mod('reindex_db', 'reindex_unique_coll', '{ "collMod": "reindex_unique_coll", "index": { "keyPattern": { "_id": 1 }, "reindex": true } }');
SELECT cmd_type, index_cmd FROM blackboxdb_api_catalog.blackboxdb_index_queue WHERE index_id >= 25703000 AND index_id <= 25703100 ORDER BY index_id;
CALL blackboxdb_api_internal.build_index_concurrently(1);
CALL blackboxdb_api_internal.build_index_background(1);
SELECT cmd_type, index_cmd FROM blackboxdb_api_catalog.blackboxdb_index_queue WHERE index_id >= 25703000 AND index_id <= 25703100 ORDER BY index_id;

-- Verify no _ccold/_ccnew artifacts remain after _id reindex and primary key is intact
\d blackboxdb_data.documents_:unique_coll_id

-- Verify only expected constraints exist after _id reindex (no _ccold/_ccnew artifacts)
SELECT conname, contype, convalidated
FROM pg_constraint
WHERE conrelid = ('blackboxdb_data.documents_' || :unique_coll_id)::regclass
  AND contype IN ('p', 'x')
ORDER BY conname;

-- Verify _id index still works after reindex
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('reindex_db', '{ "find": "reindex_unique_coll", "filter": { "_id": 10 } }');

------------------------------------------------------------
-- Error case: reindex with updateOptions is not supported for the _id_ index
-- (its opclass options are fixed and must not be regenerated). Both the
-- name-based and keyPattern-based forms must be rejected, and nothing should be
-- queued.
------------------------------------------------------------
SELECT blackboxdb_api.coll_mod('reindex_db', 'reindex_unique_coll', '{ "collMod": "reindex_unique_coll", "index": { "name": "_id_", "reindex": true, "updateOptions": true } }');
SELECT blackboxdb_api.coll_mod('reindex_db', 'reindex_unique_coll', '{ "collMod": "reindex_unique_coll", "index": { "keyPattern": { "_id": 1 }, "reindex": true, "updateOptions": true } }');
-- The queue must be empty: the rejected requests were never enqueued.
SELECT cmd_type, index_cmd FROM blackboxdb_api_catalog.blackboxdb_index_queue WHERE index_id >= 25703000 AND index_id <= 25703100 ORDER BY index_id;

------------------------------------------------------------
-- Reindex unique index via collMod using keyPattern
------------------------------------------------------------
SELECT blackboxdb_api.coll_mod('reindex_db', 'reindex_unique_coll', '{ "collMod": "reindex_unique_coll", "index": { "keyPattern": { "a": 1 }, "reindex": true } }');
SELECT cmd_type, index_cmd FROM blackboxdb_api_catalog.blackboxdb_index_queue WHERE index_id >= 25703000 AND index_id <= 25703100 ORDER BY index_id;
CALL blackboxdb_api_internal.build_index_concurrently(1);
CALL blackboxdb_api_internal.build_index_background(1);
SELECT cmd_type, index_cmd FROM blackboxdb_api_catalog.blackboxdb_index_queue WHERE index_id >= 25703000 AND index_id <= 25703100 ORDER BY index_id;

-- Verify data still accessible and unique constraint intact
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('reindex_db', '{ "find": "reindex_unique_coll", "filter": { "a": 5 } }');
SELECT blackboxdb_api.insert_one('reindex_db', 'reindex_unique_coll', '{"_id": 101, "a": 2}');

------------------------------------------------------------
-- Test with compound unique index
------------------------------------------------------------
SELECT blackboxdb_api.create_collection('reindex_db', 'reindex_compound_unique');
SELECT COUNT(blackboxdb_api.insert_one('reindex_db', 'reindex_compound_unique', FORMAT('{"_id": %s, "x": %s, "y": %s}', i, i, i)::blackboxdb_core.bson)) FROM generate_series(1, 10) i;

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('reindex_db',
  '{ "createIndexes": "reindex_compound_unique", "indexes": [ { "key": { "x": 1, "y": 1 }, "name": "xy_unique", "unique": true } ] }', true);

-- Reindex the compound unique index
SELECT blackboxdb_api.coll_mod('reindex_db', 'reindex_compound_unique', '{ "collMod": "reindex_compound_unique", "index": { "name": "xy_unique", "reindex": true } }');
SELECT cmd_type, index_cmd FROM blackboxdb_api_catalog.blackboxdb_index_queue WHERE index_id >= 25703000 AND index_id <= 25703100 ORDER BY index_id;
CALL blackboxdb_api_internal.build_index_concurrently(1);
CALL blackboxdb_api_internal.build_index_background(1);
SELECT cmd_type, index_cmd FROM blackboxdb_api_catalog.blackboxdb_index_queue WHERE index_id >= 25703000 AND index_id <= 25703100 ORDER BY index_id;

-- Verify uniqueness still works on compound index
SELECT blackboxdb_api.insert_one('reindex_db', 'reindex_compound_unique', '{"_id": 100, "x": 1, "y": 1}');

-- Verify the index is used
SET enable_seqscan TO off;
EXPLAIN (COSTS OFF) SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('reindex_db', '{ "find": "reindex_compound_unique", "filter": { "x": 5, "y": 5 } }');
RESET enable_seqscan;

------------------------------------------------------------
-- Test with shard_collection (sharded unique index reindex)
------------------------------------------------------------
SELECT blackboxdb_api.create_collection('reindex_db', 'reindex_unique_sharded');
SELECT COUNT(blackboxdb_api.insert_one('reindex_db', 'reindex_unique_sharded', FORMAT('{"_id": %s, "a": %s, "b": %s}', i, i, i)::blackboxdb_core.bson)) FROM generate_series(1, 20) i;

-- Create a unique index before sharding
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('reindex_db',
  '{ "createIndexes": "reindex_unique_sharded", "indexes": [ { "key": { "a": 1 }, "name": "a_1_unique", "unique": true } ] }', true);

-- Shard the collection
SELECT blackboxdb_api.shard_collection('reindex_db', 'reindex_unique_sharded', '{ "a": "hashed" }', false);

-- Reindex the unique index on the sharded collection via collMod
SELECT blackboxdb_api.coll_mod('reindex_db', 'reindex_unique_sharded', '{ "collMod": "reindex_unique_sharded", "index": { "name": "a_1_unique", "reindex": true } }');
SELECT cmd_type, index_cmd FROM blackboxdb_api_catalog.blackboxdb_index_queue WHERE index_id >= 25703000 AND index_id <= 25703100 ORDER BY index_id;
CALL blackboxdb_api_internal.build_index_concurrently(1);
CALL blackboxdb_api_internal.build_index_background(1);
SELECT cmd_type, index_cmd FROM blackboxdb_api_catalog.blackboxdb_index_queue WHERE index_id >= 25703000 AND index_id <= 25703100 ORDER BY index_id;

-- Verify uniqueness still works after sharded reindex
SELECT blackboxdb_api.insert_one('reindex_db', 'reindex_unique_sharded', '{"_id": 100, "a": 1}');

-- Verify data is accessible
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('reindex_db', '{ "find": "reindex_unique_sharded", "filter": { "a": 10 } }');

-- Reindex the _id_ index on the sharded collection
SELECT blackboxdb_api.coll_mod('reindex_db', 'reindex_unique_sharded', '{ "collMod": "reindex_unique_sharded", "index": { "keyPattern": { "_id": 1 }, "reindex": true } }');
SELECT cmd_type, index_cmd FROM blackboxdb_api_catalog.blackboxdb_index_queue WHERE index_id >= 25703000 AND index_id <= 25703100 ORDER BY index_id;
CALL blackboxdb_api_internal.build_index_concurrently(1);
CALL blackboxdb_api_internal.build_index_background(1);
SELECT cmd_type, index_cmd FROM blackboxdb_api_catalog.blackboxdb_index_queue WHERE index_id >= 25703000 AND index_id <= 25703100 ORDER BY index_id;

-- Verify indexes after all reindex operations
SELECT blackboxdb_api_catalog.bson_dollar_unwind(cursorpage, '$cursor.firstBatch') FROM blackboxdb_api.list_indexes_cursor_first_page('reindex_db', '{ "listIndexes": "reindex_unique_sharded" }');

------------------------------------------------------------
-- Test: skipIndexCleanupOnReindex leaves old index behind
------------------------------------------------------------
SELECT blackboxdb_api.create_collection('reindex_db', 'reindex_skip_cleanup');
SELECT COUNT(blackboxdb_api.insert_one('reindex_db', 'reindex_skip_cleanup', FORMAT('{"_id": %s, "a": %s}', i, i)::blackboxdb_core.bson)) FROM generate_series(1, 10) i;

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('reindex_db',
  '{ "createIndexes": "reindex_skip_cleanup", "indexes": [ { "key": { "a": 1 }, "name": "a_1_unique", "unique": true } ] }', true);

-- Show table state before reindex
SELECT collection_id as skip_cleanup_collection_id FROM blackboxdb_api_catalog.collections WHERE database_name = 'reindex_db' AND collection_name = 'reindex_skip_cleanup' \gset
\d blackboxdb_data.documents_:skip_cleanup_collection_id

-- Set the GUC to skip cleanup of old index after reindex
SET blackboxdb.skipIndexCleanupOnReindex TO true;

-- Reindex the unique index
SELECT blackboxdb_api.coll_mod('reindex_db', 'reindex_skip_cleanup', '{ "collMod": "reindex_skip_cleanup", "index": { "name": "a_1_unique", "reindex": true } }');
CALL blackboxdb_api_internal.build_index_concurrently(1);
CALL blackboxdb_api_internal.build_index_background(1);
SELECT cmd_type, index_cmd FROM blackboxdb_api_catalog.blackboxdb_index_queue WHERE index_id >= 25703000 AND index_id <= 25703100 ORDER BY index_id;

-- The old index (_ccold) should still be present on the table
\d blackboxdb_data.documents_:skip_cleanup_collection_id

RESET blackboxdb.skipIndexCleanupOnReindex;
