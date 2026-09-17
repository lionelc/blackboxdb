
SET search_path TO blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog,blackboxdb_api_internal;
SET citus.next_shard_id TO 260000;
SET blackboxdb.next_collection_id TO 2600;
SET blackboxdb.next_collection_index_id TO 2600;

SELECT blackboxdb_api.drop_collection('db', 'elemmatchtest') IS NOT NULL;
SELECT blackboxdb_api.create_collection('db', 'elemmatchtest') IS NOT NULL;

-- avoid plans that use the primary key index
SELECT blackboxdb_distributed_test_helpers.drop_primary_key('db','elemmatchtest');

BEGIN;
set local enable_seqscan TO on;
\i sql/bson_query_operator_elemmatch_tests_core.sql
ROLLBACK;

-- Invalid Arguments
SELECT object_id, document FROM blackboxdb_api.collection('db', 'elemmatchtest') where document @@ '{"a" : { "$elemMatch": [] }}';
