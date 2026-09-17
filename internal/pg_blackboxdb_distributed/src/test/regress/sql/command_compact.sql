SET citus.next_shard_id TO 2432000;
SET blackboxdb.next_collection_id TO 24320;
SET blackboxdb.next_collection_index_id TO 24320;
SET search_path TO blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog,blackboxdb_api_internal;

SELECT blackboxdb_api.compact(NULL);
SELECT blackboxdb_api.compact('{}');
SELECT blackboxdb_api.compact('{"noIdea": "collection1"}');
SELECT blackboxdb_api.compact('{"compact": "non_existing_collection"}');
SELECT blackboxdb_api.compact('{"compact": 1 }');
SELECT blackboxdb_api.compact('{"compact": true }');
SELECT blackboxdb_api.compact('{"compact": ["coll"]}');

SELECT blackboxdb_api.create_collection('commands_compact_db','compact_test');

SELECT blackboxdb_api.compact('{"compact": "compact_test", "dryRun": "invalid"}');
SELECT blackboxdb_api.compact('{"compact": "compact_test", "comment": "test comment"}');
SELECT blackboxdb_api.compact('{"compact": "compact_test", "force": false}');

-- Enable the GUC so that compact actually performs VACUUM FULL
SET blackboxdb.enableCompactVacuumFull TO on;

-- Insert a single document
SELECT blackboxdb_api.insert_one('commands_compact_db', 'compact_test', FORMAT('{ "_id": 1, "a": "%s", "c": [ %s "d" ] }', repeat('Sample', 100000), repeat('"' || repeat('a', 1000) || '", ', 5000))::blackboxdb_core.bson);


-- Bloat the table
DO $$
DECLARE i int;
BEGIN
-- each doc is "a": 500KB, "c": 5 MB - ~5.5 MB & there's 10 of them
FOR i IN 1..45 LOOP
UPDATE blackboxdb_data.documents_24321 SET document = document::bytea::bson WHERE document @@ '{ "_id": 1 }';
COMMIT;
END LOOP;
END;
$$;

-- VALID, first need to analyze the table so that stats are up to date
ANALYZE VERBOSE blackboxdb_data.documents_24321;
SELECT blackboxdb_api.coll_stats('commands_compact_db','compact_test')->>'storageSize' as before_compact_size \gset

-- TODO: even after analyze it seems like pg_class stats for toast tables are not updated for test run.
-- Need to investigate this further for test, for live servers this should be okay because the analyze thereshold is set to 0.
SELECT blackboxdb_api.compact('{"compact": "compact_test", "$db": "commands_compact_db", "dryRun": true}');
SELECT blackboxdb_api.compact('{"compact": "compact_test", "$db": "commands_compact_db", "dryRun": false}');
SELECT blackboxdb_api.coll_stats('commands_compact_db','compact_test')->>'storageSize' as after_compact_size \gset

SELECT :after_compact_size::bigint < :before_compact_size::bigint as is_compacted;

SELECT blackboxdb_api.drop_collection('commands_compact_db','compact_test');

-- sharded test
SELECT blackboxdb_api.create_collection('commands_compact_db', 'compact_test_sharded');
SELECT blackboxdb_api.shard_collection('commands_compact_db', 'compact_test_sharded', '{"_id": "hashed"}', false);

DO $$
DECLARE i int;
BEGIN
-- each doc is "a": 500KB, "c": 5 MB - ~5.5 MB & there's 10 of them
FOR i IN 1..51 LOOP
PERFORM blackboxdb_api.insert_one('commands_compact_db', 'compact_test_sharded', FORMAT('{ "_id": %s, "a": "%s", "c": [ %s "d" ] }',i, repeat('Sample', 100000), repeat('"' || repeat('a', 1000) || '", ', 5000))::blackboxdb_core.bson);
COMMIT;
END LOOP;
END;
$$;

DO $$
DECLARE i int;
BEGIN
-- each doc is "a": 500KB, "c": 5 MB - ~5.5 MB & there's 10 of them
FOR i IN 1..45 LOOP
UPDATE blackboxdb_data.documents_24322 SET document = document::bytea::bson WHERE document @@ '{ "_id": 1 }';
COMMIT;
END LOOP;
END;
$$;

-- VALID, first need to analyze the table so that stats are up to date
ANALYZE VERBOSE blackboxdb_data.documents_24322;
SELECT blackboxdb_api.coll_stats('commands_compact_db','compact_test_sharded')->>'storageSize' AS sharded_before_compact_size \gset

-- TODO: even after analyze it seems like pg_class stats for toast tables are not updated for test run.
-- Need to investigate this further for test, for live servers this should be okay because the analyze thereshold is set to 0.
SELECT blackboxdb_api.compact('{"compact": "compact_test_sharded", "$db": "commands_compact_db", "dryRun": true}');
SELECT blackboxdb_api.compact('{"compact": "compact_test_sharded", "$db": "commands_compact_db", "dryRun": false}');
SELECT blackboxdb_api.coll_stats('commands_compact_db','compact_test_sharded')->>'storageSize' AS sharded_after_compact_size \gset

SELECT :sharded_after_compact_size::bigint < :sharded_before_compact_size::bigint as is_sharded_compacted;

SELECT blackboxdb_api.drop_collection('commands_compact_db','compact_test_sharded');


-- sharded test
SELECT blackboxdb_api.create_collection('commands_compact_db', 'compact_test_sharded');
SELECT blackboxdb_api.shard_collection('commands_compact_db', 'compact_test_sharded', '{"_id": "hashed"}', false);

DO $$
DECLARE i int;
BEGIN
-- each doc is "a": 500KB, "c": 5 MB - ~5.5 MB & there's 10 of them
FOR i IN 1..51 LOOP
PERFORM blackboxdb_api.insert_one('commands_compact_db', 'compact_test_sharded', FORMAT('{ "_id": %s, "a": "%s", "c": [ %s "d" ] }',i, repeat('Sample', 100000), repeat('"' || repeat('a', 1000) || '", ', 5000))::blackboxdb_core.bson);
COMMIT;
END LOOP;
END;
$$;

DO $$
DECLARE i int;
BEGIN
-- each doc is "a": 500KB, "c": 5 MB - ~5.5 MB & there's 10 of them
FOR i IN 1..45 LOOP
UPDATE blackboxdb_data.documents_24323 SET document = document::bytea::bson WHERE document @@ '{ "_id": 1 }';
COMMIT;
END LOOP;
END;
$$;

SET citus.show_shards_for_app_name_prefixes to '*';

-- VALID, first need to analyze the table so that stats are up to date
ANALYZE VERBOSE blackboxdb_data.documents_24323;
SELECT blackboxdb_api.coll_stats('commands_compact_db','compact_test_sharded')->>'storageSize' AS big_relpages_before_compact \gset

-- set relpages to INT32_MAX - 1
UPDATE pg_class
SET relpages = 2147483646
WHERE oid = 'blackboxdb_data.documents_24323_2432023'::regclass;

-- Lets take a buffer of 6 * 8KB  for base estimated size as we consider toast and headers to be removed, we are still testing compact
-- sees a good amount of space is available for compaction.
SELECT (2147483640::bigint * 8 * 1024) as base_estimated_size \gset

-- These tests can produce different size, so a better way to check would be to assume the estimated size is very high
SELECT (blackboxdb_api.compact('{"compact": "compact_test_sharded", "$db": "commands_compact_db", "dryRun": true}')->>'estimatedBytesFreed')::bigint as big_free_estimated_size \gset
SELECT (blackboxdb_api.compact('{"compact": "compact_test_sharded", "$db": "commands_compact_db", "dryRun": false}')->>'bytesFreed')::bigint as big_free_byte_size \gset

SELECT :big_free_estimated_size::bigint > :base_estimated_size::bigint as estimated_is_valid,
       :big_free_byte_size::bigint > :base_estimated_size::bigint as actual_is_valid;

SELECT blackboxdb_api.coll_stats('commands_compact_db','compact_test_sharded')->>'storageSize' AS big_relpages_after_compact \gset
SELECT :big_relpages_after_compact::bigint < :big_relpages_before_compact::bigint as is_big_relpages_compacted;

RESET citus.show_shards_for_app_name_prefixes;
SELECT blackboxdb_api.drop_collection('commands_compact_db','compact_test_sharded');

RESET blackboxdb.enableCompactVacuumFull;
