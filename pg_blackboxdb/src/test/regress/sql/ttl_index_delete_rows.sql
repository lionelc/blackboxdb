SET search_path TO blackboxdb_core, blackboxdb_api, blackboxdb_api_catalog, public;
SET blackboxdb.next_collection_id TO 781000;
SET blackboxdb.next_collection_index_id TO 781000;

-- make sure ttl job is scheduled and disable it to avoid flakiness on the test as it could run on its schedule and delete documents before we run our commands in the test
select schedule, command, active from cron.job where jobname like '%ttl_task%';

select cron.unschedule(jobid) from cron.job where jobname like '%ttl_task%';

-- 1. Populate collection with a set of documents with different combination of $date fields --
SELECT blackboxdb_api.insert_one('ttl_tests','coll1', '{ "_id" : 0, "ttl" : { "$date": { "$numberLong": "-1000" } } }', NULL);
SELECT blackboxdb_api.insert_one('ttl_tests','coll1', '{ "_id" : 1, "ttl" : { "$date": { "$numberLong": "0" } } }', NULL);
SELECT blackboxdb_api.insert_one('ttl_tests','coll1', '{ "_id" : 2, "ttl" : { "$date": { "$numberLong": "100" } } }', NULL);
    -- Documents with date older than when the test was written
SELECT blackboxdb_api.insert_one('ttl_tests','coll1', '{ "_id" : 3, "ttl" : { "$date": { "$numberLong": "1657900030774" } } }', NULL);
    -- Documents with date way in future
SELECT blackboxdb_api.insert_one('ttl_tests','coll1', '{ "_id" : 4, "ttl" : { "$date": { "$numberLong": "2657899731608" } } }', NULL);
    -- Documents with date array
SELECT blackboxdb_api.insert_one('ttl_tests','coll1', '{ "_id" : 5, "ttl" : [{ "$date": { "$numberLong": "100" }}] }', NULL);
    -- Documents with date array, should be deleted based on min timestamp
SELECT blackboxdb_api.insert_one('ttl_tests','coll2', '{ "_id" : 6, "ttl" : [{ "$date": { "$numberLong": "100" }}, { "$date": { "$numberLong": "2657899731608" }}] }', NULL);
SELECT blackboxdb_api.insert_one('ttl_tests','coll1', '{ "_id" : 6, "other_field" : [{ "$date": { "$numberLong": "100" }}, { "$date": { "$numberLong": "2657899731608" }}] }', NULL);
SELECT blackboxdb_api.insert_one('ttl_tests','coll2', '{ "_id" : 7, "ttl" : [true, { "$date": { "$numberLong": "100" }}, { "$date": { "$numberLong": "2657899731608" }}] }', NULL);
SELECT blackboxdb_api.insert_one('ttl_tests','coll1', '{ "_id" : 7, "other_field" : [true, { "$date": { "$numberLong": "100" }}, { "$date": { "$numberLong": "2657899731608" }}] }', NULL);
    -- Documents with non-date ttl field
SELECT blackboxdb_api.insert_one('ttl_tests','coll2', '{ "_id" : 8, "ttl" : true }', NULL);
SELECT blackboxdb_api.insert_one('ttl_tests','coll1', '{ "_id" : 8, "other_field" : true }', NULL);
    -- Documents with non-date ttl field
SELECT blackboxdb_api.insert_one('ttl_tests','coll2', '{ "_id" : 9, "ttl" : "would not expire" }', NULL);
SELECT blackboxdb_api.insert_one('ttl_tests','coll1', '{ "_id" : 9, "other_field" : "would not expire" }', NULL);

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('ttl_tests', '{"createIndexes": "coll1", "indexes": [{"key": {"ttl": 1}, "name": "ttl_index", "v" : 1, "expireAfterSeconds": 5}]}', true);
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('ttl_tests', '{"createIndexes": "coll2", "indexes": [{"key": {"ttl": 1}, "name": "ttl_index", "v" : 1, "expireAfterSeconds": 10}]}', true);

SELECT document FROM blackboxdb_api.collection('ttl_tests', 'coll1');
SELECT document FROM blackboxdb_api.collection('ttl_tests', 'coll2');

-- should not delete any documents because batch size is 0
CALL blackboxdb_api_internal.delete_expired_rows(0);

SELECT document FROM blackboxdb_api.collection('ttl_tests', 'coll1');
SELECT document FROM blackboxdb_api.collection('ttl_tests', 'coll2');

-- should delete all expired rows, but only ttl field since we haven't created an index for other_field
CALL blackboxdb_api_internal.delete_expired_rows();
SELECT document FROM blackboxdb_api.collection('ttl_tests', 'coll1');
SELECT document FROM blackboxdb_api.collection('ttl_tests', 'coll2');

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('ttl_tests', '{"createIndexes": "coll1", "indexes": [{"key": {"other_field": 1}, "name": "ttl_index_other_field", "v" : 1, "expireAfterSeconds": 10}]}', true);

-- should now delete other_field entries
CALL blackboxdb_api_internal.delete_expired_rows();
SELECT document FROM blackboxdb_api.collection('ttl_tests', 'coll1');

-- insert more data and create one more ttl index
SELECT blackboxdb_api.insert_one('ttl_tests','coll2', '{ "_id" : 10, "new_field" : [{ "$date": { "$numberLong": "100" }}, { "$date": { "$numberLong": "2657899731608" }}] }', NULL);
SELECT blackboxdb_api.insert_one('ttl_tests','coll2', '{ "_id" : 11, "new_field" : true }', NULL);

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('ttl_tests', '{"createIndexes": "coll2", "indexes": [{"key": {"new_field": 1}, "name": "ttl_index_new_field", "v" : 1, "expireAfterSeconds": 10}]}', true);

SELECT blackboxdb_api.insert_one('ttl_tests','coll1', '{ "_id" : 11, "ttl" : { "$date": { "$numberLong": "100" }} }', NULL);
SELECT blackboxdb_api.insert_one('ttl_tests','coll1', '{ "_id" : 12, "other_field" : [{ "$date": { "$numberLong": "100" }}, { "$date": { "$numberLong": "2657899731608" }}] }', NULL);
SELECT blackboxdb_api.insert_one('ttl_tests','coll1', '{ "_id" : 13, "ttl" : true, "other_field": {"$date": {"$numberLong": "-10" }} }', NULL);

SELECT document FROM blackboxdb_api.collection('ttl_tests', 'coll1');
SELECT document FROM blackboxdb_api.collection('ttl_tests', 'coll2');

CALL blackboxdb_api_internal.delete_expired_rows();

SELECT document FROM blackboxdb_api.collection('ttl_tests', 'coll1');
SELECT document FROM blackboxdb_api.collection('ttl_tests', 'coll2');

SELECT drop_collection('ttl_tests', 'coll1');
SELECT drop_collection('ttl_tests', 'coll2');

-- test with partial filter expression
SELECT blackboxdb_api.insert_one('ttl_tests','coll1', '{ "_id" : 1, "ttl" : { "$date": { "$numberLong": "-1000" } }, "a": 1, "b":55 }');

-- should not be pruned since it doesn't match the partial filter expression
SELECT blackboxdb_api.insert_one('ttl_tests','coll1', '{ "_id" : 2, "ttl" : { "$date": { "$numberLong": "-1000" } }, "a": 1, "b":54 }');
SELECT blackboxdb_api.insert_one('ttl_tests','coll1', '{ "_id" : 3, "ttl" : { "$date": { "$numberLong": "-1000" } }, "b":55 }');

SELECT blackboxdb_api_internal.create_indexes_non_concurrently(
  'ttl_tests',
  '{
     "createIndexes": "coll1",
     "indexes": [
       {
         "key": {"ttl": 1},
         "name": "ttl_pfe_index",
         "expireAfterSeconds" : 5,
         "partialFilterExpression":
         {
           "$and": [
             {"b": 55},
             {"a": {"$exists": true}}
            ]
         }
       }
     ]
   }',
   true
);

CALL blackboxdb_api_internal.delete_expired_rows();

SELECT document FROM blackboxdb_api.collection('ttl_tests', 'coll1');

SELECT drop_collection('ttl_tests', 'coll1');

-- Test that the LP_DEAD code path in delete_expired_rows() does not break the OSS suite.
-- The extended LP_DEAD assertions (deadEntriesOrPagesSkipped) are covered in distributed tests.
-- Here we just verify the basic flow succeeds end-to-end.

SET blackboxdb.enableDeadIndexEntryMarkingByTTLTask to on;

SELECT blackboxdb_api.create_collection('ttl_lpdead_db', 'ttlDeadTupleTest');

SELECT collection_id AS dead_tup_col FROM blackboxdb_api_catalog.collections
    WHERE database_name = 'ttl_lpdead_db' AND collection_name = 'ttlDeadTupleTest' \gset

-- Disable autovacuum for predictability
SELECT FORMAT('ALTER TABLE blackboxdb_data.documents_%s SET (autovacuum_enabled = off)', :dead_tup_col) \gexec

-- Insert 1000 expired documents (batch 1)
SELECT COUNT(blackboxdb_api.insert_one('ttl_lpdead_db', 'ttlDeadTupleTest',
    FORMAT('{ "_id": %s, "ttl": { "$date": { "$numberLong": "%s" } } }', i, i)::blackboxdb_core.bson))
FROM generate_series(1, 1000) AS i;

-- Create composite TTL index
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('ttl_lpdead_db',
    '{"createIndexes": "ttlDeadTupleTest", "indexes": [{"key": {"ttl": 1}, "name": "ttl_dead_idx", "v":1, "expireAfterSeconds": 5, "enableCompositeTerm": true}]}', true);

-- First TTL delete: removes all 1000 rows
BEGIN;
SET LOCAL blackboxdb.RepeatPurgeIndexesForTTLTask to off;
CALL blackboxdb_api_internal.delete_expired_rows(1000);
END;

SELECT count(*) AS rows_after_first_delete FROM blackboxdb_api.collection('ttl_lpdead_db', 'ttlDeadTupleTest');

-- VACUUM leaves index entries stale (LP_DEAD scenario)
SELECT FORMAT('VACUUM (FREEZE ON, INDEX_CLEANUP OFF) blackboxdb_data.documents_%s', :dead_tup_col) \gexec

-- Insert 10 more expired rows (batch 2)
SELECT COUNT(blackboxdb_api.insert_one('ttl_lpdead_db', 'ttlDeadTupleTest',
    FORMAT('{ "_id": %s, "ttl": { "$date": { "$numberLong": "%s" } } }', i, i)::blackboxdb_core.bson))
FROM generate_series(2001, 2010) AS i;

-- Second TTL delete: encounters 1000 stale + 10 live entries; should complete without error
BEGIN;
SET LOCAL blackboxdb.RepeatPurgeIndexesForTTLTask to off;
CALL blackboxdb_api_internal.delete_expired_rows(1000);
END;

SELECT count(*) AS rows_after_second_delete FROM blackboxdb_api.collection('ttl_lpdead_db', 'ttlDeadTupleTest');

RESET blackboxdb.enableDeadIndexEntryMarkingByTTLTask;
SELECT blackboxdb_api.drop_collection('ttl_lpdead_db', 'ttlDeadTupleTest');