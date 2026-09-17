
SET search_path TO blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog,blackboxdb_api_internal;
SET citus.next_shard_id TO 260000;
SET blackboxdb.next_collection_id TO 2600;
SET blackboxdb.next_collection_index_id TO 2600;

SELECT blackboxdb_api.drop_collection('db', 'elemmatchtest') IS NOT NULL;
SELECT blackboxdb_api.create_collection('db', 'elemmatchtest') IS NOT NULL;

\set prevEcho :ECHO
\set ECHO none
\o /dev/null
-- Create a wildcard index by using CREATE INDEX command instead of
-- using blackboxdb_api.create_indexes. This is because, we will use
-- that index to test whether we can use the index via query operators
-- other than "@@".
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', blackboxdb_distributed_test_helpers.generate_create_index_arg('elemmatchtest', 'index_2', '{"$**": 1}'), true);
\o
\set ECHO :prevEcho


-- avoid plans that use the primary key index
SELECT blackboxdb_distributed_test_helpers.drop_primary_key('db','elemmatchtest');

BEGIN;
set local enable_seqscan TO off;
set local blackboxdb.forceUseIndexIfAvailable to on;
\i sql/bson_query_operator_elemmatch_tests_core.sql
ROLLBACK;

-- Invalid Arguments
SELECT object_id, document FROM blackboxdb_api.collection('db', 'elemmatchtest') where document @@ '{"a" : { "$elemMatch": [] }}';
