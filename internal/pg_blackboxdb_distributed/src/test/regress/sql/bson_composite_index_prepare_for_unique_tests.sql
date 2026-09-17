SET search_path TO blackboxdb_api,blackboxdb_core,blackboxdb_api_catalog;

SET citus.next_shard_id TO 5880000;
SET blackboxdb.next_collection_id TO 588000;
SET blackboxdb.next_collection_index_id TO 588000;

set blackboxdb.enablePrepareUnique to on;

-- if blackboxdb_extended_rum exists, set alternate index handler
SELECT pg_catalog.set_config('blackboxdb.alternate_index_handler_name', 'extended_rum', false), extname FROM pg_extension WHERE extname = 'blackboxdb_extended_rum';

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('prep_unique_db', '{ "createIndexes": "collection", "indexes": [ { "name": "a_1", "key": { "a": 1 }, "storageEngine": { "enableOrderedIndex": true, "buildAsUnique": true } } ] }', TRUE);
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('prep_unique_db', '{ "createIndexes": "collection", "indexes": [ { "name": "c_1", "key": { "c": 1 }, "storageEngine": { "enableOrderedIndex": true, "buildAsUnique": true } } ] }', TRUE);

\d blackboxdb_data.documents_588001;

-- inserting and querying works fine.
select COUNT(blackboxdb_api.insert_one('prep_unique_db', 'collection', FORMAT('{ "_id": %s, "a": %s, "b": %s, "c": %s }', i, i, 100-i, i)::bson)) FROM generate_series(1, 100) i;

-- insert a duplicate, should not fail
SELECT blackboxdb_api.insert_one('prep_unique_db', 'collection', '{ "_id": 101, "a": 1, "c": 1 }');
SELECT blackboxdb_api.insert_one('prep_unique_db', 'collection', '{ "_id": 201, "a": 201, "c": 1 }');

ANALYZE blackboxdb_data.documents_588001;

set citus.propagate_set_commands to 'local';

BEGIN;
set local blackboxdb.enableExtendedExplainPlans to on;
set local enable_seqscan to off;
SELECT blackboxdb_distributed_test_helpers.run_explain_and_trim($cmd$ EXPLAIN (COSTS OFF, ANALYZE ON, VERBOSE ON, TIMING OFF, SUMMARY OFF, BUFFERS OFF) select document FROM bson_aggregation_find('prep_unique_db', '{ "find": "collection", "filter": {"a": {"$gt": 2}} }') $cmd$);
ROLLBACK;

BEGIN;
set local blackboxdb.enableExtendedExplainPlans to on;
SELECT blackboxdb_distributed_test_helpers.run_explain_and_trim($cmd$ EXPLAIN (COSTS OFF, ANALYZE ON, VERBOSE ON, TIMING OFF, SUMMARY OFF, BUFFERS OFF) select document FROM bson_aggregation_find('prep_unique_db', '{ "find": "collection", "filter": {"a": {"$gt": 2}}, "sort": {"a": 1} }') $cmd$);
ROLLBACK;


-- multiple fields work fine
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('prep_unique_db', '{ "createIndexes": "collection", "indexes": [ { "name": "a_1_b_1", "key": { "a": 1, "b": 1 }, "storageEngine": { "enableOrderedIndex": true, "buildAsUnique": true } } ] }', TRUE);

SELECT bson_dollar_unwind(cursorpage, '$cursor.firstBatch') FROM blackboxdb_api.list_indexes_cursor_first_page('prep_unique_db', '{ "listIndexes": "collection" }') ORDER BY 1;

\d blackboxdb_data.documents_588001;
ANALYZE blackboxdb_data.documents_588001;

BEGIN;
set local blackboxdb.enableExtendedExplainPlans to on;
set local enable_seqscan to off;
SELECT blackboxdb_distributed_test_helpers.run_explain_and_trim($cmd$ EXPLAIN (COSTS OFF, ANALYZE ON, VERBOSE ON, TIMING OFF, SUMMARY OFF, BUFFERS OFF) select document FROM bson_aggregation_find('prep_unique_db', '{ "find": "collection", "filter": {"a": {"$gt": 2}, "b": 3} }') $cmd$);
ROLLBACK;

-- test error paths
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('prep_unique_db', '{"createIndexes": "collection", "indexes": [{"key": {"a": 1 }, "storageEngine": { "enableOrderedIndex": false, "buildAsUnique": true }, "name": "invalid"}]}',true);
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('prep_unique_db', '{"createIndexes": "collection", "indexes": [{"key": {"b": 1 }, "unique": true, "storageEngine": { "enableOrderedIndex": true, "buildAsUnique": true }, "name": "invalid"}]}',true);


-- Now that we have indexes with builtAsUnique, test prepareUnique.
SELECT blackboxdb_api.coll_mod('prep_unique_db', 'collection', '{ "collMod": "collection", "index": { "name": "a_1", "prepareUnique": true } }');
SELECT blackboxdb_api.coll_mod('prep_unique_db', 'collection', '{ "collMod": "collection", "index": { "name": "c_1", "prepareUnique": true } }');

\d blackboxdb_data.documents_588001;

-- inserting a duplicate should fail now.
SELECT blackboxdb_api.insert_one('prep_unique_db', 'collection', '{ "_id": 102, "a": 1 }');

-- but we already have a duplicate because prepareUnique doesn't enforce uniqueness on existing data.
SELECT document from blackboxdb_data.documents_588001 where document @@ '{"a": 1}';

-- now convert it to unique (this should fail for GUC check)
set blackboxdb.enableCollModUnique to off;
SELECT blackboxdb_api.coll_mod('prep_unique_db', 'collection', '{ "collMod": "collection", "index": { "name": "a_1", "unique": true } }');

-- now this fails with existing unique violations
set blackboxdb.enableCollModUnique to on;
SELECT blackboxdb_api.coll_mod('prep_unique_db', 'collection', '{ "collMod": "collection", "index": { "name": "a_1", "unique": true } }');

-- now drop the duplicate
SELECT blackboxdb_api.delete('prep_unique_db', '{ "delete": "collection", "deletes": [ { "q": { "_id": 101 }, "limit": 1 } ]}');

-- now convert to unique succeeds
SELECT blackboxdb_api.coll_mod('prep_unique_db', 'collection', '{ "collMod": "collection", "index": { "name": "a_1", "unique": true } }');
SELECT bson_dollar_unwind(cursorpage, '$cursor.firstBatch') FROM blackboxdb_api.list_indexes_cursor_first_page('prep_unique_db', '{ "listIndexes": "collection" }') ORDER BY 1;

-- sharding should work.
SELECT blackboxdb_api.shard_collection('{ "shardCollection": "prep_unique_db.collection", "key": { "_id": "hashed" } }');

set citus.show_shards_for_app_name_prefixes to '*';

\d blackboxdb_data.documents_588001_5880006;

-- list indexes, a_1_b_1 index should have buildAsUnique but a_1 should be prepareUnique after sharding.
SELECT bson_dollar_unwind(cursorpage, '$cursor.firstBatch') FROM blackboxdb_api.list_indexes_cursor_first_page('prep_unique_db', '{ "listIndexes": "collection" }') ORDER BY 1;

-- now convert a_1_b_1 index to prepareUnique
SELECT blackboxdb_api.coll_mod('prep_unique_db', 'collection', '{ "collMod": "collection", "index": { "name": "a_1_b_1", "prepareUnique": true } }');

\d blackboxdb_data.documents_588001_5880004;

-- convert to unique
SELECT blackboxdb_api.coll_mod('prep_unique_db', 'collection', '{ "collMod": "collection", "index": { "name": "a_1_b_1", "unique": true } }');

-- now convert to unique for "c" - succeeds since unique is per shard
SELECT blackboxdb_api.coll_mod('prep_unique_db', 'collection', '{ "collMod": "collection", "index": { "name": "c_1", "unique": true } }');

\d blackboxdb_data.documents_588001_5880004;

CALL blackboxdb_api.drop_indexes('prep_unique_db', '{ "dropIndexes": "collection", "index": "c_1" }');

-- now unshard the collection
SELECT blackboxdb_api.unshard_collection('{ "unshardCollection": "prep_unique_db.collection" }');

\d blackboxdb_data.documents_588001;

SELECT bson_dollar_unwind(cursorpage, '$cursor.firstBatch') FROM blackboxdb_api.list_indexes_cursor_first_page('prep_unique_db', '{ "listIndexes": "collection" }') ORDER BY 1;

-- now create another index with buildAsUnique, then convert and drop the collection
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('prep_unique_db', '{ "createIndexes": "collection", "indexes": [ { "name": "c1_1", "key": { "d": 1 }, "storageEngine": { "enableOrderedIndex": true, "buildAsUnique": true } } ] }', TRUE);
SELECT blackboxdb_api.coll_mod('prep_unique_db', 'collection', '{ "collMod": "collection", "index": { "name": "c1_1", "prepareUnique": true } }');

\d blackboxdb_data.documents_588001;


SELECT blackboxdb_api.drop_collection('prep_unique_db', 'collection');

-- test error paths for prepareUnique
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('prep_unique_db', '{ "createIndexes": "collection", "indexes": [ { "name": "d_1", "key": { "d": 1 }, "storageEngine": { "enableOrderedIndex": true } } ] }', TRUE);
SELECT blackboxdb_api.coll_mod('prep_unique_db', 'collection', '{ "collMod": "collection", "index": { "name": "d_1", "prepareUnique": true } }');

-- try to set prepareUnique to false
-- TODO: this can be supported in future if needed.
SELECT blackboxdb_api.coll_mod('prep_unique_db', 'collection', '{ "collMod": "collection", "index": { "name": "d_1", "prepareUnique": false } }');

-- now create a unique index and a prepareUnique index on different fields, and let's compare the pg_constraint entries.
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('prep_unique_db', '{ "createIndexes": "collection", "indexes": [ { "name": "e_1", "key": { "e": 1 }, "unique": true, "storageEngine": { "enableOrderedIndex": true } },
                                                                                                                                { "name": "f_1", "key": { "f": 1 }, "storageEngine": { "enableOrderedIndex": true, "buildAsUnique": true } } ] }', TRUE);

-- test this one with the forceUpdateIndexInline GUC
SET blackboxdb.forceUpdateIndexInline TO on;
SELECT blackboxdb_api.coll_mod('prep_unique_db', 'collection', '{ "collMod": "collection", "index": { "name": "f_1", "prepareUnique": true } }');
RESET blackboxdb.forceUpdateIndexInline;

-- now compare the pg_constraint entries for the two indexes
SELECT 
    c1.conname AS conname1,
    c2.conname AS conname2,
    c1.contype AS contype1,
    c2.contype AS contype2,
    c1.conkey AS conkey1,
    c2.conkey AS conkey2,
    (c1.conexclop = c2.conexclop) AS conexclop_equal
FROM pg_constraint c1
JOIN pg_constraint c2 
  ON c1.conrelid = c2.conrelid
WHERE c1.conrelid = 'blackboxdb_data.documents_588002'::regclass
  AND c1.conname::text like '%_rum_%'
  AND c1.oid < c2.oid
ORDER BY c1.conname, c2.conname;

-- running prepareUnique again should be a no-op
SELECT blackboxdb_api.coll_mod('prep_unique_db', 'collection', '{ "collMod": "collection", "index": { "name": "f_1", "prepareUnique": true } }');

-- list indexes there we should not see buildAsUnique.
SELECT bson_dollar_unwind(cursorpage, '$cursor.firstBatch') FROM blackboxdb_api.list_indexes_cursor_first_page('prep_unique_db', '{ "listIndexes": "collection" }') ORDER BY 1;

\d blackboxdb_data.documents_588002;

-- turn off feature, should fail
set blackboxdb.enablePrepareUnique to off;
SELECT blackboxdb_api.coll_mod('prep_unique_db', 'collection', '{ "collMod": "collection", "index": { "name": "f_1", "prepareUnique": true } }');

SELECT blackboxdb_api.drop_collection('prep_unique_db', 'collection');

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('prep_unique_db', '{ "createIndexes": "collection", "indexes": [ { "name": "f_1", "key": { "f": 1 }, "storageEngine": { "enableOrderedIndex": true, "buildAsUnique": true } } ] }', TRUE);

-- test with a secondary user
SELECT blackboxdb_api.create_user('{"createUser":"newPrepareUniqueUser", "pwd":"Admin123!", "roles":[{"role":"readWriteAnyDatabase","db":"admin"}, {"role":"clusterAdmin","db":"admin"}]}');

\c - newPrepareUniqueUser
set blackboxdb.enablePrepareUnique to on;

SELECT blackboxdb_api.coll_mod('prep_unique_db', 'collection', '{ "collMod": "collection", "index": { "name": "f_1", "prepareUnique": true } }');

\d blackboxdb_data.documents_588003;


-- create prepareUnique & conversion to unique with a violation in one shard only.
-- insert where shKey is i % 10 where there's 10 shard keys given 100 rows
select COUNT(blackboxdb_api.insert_one('prep_unique_db', 'shard_collection', FORMAT('{ "_id": %s, "a": %s, "shkey": %s }', i, i, i % 10)::blackboxdb_core.bson)) FROM generate_series(1, 100) i;

-- build "a"
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('prep_unique_db', '{"createIndexes": "shard_collection", "indexes": [{"key": {"a": 1 }, "storageEngine": { "enableOrderedIndex": true, "buildAsUnique": true }, "name": "a_1_shard"}]}',true);

-- insert 2 duplicates in just one shard each
SELECT blackboxdb_api.insert_one('prep_unique_db', 'shard_collection', '{ "_id": 201, "a": 50, "shkey": 0 }');
SELECT blackboxdb_api.insert_one('prep_unique_db', 'shard_collection', '{ "_id": 202, "a": 51, "shkey": 1 }');

-- prepare unique (works with the violation on one shard)
SELECT blackboxdb_api.coll_mod('prep_unique_db', 'shard_collection', '{ "collMod": "shard_collection", "index": { "name": "a_1_shard", "prepareUnique": true } }');

-- this now fails (new unique violations)
SELECT blackboxdb_api.insert_one('prep_unique_db', 'shard_collection', '{ "_id": 203, "a": 55, "shkey": 5 }');
SELECT blackboxdb_api.insert_one('prep_unique_db', 'shard_collection', '{ "_id": 204, "a": 50, "shkey": 0 }');

SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('prep_unique_db', '{ "find": "shard_collection", "filter": { "a": 50 } }');

-- this fails (one shard has a duplicate)
set blackboxdb.enableCollModUnique to on;
SELECT blackboxdb_api.coll_mod('prep_unique_db', 'shard_collection', '{ "collMod": "shard_collection", "index": { "name": "a_1_shard", "unique": true } }');

-- fixing the duplicates allows it to go through
SELECT blackboxdb_api.delete('prep_unique_db', '{ "delete": "shard_collection", "deletes": [ { "q": { "_id": 201 }, "limit": 1 } ]}');
SELECT blackboxdb_api.coll_mod('prep_unique_db', 'shard_collection', '{ "collMod": "shard_collection", "index": { "name": "a_1_shard", "unique": true } }');

SELECT blackboxdb_api.delete('prep_unique_db', '{ "delete": "shard_collection", "deletes": [ { "q": { "_id": 202 }, "limit": 1 } ]}');
SELECT blackboxdb_api.coll_mod('prep_unique_db', 'shard_collection', '{ "collMod": "shard_collection", "index": { "name": "a_1_shard", "unique": true } }');