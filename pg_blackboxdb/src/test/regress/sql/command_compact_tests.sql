SET blackboxdb.next_collection_id TO 25709000;
SET blackboxdb.next_collection_index_id TO 25709000;
SET search_path TO blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog,blackboxdb_api_internal;

-- Error cases: NULL and empty spec
SELECT blackboxdb_api.compact(NULL);
SELECT blackboxdb_api.compact('{}');
SELECT blackboxdb_api.compact('{"noIdea": "collection1"}');
SELECT blackboxdb_api.compact('{"compact": "non_existing_collection"}');
SELECT blackboxdb_api.compact('{"compact": 1 }');
SELECT blackboxdb_api.compact('{"compact": true }');
SELECT blackboxdb_api.compact('{"compact": ["coll"]}');

-- Create a test collection
SELECT blackboxdb_api.create_collection('compact_db','compact_coll');

-- Invalid args
SELECT blackboxdb_api.compact('{"compact": "compact_coll", "dryRun": "invalid"}');
SELECT blackboxdb_api.compact('{"compact": "compact_coll", "force": false}');

-- Default GUC is off: compact should be a no-op returning bytesFreed: 0
SELECT blackboxdb_api.compact('{"compact": "compact_coll", "$db": "compact_db"}');

-- dryRun with GUC off should return estimatedBytesFreed: 0
SELECT blackboxdb_api.compact('{"compact": "compact_coll", "$db": "compact_db", "dryRun": true}');

-- Enable the GUC and run compact (with vacuum full)
SET blackboxdb.enableCompactVacuumFull TO on;

-- Insert data to have something to compact
SELECT blackboxdb_api.insert_one('compact_db', 'compact_coll', '{ "_id": 1, "a": "hello" }');

-- With GUC on, compact should execute and return bytesFreed
SELECT blackboxdb_api.compact('{"compact": "compact_coll", "$db": "compact_db"}');

-- dryRun with GUC on should return estimatedBytesFreed
SELECT blackboxdb_api.compact('{"compact": "compact_coll", "$db": "compact_db", "dryRun": true}');

-- comment field should be accepted
SELECT blackboxdb_api.compact('{"compact": "compact_coll", "$db": "compact_db", "comment": "test comment"}');

RESET blackboxdb.enableCompactVacuumFull;

-- After reset, compact should be no-op again
SELECT blackboxdb_api.compact('{"compact": "compact_coll", "$db": "compact_db"}');

SELECT blackboxdb_api.drop_collection('compact_db','compact_coll');
