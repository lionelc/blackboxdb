SET search_path TO blackboxdb_core, blackboxdb_api, blackboxdb_api_internal, public;
SET blackboxdb.next_collection_id TO 25708000;
SET blackboxdb.next_collection_index_id TO 25708000;

-- ===================================================================
-- 1. createCollection on config database - restricted collections
-- ===================================================================
-- restricted collections should fail
SELECT blackboxdb_api.create_collection('config', 'chunks');
SELECT blackboxdb_api.create_collection('config', '_shards');
SELECT blackboxdb_api.create_collection('config', 'shards');
SELECT blackboxdb_api.create_collection('config', 'version');
SELECT blackboxdb_api.create_collection('config', 'databases');
SELECT blackboxdb_api.create_collection('config', 'collections');
SELECT blackboxdb_api.create_collection('config', 'settings');

-- non-restricted config collections should succeed
SELECT blackboxdb_api.create_collection('config', 'my_config_coll');
SELECT blackboxdb_api.create_collection('config', 'user_custom_coll');

-- ===================================================================
-- 2. create_collection_view on config database
-- ===================================================================
-- restricted collections should fail
SELECT blackboxdb_api.create_collection_view('config', '{ "create": "chunks" }');
SELECT blackboxdb_api.create_collection_view('config', '{ "create": "_shards" }');
SELECT blackboxdb_api.create_collection_view('config', '{ "create": "shards" }');
-- non-restricted config collection view should succeed
SELECT blackboxdb_api.create_collection_view('config', '{ "create": "my_config_view_coll" }');

-- ===================================================================
-- 3. dropCollection on config database
-- ===================================================================
-- drop_collection on reserved names is not restricted; returns false (no-op) if collection does not exist
SELECT blackboxdb_api.drop_collection('config', 'chunks');
SELECT blackboxdb_api.drop_collection('config', '_shards');
SELECT blackboxdb_api.drop_collection('config', 'version');

-- dropping non-restricted config collections should succeed
SELECT blackboxdb_api.drop_collection('config', 'my_config_coll');
SELECT blackboxdb_api.drop_collection('config', 'user_custom_coll');
SELECT blackboxdb_api.drop_collection('config', 'my_config_view_coll');

-- dropping non-existent non-restricted collection returns false (no error)
SELECT blackboxdb_api.drop_collection('config', 'nonexistent_config');

-- ===================================================================
-- 4. $out on config database - should be blocked for all collections
-- ===================================================================
-- create a source collection with data for $out/$merge tests
SELECT blackboxdb_api.create_collection('testdb', 'source_coll');
SELECT blackboxdb_api.insert_one('testdb', 'source_coll', '{"_id": 1, "a": 1}');

-- $out to config.chunks should fail (config db blocked entirely)
SELECT * FROM aggregate_cursor_first_page('testdb', '{ "aggregate": "source_coll", "pipeline": [{"$out": {"db": "config", "coll": "chunks"}}], "cursor": {"batchSize": 1} }', 4294967294);

-- $out to config.my_allowed_coll should also fail (config db blocked entirely)
SELECT * FROM aggregate_cursor_first_page('testdb', '{ "aggregate": "source_coll", "pipeline": [{"$out": {"db": "config", "coll": "my_allowed_coll"}}], "cursor": {"batchSize": 1} }', 4294967294);

-- $out to normal db should succeed
SELECT * FROM aggregate_cursor_first_page('testdb', '{ "aggregate": "source_coll", "pipeline": [{"$out": "out_target_coll"}], "cursor": {"batchSize": 1} }', 4294967294);

-- ===================================================================
-- 5. $merge on config database - should be blocked for all collections
-- ===================================================================
-- $merge to config.chunks should fail
SELECT * FROM aggregate_cursor_first_page('testdb', '{ "aggregate": "source_coll", "pipeline": [{"$merge": {"into": {"db": "config", "coll": "chunks"}}}], "cursor": {"batchSize": 1} }', 4294967294);

-- $merge to config.my_allowed_coll should also fail (config db blocked entirely)
SELECT * FROM aggregate_cursor_first_page('testdb', '{ "aggregate": "source_coll", "pipeline": [{"$merge": {"into": {"db": "config", "coll": "my_allowed_coll"}}}], "cursor": {"batchSize": 1} }', 4294967294);

-- $merge to normal db should succeed
SELECT * FROM aggregate_cursor_first_page('testdb', '{ "aggregate": "source_coll", "pipeline": [{"$merge": {"into": "merge_target_coll"}}], "cursor": {"batchSize": 1} }', 4294967294);

-- ===================================================================
-- 6. renameCollection to restricted config collections should fail
-- ===================================================================
-- create a source collection to rename
SELECT blackboxdb_api.create_collection('config', 'rename_source');

-- rename to restricted collection should fail
SELECT blackboxdb_api.rename_collection('config', 'rename_source', 'chunks');
SELECT blackboxdb_api.rename_collection('config', 'rename_source', '_shards');
SELECT blackboxdb_api.rename_collection('config', 'rename_source', 'version');
SELECT blackboxdb_api.rename_collection('config', 'rename_source', 'databases');

-- rename to non-restricted collection should succeed
SELECT blackboxdb_api.rename_collection('config', 'rename_source', 'rename_target');

-- cleanup
SELECT blackboxdb_api.drop_collection('config', 'rename_target');
SELECT blackboxdb_api.drop_collection('testdb', 'source_coll');
SELECT blackboxdb_api.drop_collection('testdb', 'out_target_coll');
SELECT blackboxdb_api.drop_collection('testdb', 'merge_target_coll');

-- ===================================================================
-- 7. shard_collection on restricted config collections should fail
-- ===================================================================
SELECT blackboxdb_api.shard_collection('config', 'chunks', '{"_id": "hashed"}', false);
SELECT blackboxdb_api.shard_collection('config', '_shards', '{"_id": "hashed"}', false);
SELECT blackboxdb_api.shard_collection('config', 'version', '{"_id": "hashed"}', false);
SELECT blackboxdb_api.shard_collection('config', 'databases', '{"_id": "hashed"}', false);

-- shard_collection on non-restricted config collection should succeed
SELECT blackboxdb_api.shard_collection('config', 'shard_test_coll', '{"_id": "hashed"}', false);
SELECT blackboxdb_api.drop_collection('config', 'shard_test_coll');

-- ===================================================================
-- 8. Reserved system namespace creation tests (admin and config system.*)
-- ===================================================================
-- admin.system.roles - not in whitelist, should fail
SELECT blackboxdb_api.create_collection('admin', 'system.roles');
-- admin.system.users - in whitelist but non-writable, creation should fail
SELECT blackboxdb_api.create_collection('admin', 'system.users');
-- admin.system.version - not in whitelist, should fail
SELECT blackboxdb_api.create_collection('admin', 'system.version');
-- config.system.indexBuilds - not in whitelist, should fail
SELECT blackboxdb_api.create_collection('config', 'system.indexBuilds');
-- config.system.preimages - not in whitelist, should fail
SELECT blackboxdb_api.create_collection('config', 'system.preimages');

-- ===================================================================
-- 9. drop_collection on reserved system namespaces is not restricted;
--    returns false (no-op) if collection does not exist
-- ===================================================================
SELECT blackboxdb_api.drop_collection('admin', 'system.roles');
SELECT blackboxdb_api.drop_collection('admin', 'system.users');
SELECT blackboxdb_api.drop_collection('admin', 'system.version');
SELECT blackboxdb_api.drop_collection('config', 'system.indexBuilds');
SELECT blackboxdb_api.drop_collection('config', 'system.preimages');

-- ===================================================================
-- 10. create_indexes_background on reserved namespaces should fail
-- ===================================================================
-- reserved config collection should fail
SELECT * FROM blackboxdb_api.create_indexes_background('config', '{"createIndexes": "chunks", "indexes": [{"key": {"a": 1}, "name": "my_idx_1"}]}');
SELECT * FROM blackboxdb_api.create_indexes_background('config', '{"createIndexes": "version", "indexes": [{"key": {"a": 1}, "name": "my_idx_2"}]}');

-- reserved system namespace should fail
SELECT * FROM blackboxdb_api.create_indexes_background('admin', '{"createIndexes": "system.roles", "indexes": [{"key": {"a": 1}, "name": "my_idx_3"}]}');
SELECT * FROM blackboxdb_api.create_indexes_background('config', '{"createIndexes": "system.indexBuilds", "indexes": [{"key": {"a": 1}, "name": "my_idx_4"}]}');

-- non-reserved collection should succeed (collection will be created)
SELECT * FROM blackboxdb_api.create_indexes_background('config', '{"createIndexes": "user_index_coll", "indexes": [{"key": {"a": 1}, "name": "my_idx_5"}]}');
SELECT blackboxdb_api.drop_collection('config', 'user_index_coll');

-- ===================================================================
-- 11. delete on reserved config collections should fail
-- ===================================================================
SELECT blackboxdb_api.delete('config', '{"delete": "chunks", "deletes": [{"q": {}, "limit": 0}]}');
SELECT blackboxdb_api.delete('config', '{"delete": "_shards", "deletes": [{"q": {}, "limit": 0}]}');
SELECT blackboxdb_api.delete('config', '{"delete": "version", "deletes": [{"q": {}, "limit": 0}]}');

-- ===================================================================
-- 12. delete on reserved system namespaces should fail
-- ===================================================================
SELECT blackboxdb_api.delete('admin', '{"delete": "system.roles", "deletes": [{"q": {}, "limit": 0}]}');
SELECT blackboxdb_api.delete('admin', '{"delete": "system.users", "deletes": [{"q": {}, "limit": 0}]}');
SELECT blackboxdb_api.delete('admin', '{"delete": "system.version", "deletes": [{"q": {}, "limit": 0}]}');
SELECT blackboxdb_api.delete('config', '{"delete": "system.indexBuilds", "deletes": [{"q": {}, "limit": 0}]}');
SELECT blackboxdb_api.delete('config', '{"delete": "system.preimages", "deletes": [{"q": {}, "limit": 0}]}');

-- ===================================================================
-- 13. createCollection on newly added config reserved names should fail
-- ===================================================================
SELECT blackboxdb_api.create_collection('config', 'changelog');
SELECT blackboxdb_api.create_collection('config', 'tags');
SELECT blackboxdb_api.create_collection('config', 'placementHistory');
SELECT blackboxdb_api.create_collection('config', 'mongos');
SELECT blackboxdb_api.create_collection('config', 'transactions');
SELECT blackboxdb_api.create_collection('config', 'locks');
SELECT blackboxdb_api.create_collection('config', 'lockpings');
SELECT blackboxdb_api.create_collection('config', 'migrations');
SELECT blackboxdb_api.create_collection('config', 'migrationCoordinators');
SELECT blackboxdb_api.create_collection('config', 'rangeDeletions');
SELECT blackboxdb_api.create_collection('config', 'reshardingOperations');
SELECT blackboxdb_api.create_collection('config', 'cache.collections');
SELECT blackboxdb_api.create_collection('config', 'cache.databases');

-- ===================================================================
-- 14. createCollection on local reserved names should fail
-- (only non-"system.*" names; "system.*" names are already covered by
--  ValidateCollectionNameForValidSystemNamespace and tested above.)
-- ===================================================================
SELECT blackboxdb_api.create_collection('local', 'oplog.rs');
SELECT blackboxdb_api.create_collection('local', 'startup_log');
SELECT blackboxdb_api.create_collection('local', 'replset.election');
SELECT blackboxdb_api.create_collection('local', 'replset.minvalid');
SELECT blackboxdb_api.create_collection('local', 'replset.initialSyncId');
SELECT blackboxdb_api.create_collection('local', 'replset.oplogTruncateAfterPoint');
-- non-reserved local collection should succeed
SELECT blackboxdb_api.create_collection('local', 'my_local_coll');

-- ===================================================================
-- 15. drop on local reserved names is not restricted (no-op if absent);
--     rename to local reserved names should fail
-- ===================================================================
SELECT blackboxdb_api.drop_collection('local', 'oplog.rs');
SELECT blackboxdb_api.rename_collection('local', 'my_local_coll', 'oplog.rs');
-- cleanup
SELECT blackboxdb_api.drop_collection('local', 'my_local_coll');

-- ===================================================================
-- 16. drop_collection on newly-added config reserved names is not
--     restricted; returns false (no-op) if collection does not exist
--     (covers the names added by this branch; section 3 only covers
--      chunks/_shards/version.)
-- ===================================================================
SELECT blackboxdb_api.drop_collection('config', 'cache.collections');
SELECT blackboxdb_api.drop_collection('config', 'migrations');
SELECT blackboxdb_api.drop_collection('config', 'locks');
SELECT blackboxdb_api.drop_collection('config', 'mongos');
SELECT blackboxdb_api.drop_collection('config', 'transactions');

-- ===================================================================
-- 17. Regression: non-reserved admin/local collections should still work
--     (guards against accidentally blocking the entire admin/local db.)
-- ===================================================================
SELECT blackboxdb_api.create_collection('admin', 'my_admin_coll');
SELECT blackboxdb_api.drop_collection('admin', 'my_admin_coll');
SELECT blackboxdb_api.create_collection('local', 'my_other_local_coll');
SELECT blackboxdb_api.drop_collection('local', 'my_other_local_coll');

-- ===================================================================
-- 18. $out / $merge into admin and local should be blocked
--     (sections 4-5 only cover config; admin/local are also blocked
--      by ValidateTargetNameSpaceForOutputStage.)
-- ===================================================================
SELECT blackboxdb_api.create_collection('testdb', 'agg_source');
SELECT blackboxdb_api.insert_one('testdb', 'agg_source', '{"_id": 1, "a": 1}');
-- $out to admin / local should fail (internal database resource)
SELECT * FROM aggregate_cursor_first_page('testdb', '{ "aggregate": "agg_source", "pipeline": [{"$out": {"db": "admin", "coll": "anycoll"}}], "cursor": {"batchSize": 1} }', 4294967294);
SELECT * FROM aggregate_cursor_first_page('testdb', '{ "aggregate": "agg_source", "pipeline": [{"$out": {"db": "local", "coll": "anycoll"}}], "cursor": {"batchSize": 1} }', 4294967294);
-- $merge to admin / local should fail (internal database resource)
SELECT * FROM aggregate_cursor_first_page('testdb', '{ "aggregate": "agg_source", "pipeline": [{"$merge": {"into": {"db": "admin", "coll": "anycoll"}}}], "cursor": {"batchSize": 1} }', 4294967294);
SELECT * FROM aggregate_cursor_first_page('testdb', '{ "aggregate": "agg_source", "pipeline": [{"$merge": {"into": {"db": "local", "coll": "anycoll"}}}], "cursor": {"batchSize": 1} }', 4294967294);
-- cleanup
SELECT blackboxdb_api.drop_collection('testdb', 'agg_source');

-- ===================================================================
-- 19. Flag-off behaviour: gate disengaged for config/local reserved names
-- ===================================================================
SET blackboxdb.enableNewNamespaceValidation TO off;
-- Reserved names should now be allowed because the gate is off.
SELECT blackboxdb_api.create_collection('local', 'oplog.rs');
SELECT blackboxdb_api.drop_collection('local', 'oplog.rs');
SELECT blackboxdb_api.create_collection('config', 'locks');
SELECT blackboxdb_api.drop_collection('config', 'locks');
RESET blackboxdb.enableNewNamespaceValidation;

-- ===================================================================
-- 20. create_indexes_non_concurrently on reserved namespaces should fail
--     (covers the second of three createIndexes entry points; the third
--      entry point is the utility-hook CALL path -- exercised in
--      production via the gateway, not reachable from regress.)
-- ===================================================================
-- reserved config collection should fail
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('config', '{"createIndexes": "chunks", "indexes": [{"key": {"a": 1}, "name": "nci_idx_1"}]}');
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('config', '{"createIndexes": "transactions", "indexes": [{"key": {"a": 1}, "name": "nci_idx_2"}]}');

-- reserved system namespace should fail
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('admin', '{"createIndexes": "system.roles", "indexes": [{"key": {"a": 1}, "name": "nci_idx_3"}]}');
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('config', '{"createIndexes": "system.indexBuilds", "indexes": [{"key": {"a": 1}, "name": "nci_idx_4"}]}');

-- reserved local collection should fail
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('local', '{"createIndexes": "oplog.rs", "indexes": [{"key": {"a": 1}, "name": "nci_idx_5"}]}');

-- ===================================================================
-- 21. Error-precedence edge case: empty indexes:[] on a reserved
--     namespace must throw IllegalOperation BEFORE the parser throws
--     BadValue. Covered for both reachable entry points.
-- ===================================================================
-- background path
SELECT * FROM blackboxdb_api.create_indexes_background('config', '{"createIndexes": "transactions", "indexes": []}');
-- non-concurrent path
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('config', '{"createIndexes": "chunks", "indexes": []}');

-- Sanity: empty indexes:[] on a non-reserved namespace still produces
-- the parser's error (validator must not over-trigger).
SELECT * FROM blackboxdb_api.create_indexes_background('config', '{"createIndexes": "non_reserved_user_coll", "indexes": []}');

-- ===================================================================
-- 22. GUC-off behavior for createIndexes: fallback blocks ALL admin
--     and config createIndexes (matches legacy gateway pre-check
--     behavior so that turning the GUC off is a clean revert).
-- ===================================================================
SET blackboxdb.enableNewNamespaceValidation TO off;

-- With GUC off, createIndexes on ANY config/admin collection is blocked
-- by the fallback (regardless of whether the name is reserved).
SELECT * FROM blackboxdb_api.create_indexes_background('config', '{"createIndexes": "transactions", "indexes": []}');
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('config', '{"createIndexes": "chunks", "indexes": []}');
SELECT * FROM blackboxdb_api.create_indexes_background('config', '{"createIndexes": "guc_off_user_coll", "indexes": [{"key": {"a": 1}, "name": "guc_off_idx_1"}]}');
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('admin', '{"createIndexes": "user_coll", "indexes": [{"key": {"a": 1}, "name": "guc_off_idx_2"}]}');

-- With GUC off, createIndexes on a normal database still works.
SELECT blackboxdb_api.create_collection('testdb', 'guc_off_normal_coll');
SELECT * FROM blackboxdb_api.create_indexes_background('testdb', '{"createIndexes": "guc_off_normal_coll", "indexes": [{"key": {"a": 1}, "name": "guc_off_idx_3"}]}');
SELECT blackboxdb_api.drop_collection('testdb', 'guc_off_normal_coll');

-- ===================================================================
-- 23. We should always allow drop on system collection and config and chunks collections for compat
-- ===================================================================

SELECT blackboxdb_api.drop_collection('db', 'system.collection');
SELECT blackboxdb_api.drop_collection('db', 'system.views');
SELECT blackboxdb_api.drop_collection('config', 'chunks');

BEGIN;
SET LOCAL blackboxdb.enableNewNamespaceValidation TO off;
SELECT blackboxdb_api.create_collection('config','chunks');
SELECT blackboxdb_api.drop_collection('config', 'chunks');
ROLLBACK;


RESET blackboxdb.enableNewNamespaceValidation;


