
SET search_path TO blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog,blackboxdb_api_internal;
SET citus.next_shard_id TO 3500000;
SET blackboxdb.next_collection_id TO 3500;
SET blackboxdb.next_collection_index_id TO 3500;

SELECT 1 FROM blackboxdb_api.drop_collection('db', 'bsonorderby');
SELECT blackboxdb_api.create_collection('db', 'bsonorderby');
SELECT blackboxdb_distributed_test_helpers.drop_primary_key('db', 'bsonorderby');

BEGIN;
set enable_seqscan to off;
\i sql/bson_query_modifier_orderby_tests_core.sql
ROLLBACK;
